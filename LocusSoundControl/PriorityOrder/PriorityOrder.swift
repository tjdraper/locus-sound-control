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

    /// Devices never seen before go into the new device queue rather than the order, so plugging
    /// something in cannot take the output from a device the user placed.
    mutating func record(_ connected: [AudioOutputDevice]) {
        for device in connected where !device.hasPerSessionIdentity {
            if let index = index(ofUID: device.uid) {
                entries[index].refresh(from: device)
            } else {
                entries.append(DeviceEntry(device: device, isQueued: true))
            }
        }
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
