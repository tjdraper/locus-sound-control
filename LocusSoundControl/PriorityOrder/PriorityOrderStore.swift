import Foundation
import OSLog
import SwiftUI

/// The priority order as the user arranged it, saved in `UserDefaults`.
@Observable
final class PriorityOrderStore {
    private(set) var order: PriorityOrder

    @ObservationIgnored private let defaults: UserDefaults

    /// Only a Mac that has never saved an order is seeded. An empty saved order is still the
    /// user's, and the devices that arrive after it go to the new device queue.
    @ObservationIgnored private var hasSavedOrder: Bool

    /// Still the order first launch guessed, untouched by the user. An order synced from another
    /// Mac replaces it rather than merging with it.
    private(set) var isUnarrangedSeed: Bool

    private static let key = "PriorityOrder"
    private static let seedKey = "PriorityOrderIsUnarrangedSeed"
    private static let log = Logger(subsystem: "com.buzzingpixel.LocusSoundControl", category: "PriorityOrder")

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isUnarrangedSeed = defaults.bool(forKey: Self.seedKey)
        guard let data = defaults.data(forKey: Self.key) else {
            order = PriorityOrder(entries: [])
            hasSavedOrder = false
            isUnarrangedSeed = true
            return
        }

        do {
            order = PriorityOrder(entries: try JSONDecoder().decode([DeviceEntry].self, from: data))
            hasSavedOrder = true
        } catch {
            Self.log.error("The saved priority order could not be read, so it starts again: \(error, privacy: .public)")
            order = PriorityOrder(entries: [])
            hasSavedOrder = false
            isUnarrangedSeed = true
        }
    }

    func record(_ connected: [AudioOutputDevice], currentOutputUID: String?) {
        guard hasSavedOrder else {
            order = .seeded(from: connected, currentOutputUID: currentOutputUID)
            Self.log.info("Seeded the priority order from \(connected.count) connected outputs")
            save()
            return
        }

        var next = order
        let recorded = next.record(connected)
        // Assigning an equal order would still wake everything observing it, the switching engine included.
        guard next != order else { return }

        order = next
        if recorded.recognized > 0 {
            Self.log.info("Recognized \(recorded.recognized) outputs under new UIDs as known devices, by their model")
        }
        if recorded.queued > 0 { Self.log.info("Queued \(recorded.queued) new outputs") }
        save()
    }

    func movePlaced(fromOffsets source: IndexSet, toOffset destination: Int) {
        order.movePlaced(fromOffsets: source, toOffset: destination)
        saveUserEdit()
    }

    func place(_ id: DeviceEntry.ID, atPlacedOffset offset: Int) {
        order.place(id, atPlacedOffset: offset)
        Self.log.info("Placed a queued device at priority \(offset + 1) of \(self.order.placed.count)")
        saveUserEdit()
    }

    func setHidden(_ isHidden: Bool, for ids: Set<DeviceEntry.ID>) {
        order.setHidden(isHidden, for: ids)
        Self.log.info("\(isHidden ? "Hid" : "Unhid", privacy: .public) \(ids.count) devices")
        saveUserEdit()
    }

    func assignSymbol(_ symbolName: String?, to id: DeviceEntry.ID) {
        order.assignSymbol(symbolName, to: id)
        saveUserEdit()
    }

    func merge(_ ids: Set<DeviceEntry.ID>) -> DeviceEntry.ID? {
        guard let merged = order.merge(ids) else { return nil }
        Self.log.info("Merged \(ids.count) devices into one")
        saveUserEdit()
        return merged
    }

    func split(_ id: DeviceEntry.ID, keepingUID: String?) -> [DeviceEntry.ID] {
        let splitOff = order.split(id, keepingUID: keepingUID)
        guard !splitOff.isEmpty else { return [] }
        Self.log.info("Split one device into \(splitOff.count + 1)")
        saveUserEdit()
        return splitOff
    }

    func forget(_ ids: Set<DeviceEntry.ID>) {
        order.forget(ids)
        Self.log.info("Forgot \(ids.count) devices")
        saveUserEdit()
    }

    /// An order from iCloud was arranged by the user on another Mac, so it is no longer a seed.
    func adoptSynced(_ synced: PriorityOrder) {
        guard synced != order else { return }
        order = synced
        saveUserEdit()
    }

    private func saveUserEdit() {
        isUnarrangedSeed = false
        save()
    }

    private func save() {
        do {
            defaults.set(try JSONEncoder().encode(order.entries), forKey: Self.key)
            defaults.set(isUnarrangedSeed, forKey: Self.seedKey)
            hasSavedOrder = true
        } catch {
            Self.log.error("The priority order could not be saved: \(error, privacy: .public)")
        }
    }
}
