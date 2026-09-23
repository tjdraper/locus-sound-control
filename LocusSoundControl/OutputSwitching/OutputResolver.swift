import Foundation

/// Decides which connected device the Mac should be playing through.
nonisolated enum OutputResolver {
    enum Resolution: Equatable {
        case device(uid: String, reason: Reason)

        /// Nothing in the order is connected. Forcing some other device would be a guess, and
        /// macOS has already made one.
        case leaveAlone
    }

    enum Reason: Equatable {
        case override
        case priority(index: Int)
    }

    static func resolve(order: PriorityOrder, connected: [AudioOutputDevice], overrideUID: String?) -> Resolution {
        if let overrideUID, connected.contains(where: { $0.uid == overrideUID }) {
            return .device(uid: overrideUID, reason: .override)
        }

        for (index, entry) in order.entries.enumerated() where !entry.isHidden {
            if let device = connected.first(where: { entry.uids.contains($0.uid) }) {
                return .device(uid: device.uid, reason: .priority(index: index))
            }
        }
        return .leaveAlone
    }
}
