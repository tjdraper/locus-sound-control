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

    /// Adds devices never seen before at the bottom, where they can only win when nothing else is
    /// connected. Slice 6 queues them instead.
    mutating func record(_ connected: [AudioOutputDevice]) {
        for device in connected {
            if let index = index(ofUID: device.uid) {
                entries[index].refresh(from: device)
            } else {
                entries.append(DeviceEntry(device: device))
            }
        }
    }

    /// Moves entries among the ones that are not hidden, which are the only ones the window lets
    /// be dragged. Hidden entries keep their places, so unhiding one puts it back where it was.
    mutating func moveVisible(fromOffsets source: IndexSet, toOffset destination: Int) {
        let slots = entries.indices.filter { !entries[$0].isHidden }
        var visible = slots.map { entries[$0] }
        visible.move(fromOffsets: source, toOffset: destination)
        for (slot, entry) in zip(slots, visible) {
            entries[slot] = entry
        }
    }

    mutating func setHidden(_ isHidden: Bool, for ids: Set<DeviceEntry.ID>) {
        for index in entries.indices where ids.contains(entries[index].id) {
            entries[index].isHidden = isHidden
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
