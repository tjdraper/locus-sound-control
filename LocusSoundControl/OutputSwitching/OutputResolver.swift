import Foundation

/// Decides which connected device the Mac should be playing through.
nonisolated enum OutputResolver {
    enum Resolution: Equatable {
        case device(AudioOutputDevice, reason: Reason)

        /// Nothing in the order is connected, or only hidden and queued devices are. Forcing some other device would be
        /// a guess, and macOS has already made one.
        case leaveAlone
    }

    enum Reason: Equatable {
        case override
        case priority(index: Int)
    }

    static func resolve(order: PriorityOrder, connected: [AudioOutputDevice], overrideUID: String?) -> Resolution {
        if let overrideUID, let device = connected.first(where: { $0.uid == overrideUID }) {
            return .device(device, reason: .override)
        }

        for (index, entry) in order.entries.enumerated() where !entry.isHidden && !entry.isQueued {
            if let device = connected.first(where: { entry.uids.contains($0.uid) }) {
                return .device(device, reason: .priority(index: index))
            }
        }
        return .leaveAlone
    }
}
