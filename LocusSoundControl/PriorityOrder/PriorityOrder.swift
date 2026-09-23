import Foundation

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

    func inPriorityOrder(_ devices: [AudioOutputDevice]) -> [AudioOutputDevice] {
        devices.enumerated()
            .sorted { lhs, rhs in
                let lhsRank = index(ofUID: lhs.element.uid) ?? .max
                let rhsRank = index(ofUID: rhs.element.uid) ?? .max
                return (lhsRank, lhs.offset) < (rhsRank, rhs.offset)
            }
            .map(\.element)
    }
}
