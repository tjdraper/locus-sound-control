import Foundation
import OSLog

/// Keeps the priority order the same on every Mac signed in to the same iCloud account. The
/// override is left out: it is about what this Mac is doing right now.
@Observable
final class ICloudSyncCoordinator {
    private let priorityOrder: PriorityOrderStore
    private let defaults: UserDefaults
    private let cloudStore = NSUbiquitousKeyValueStore.default
    private let orderStore: ICloudOrderStore
    @ObservationIgnored private var tasks: [Task<Void, Never>] = []

    private static let accountDefaultsKey = "ICloudSyncAccount"
    private static let log = Logger(subsystem: "com.buzzingpixel.LocusSoundControl", category: "ICloudSync")

    init(priorityOrder: PriorityOrderStore, defaults: UserDefaults = .standard) {
        self.priorityOrder = priorityOrder
        self.defaults = defaults
        orderStore = ICloudOrderStore(cloudStore: cloudStore, defaults: defaults)
    }

    deinit {
        tasks.forEach { $0.cancel() }
    }

    var isEnabled: Bool {
        get {
            access(keyPath: \.isEnabled)
            return ICloudSyncPreference(defaults: defaults).isEnabled
        }
        set {
            guard newValue != isEnabled else { return }
            withMutation(keyPath: \.isEnabled) {
                ICloudSyncPreference(defaults: defaults).isEnabled = newValue
            }
            if newValue { startSyncing() } else { stopSyncing() }
        }
    }

    func start() {
        if isEnabled { startSyncing() } else { stopSyncing() }
    }

    private func stopSyncing() {
        tasks.forEach { $0.cancel() }
        tasks = []
        // Turning it back on then merges both sides as if neither had seen the other. Otherwise a
        // device forgotten elsewhere in the meantime would be forgotten here, and a device added
        // here would be read as forgotten elsewhere.
        orderStore.forgetBase()
        Self.log.info("Sync with iCloud is turned off")
    }

    private func startSyncing() {
        let reasons = NotificationCenter.default
            .notifications(named: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .map { $0.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int }
        forgetBaseIfAccountChanged()
        cloudStore.synchronize()

        tasks.append(Task { [weak self, priorityOrder] in
            for await _ in Observations({ priorityOrder.order }) {
                self?.sync()
            }
        })
        tasks.append(Task { [weak self] in
            for await reason in reasons {
                self?.cloudStoreDidChange(reason: reason)
            }
        })
    }

    private func cloudStoreDidChange(reason: Int?) {
        switch reason {
        case NSUbiquitousKeyValueStoreInitialSyncChange:
            // Writes made before the first download were thrown away, so what this Mac last
            // agreed on no longer holds.
            orderStore.forgetBase()
        case NSUbiquitousKeyValueStoreAccountChange:
            forgetBaseIfAccountChanged()
        default:
            break
        }
        sync()
    }

    /// The account can change while the app is not running, and then no notification says so. The
    /// store would hold another account's order, and comparing it with what this Mac agreed with
    /// the old account would forget every device here. Signing out counts as a change too.
    private func forgetBaseIfAccountChanged() {
        let token = FileManager.default.ubiquityIdentityToken
            .flatMap { try? NSKeyedArchiver.archivedData(withRootObject: $0, requiringSecureCoding: true) }
        guard token != defaults.data(forKey: Self.accountDefaultsKey) else { return }
        orderStore.forgetBase()
        defaults.set(token, forKey: Self.accountDefaultsKey)
    }

    private func sync() {
        let before = priorityOrder.order
        let outcome = orderStore.sync(before, localIsSeed: priorityOrder.isUnarrangedSeed)
        logChanges(outcome, before: before)
        priorityOrder.adoptSynced(outcome.local)
    }

    private func logChanges(_ outcome: PriorityOrderSyncMerge.Outcome, before: PriorityOrder) {
        let previous = Dictionary(before.entries.map { ($0.id, $0) }) { first, _ in first }
        let taken = outcome.local.entries.filter { previous[$0.id] != $0 }.count
        let forgotten = Set(previous.keys).subtracting(outcome.local.entries.map(\.id)).count
        let reordered = outcome.local.entries.map(\.id) != before.entries.map(\.id)
        let sent = outcome.cloudChanges
        guard taken > 0 || forgotten > 0 || reordered || !sent.isEmpty else { return }

        if outcome.replacedSeed {
            Self.log.info("Replaced the order seeded on first launch with the one in iCloud, of \(outcome.local.entries.count) devices")
        }
        Self.log.info(
            """
            Synced with iCloud. Here: \(taken) devices added or changed, \(forgotten) forgotten, \
            reordered \(reordered ? "yes" : "no", privacy: .public). \
            To iCloud: \(sent.writes.count) devices written, \(sent.removals.count) removed, \
            order written \(sent.order == nil ? "no" : "yes", privacy: .public)
            """
        )
    }
}
