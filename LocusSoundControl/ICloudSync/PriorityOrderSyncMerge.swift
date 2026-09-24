import Foundation

/// The priority order as iCloud holds it, or as this Mac and iCloud last agreed on it.
nonisolated struct SyncedOrder: Codable, Equatable, Sendable {
    /// Nil in iCloud until a Mac has written one.
    var order: [DeviceEntry.ID]?
    var entries: [DeviceEntry.ID: DeviceEntry]

    static let empty = SyncedOrder(order: nil, entries: [:])

    init(order: [DeviceEntry.ID]?, entries: [DeviceEntry.ID: DeviceEntry]) {
        self.order = order
        self.entries = entries
    }

    init(_ priorityOrder: PriorityOrder) {
        order = priorityOrder.entries.map(\.id)
        entries = Dictionary(priorityOrder.entries.map { ($0.id, $0) }) { first, _ in first }
    }
}

/// Brings the priority order on this Mac and in iCloud into agreement.
///
/// Each side is compared with `base`, what both agreed on last time, so the merge can tell which
/// side changed. When both did, iCloud wins, since that is what the other Macs already have.
/// iCloud keeps the last write to each key, so that only happens when this Mac changed something
/// while it was not syncing.
///
/// The order is one value, because interleaving two reorders gives an order nobody chose. Each
/// device is merged on its own, so hiding one here and placing another elsewhere both hold.
nonisolated struct PriorityOrderSyncMerge {
    struct Outcome: Equatable {
        var local: PriorityOrder
        var cloudChanges: CloudChanges
        var replacedSeed = false
    }

    struct CloudChanges: Equatable {
        var writes: [DeviceEntry] = []
        var removals: [DeviceEntry.ID] = []
        var order: [DeviceEntry.ID]?

        var isEmpty: Bool {
            writes.isEmpty && removals.isEmpty && order == nil
        }
    }

    let local: PriorityOrder
    /// The order first launch guessed from whatever was plugged in, not yet touched by the user.
    let localIsSeed: Bool
    let cloud: SyncedOrder
    /// Nil when this Mac has never agreed with iCloud, or has stopped trusting what it agreed.
    let base: SyncedOrder?

    func run() -> Outcome {
        if localIsSeed, base == nil, let cloudOrder = cloud.order {
            // The seed is a guess; an order in iCloud is one the user arranged on another Mac.
            let adopted = Self.assemble(order: cloudOrder, entries: cloud.entries, thenInOrder: [])
            return Outcome(local: adopted, cloudChanges: changes(toReach: adopted), replacedSeed: true)
        }

        let merged = Self.assemble(order: mergedOrder(), entries: mergedEntries(), thenInOrder: local.entries.map(\.id))
            .foldingSharedUIDs()
        return Outcome(local: merged, cloudChanges: changes(toReach: merged))
    }

    private func mergedOrder() -> [DeviceEntry.ID] {
        let mine = local.entries.map(\.id)
        guard let theirs = cloud.order, mine != theirs, theirs != base?.order else { return mine }
        return theirs
    }

    private func mergedEntries() -> [DeviceEntry.ID: DeviceEntry] {
        let mine = Dictionary(local.entries.map { ($0.id, $0) }) { first, _ in first }
        var ids = Set(mine.keys).union(cloud.entries.keys)
        if let base { ids.formUnion(base.entries.keys) }
        var merged: [DeviceEntry.ID: DeviceEntry] = [:]
        for id in ids {
            merged[id] = Self.merge(mine: mine[id], theirs: cloud.entries[id], agreed: base?.entries[id])
        }
        return merged
    }

    private static func merge(mine: DeviceEntry?, theirs: DeviceEntry?, agreed: DeviceEntry?) -> DeviceEntry? {
        if mine?.decisions == theirs?.decisions || theirs?.decisions == agreed?.decisions {
            return mine
        }
        // Changed here and forgotten elsewhere: keeping the change loses less.
        if theirs == nil, mine?.decisions != agreed?.decisions {
            return mine
        }
        return take(theirs, over: mine)
    }

    /// Takes the other Mac's decisions about a device and keeps what this Mac reads from it. Its
    /// name can differ between Macs, and taking it would have each Mac write its own back.
    private static func take(_ theirs: DeviceEntry?, over mine: DeviceEntry?) -> DeviceEntry? {
        guard var entry = mine, let theirs else { return theirs }
        entry.uids = theirs.uids
        entry.assignedSymbolName = theirs.assignedSymbolName
        entry.isHidden = theirs.isHidden
        entry.isQueued = theirs.isQueued
        return entry
    }

    /// Entries the order does not list come after it: this Mac's in the order they had here, then
    /// any others sorted, so every Mac adds them the same way.
    private static func assemble(
        order: [DeviceEntry.ID],
        entries: [DeviceEntry.ID: DeviceEntry],
        thenInOrder localOrder: [DeviceEntry.ID]
    ) -> PriorityOrder {
        var remaining = entries
        var assembled = (order + localOrder).compactMap { remaining.removeValue(forKey: $0) }
        assembled += remaining.values.sorted { $0.id.uuidString < $1.id.uuidString }
        return PriorityOrder(entries: assembled)
    }

    private func changes(toReach merged: PriorityOrder) -> CloudChanges {
        let ids = merged.entries.map(\.id)
        let kept = Set(ids)
        return CloudChanges(
            writes: merged.entries.filter { cloud.entries[$0.id]?.decisions != $0.decisions },
            removals: cloud.entries.keys.filter { !kept.contains($0) }.sorted { $0.uuidString < $1.uuidString },
            order: ids == cloud.order ?? [] ? nil : ids
        )
    }
}

nonisolated private extension DeviceEntry {
    /// What the user, and the matching that folds UIDs together, decided about a device. The rest
    /// each Mac reads from the device itself.
    struct Decisions: Equatable {
        let uids: Set<String>
        let assignedSymbolName: String?
        let isHidden: Bool
        let isQueued: Bool
    }

    var decisions: Decisions {
        Decisions(uids: uids, assignedSymbolName: assignedSymbolName, isHidden: isHidden, isQueued: isQueued)
    }
}

nonisolated private extension PriorityOrder {
    /// Two entries holding one UID are one device, recorded separately: by two Macs that each
    /// had the device before syncing, or on one Mac while a merge made on another was on its way.
    /// They are folded the way a merge by hand folds them.
    func foldingSharedUIDs() -> PriorityOrder {
        var folded = self
        while let uid = folded.firstSharedUID() {
            folded.merge(Set(folded.entries.filter { $0.uids.contains(uid) }.map(\.id)))
        }
        return folded
    }

    private func firstSharedUID() -> String? {
        var seen: Set<String> = []
        for uid in entries.flatMap({ $0.uids.sorted() }) where !seen.insert(uid).inserted {
            return uid
        }
        return nil
    }
}
