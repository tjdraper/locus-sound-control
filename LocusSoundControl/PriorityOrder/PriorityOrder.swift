import Foundation
import SwiftUI

/// The devices the Mac has seen, highest priority first.
nonisolated struct PriorityOrder: Equatable, Sendable {
    var entries: [DeviceEntry]

    /// The order a Mac starts with, guessed from whatever is connected on first launch. The current
    /// output goes first, since the user was already listening to it and seeding should not switch.
    static func seeded(from connected: [AudioOutputDevice], currentOutputUID: String?) -> PriorityOrder {
        let current = connected.filter { $0.uid == currentOutputUID }
        let rest = connected.filter { $0.uid != currentOutputUID }
        return PriorityOrder(entries: (current + rest).map { DeviceEntry(device: $0) })
    }

    func index(ofUID uid: String) -> Int? {
        entries.firstIndex { $0.uids.contains(uid) }
    }

    func entry(forUID uid: String) -> DeviceEntry? {
        index(ofUID: uid).map { entries[$0] }
    }

    struct Recorded: Equatable {
        /// New UIDs taken to be devices already remembered, by their model.
        var recognized = 0
        var queued = 0
    }

    /// Devices never seen before go into the new device queue rather than the order, so plugging
    /// something in cannot take the output from a device the user placed. A known device under a
    /// new UID keeps its entry, which takes the UID on.
    @discardableResult
    mutating func record(_ connected: [AudioOutputDevice]) -> Recorded {
        var recorded = Recorded()
        let connectedUIDs = Set(connected.map(\.uid))
        for device in connected where !device.hasPerSessionIdentity {
            if let index = index(ofUID: device.uid) {
                entries[index].refresh(from: device)
            } else if let index = ModelMatch.entryIndex(for: device, in: entries, connectedUIDs: connectedUIDs) {
                entries[index].uids.insert(device.uid)
                entries[index].refresh(from: device)
                recorded.recognized += 1
            } else {
                // An entry keeps its id when a split leaves it holding a different UID from the
                // one it was made for, so the id this UID would get can already be taken.
                let id = DeviceEntry.id(forUID: device.uid)
                let isTaken = entries.contains { $0.id == id }
                entries.append(DeviceEntry(device: device, id: isTaken ? UUID() : id, isQueued: true))
                recorded.queued += 1
            }
        }
        return recorded
    }

    var queued: [DeviceEntry] {
        entries.filter(\.isQueued)
    }

    /// The entries the window lists as the priority order, which are the only ones it lets be
    /// dragged.
    var placed: [DeviceEntry] {
        placedSlots.map { entries[$0] }
    }

    /// Moves entries among the placed ones. Hidden entries keep their places, so unhiding one puts
    /// it back where it was.
    mutating func movePlaced(fromOffsets source: IndexSet, toOffset destination: Int) {
        let slots = placedSlots
        var placed = slots.map { entries[$0] }
        placed.move(fromOffsets: source, toOffset: destination)
        for (slot, entry) in zip(slots, placed) {
            entries[slot] = entry
        }
    }

    /// Takes a device out of the queue and puts it among the placed entries. The offset counts
    /// only those, since they are the rows it is dropped between.
    mutating func place(_ id: DeviceEntry.ID, atPlacedOffset offset: Int) {
        guard let from = entries.firstIndex(where: { $0.id == id }) else { return }
        var entry = entries.remove(at: from)
        entry.isQueued = false

        let slots = placedSlots
        let destination = if offset < slots.count {
            slots[max(offset, 0)]
        } else {
            slots.last.map { $0 + 1 } ?? 0
        }
        entries.insert(entry, at: destination)
    }

    private var placedSlots: [Int] {
        entries.indices.filter { !entries[$0].isHidden && !entries[$0].isQueued }
    }

    /// Hiding a queued device sorts it too. It is a decision about the device, and one nobody
    /// wants would otherwise keep the badge lit until dragged into a list it is never chosen from.
    mutating func setHidden(_ isHidden: Bool, for ids: Set<DeviceEntry.ID>) {
        for index in entries.indices where ids.contains(entries[index].id) {
            entries[index].isHidden = isHidden
            if isHidden { entries[index].isQueued = false }
        }
    }

    mutating func assignSymbol(_ symbolName: String?, to id: DeviceEntry.ID) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].assignedSymbolName = symbolName
    }

    /// Folds entries the user says are one device into one, keeping the highest placed of them, or
    /// the first queued one when none is placed. It keeps its slot, and takes on every UID.
    ///
    /// It stays hidden only if all of them were, since merging says the device is one in use. It
    /// keeps its own assigned icon, or takes one of the others' if it had none.
    ///
    /// - Returns: The merged entry, or nil when fewer than two of `ids` are in the order.
    @discardableResult
    mutating func merge(_ ids: Set<DeviceEntry.ID>) -> DeviceEntry.ID? {
        let merging = entries.filter { ids.contains($0.id) }
        guard merging.count > 1,
              let kept = merging.first(where: { !$0.isQueued }) ?? merging.first,
              let index = entries.firstIndex(where: { $0.id == kept.id })
        else { return nil }

        for other in merging where other.id != kept.id {
            entries[index].uids.formUnion(other.uids)
            if entries[index].assignedSymbolName == nil {
                entries[index].assignedSymbolName = other.assignedSymbolName
            }
        }
        entries[index].isHidden = merging.allSatisfy(\.isHidden)
        entries.removeAll { ids.contains($0.id) && $0.id != kept.id }
        return kept.id
    }

    /// Undoes a merge, automatic or by hand, giving each UID an entry of its own directly below
    /// the original. Nothing records which UIDs were merged together, so it splits all of them.
    ///
    /// - Parameter keepingUID: The UID the original entry keeps, which is the connected one, so
    ///   the device playing now keeps its place, icon and override. The rest start as copies of it.
    /// - Returns: The entries split off.
    @discardableResult
    mutating func split(_ id: DeviceEntry.ID, keepingUID: String?) -> [DeviceEntry.ID] {
        guard let index = entries.firstIndex(where: { $0.id == id }), entries[index].uids.count > 1 else { return [] }

        let original = entries[index]
        let kept = keepingUID.flatMap { original.uids.contains($0) ? $0 : nil } ?? original.uids.sorted()[0]
        let splitOff = original.uids.subtracting([kept]).sorted().map(original.splittingOff)
        entries[index].uids = [kept]
        entries.insert(contentsOf: splitOff, at: index + 1)
        return splitOff.map(\.id)
    }

    /// Deletes the entries outright. A device that comes back is new again.
    mutating func forget(_ ids: Set<DeviceEntry.ID>) {
        entries.removeAll { ids.contains($0.id) }
    }

    func inPriorityOrder(_ devices: [AudioOutputDevice]) -> [AudioOutputDevice] {
        devices.enumerated()
            .sorted { lhs, rhs in
                let lhsRank = index(ofUID: lhs.element.uid) ?? .max
                let rhsRank = index(ofUID: rhs.element.uid) ?? .max
                return (lhsRank, lhs.offset) < (rhsRank, rhs.offset)
            }
            .map(\.element)
    }

    /// The connected devices the menu offers, in priority order. A hidden device is left out unless
    /// it is the one playing, so the menu never loses track of where the sound is going.
    func offeredInMenu(_ connected: [AudioOutputDevice], currentOutputUID: String?) -> [AudioOutputDevice] {
        inPriorityOrder(connected).filter { device in
            device.uid == currentOutputUID || entry(forUID: device.uid)?.isHidden != true
        }
    }
}
