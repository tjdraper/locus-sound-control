import Foundation

/// Keeps the priority order in iCloud key-value storage: the order under one key, and each device
/// under a key of its own, so two Macs changing different devices at once do not overwrite each other.
struct ICloudOrderStore {
    let cloudStore: NSUbiquitousKeyValueStore
    let defaults: UserDefaults

    private static let orderKey = "PriorityOrder"
    private static let entryKeyPrefix = "Device."
    /// Where this Mac keeps the order it and iCloud last agreed on.
    private static let baseKey = "PriorityOrderSyncBase"

    /// Returns the merge, with its changes to iCloud already written.
    func sync(_ local: PriorityOrder, localIsSeed: Bool) -> PriorityOrderSyncMerge.Outcome {
        let base = base()
        let outcome = PriorityOrderSyncMerge(local: local, localIsSeed: localIsSeed, cloud: cloud(base: base), base: base).run()
        var agreed = SyncedOrder(outcome.local)
        let changes = outcome.cloudChanges

        // iCloud drops writes over its limits without an error. Recording one as agreed would make
        // the next sync read the missing device as forgotten elsewhere and forget it here. Keeping
        // the old agreement makes the next sync try the write again.
        for entry in changes.writes where !write(entry, forKey: Self.entryKeyPrefix + entry.id.uuidString) {
            agreed.entries[entry.id] = base?.entries[entry.id]
        }
        for id in changes.removals {
            cloudStore.removeObject(forKey: Self.entryKeyPrefix + id.uuidString)
        }
        if let order = changes.order, !write(order, forKey: Self.orderKey) {
            agreed.order = base?.order
        }

        save(base: agreed)
        return outcome
    }

    /// Makes the next sync merge both sides as if neither had seen the other, so nothing is
    /// forgotten here for being missing from iCloud.
    func forgetBase() {
        defaults.removeObject(forKey: Self.baseKey)
    }

    private func write(_ value: some Encodable, forKey key: String) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else { return false }
        cloudStore.set(data, forKey: key)
        return cloudStore.data(forKey: key) == data
    }

    /// An entry or order this version cannot read, perhaps written by a newer one, counts as
    /// unchanged so it is not taken for a removal.
    private func cloud(base: SyncedOrder?) -> SyncedOrder {
        var cloud = SyncedOrder.empty
        for (key, value) in cloudStore.dictionaryRepresentation {
            let data = value as? Data
            if key == Self.orderKey {
                cloud.order = data.flatMap { try? JSONDecoder().decode([DeviceEntry.ID].self, from: $0) } ?? base?.order
            } else if key.hasPrefix(Self.entryKeyPrefix) {
                if let entry = data.flatMap({ try? JSONDecoder().decode(DeviceEntry.self, from: $0) }) {
                    cloud.entries[entry.id] = entry
                } else if let id = UUID(uuidString: String(key.dropFirst(Self.entryKeyPrefix.count))) {
                    cloud.entries[id] = base?.entries[id]
                }
            }
        }
        return cloud
    }

    private func base() -> SyncedOrder? {
        defaults.data(forKey: Self.baseKey).flatMap { try? JSONDecoder().decode(SyncedOrder.self, from: $0) }
    }

    private func save(base: SyncedOrder) {
        if let data = try? JSONEncoder().encode(base) {
            defaults.set(data, forKey: Self.baseKey)
        }
    }
}
