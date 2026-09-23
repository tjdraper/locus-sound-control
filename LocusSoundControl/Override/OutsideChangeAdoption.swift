import Foundation

/// Decides whether the output landing somewhere the app did not put it was someone's deliberate
/// choice, to be adopted as the override, or macOS falling back on its own.
///
/// CoreAudio reports a change to the default output the same way whoever made it, so the only
/// thing to go on is the resulting device. Comparing against what the app expects, rather than
/// counting its own writes, means a missed or doubled notification cannot put the two out of step.
nonisolated enum OutsideChangeAdoption {
    enum Decision: Equatable {
        /// The output is where the app expects it, or somewhere it cannot act on.
        case nothingToAdopt

        case adopt(Reason)

        /// Close enough behind a device list change to be macOS's own pick, so priority decides.
        case leaveToPriority
    }

    enum Reason: Equatable {
        case outsideChange

        /// macOS switches to a device the moment it first connects. Adopting that is what lets a
        /// device nobody has placed in the order play at all, where priority would switch away
        /// from it straight back to whatever was above it.
        case newDevice
    }

    /// macOS picks a fallback when a device leaves, and follows a device that arrives, and some of
    /// those picks land after the list has held still. Too long and a real choice made right after
    /// plugging something in gets reverted.
    static let settleGrace = Duration.seconds(3)

    /// - Parameters:
    ///   - current: The output, if it is one of the connected devices. One that is not, or is not
    ///     listed yet, is nothing an override could hold on to.
    ///   - expectedUID: What the app last wrote, or what it last chose to leave alone. Nil until it
    ///     has done either, so the output found at launch is never mistaken for a choice.
    ///   - sinceSettle: How long ago the device list last settled, or nil if it has not since launch.
    static func decide(
        current: AudioOutputDevice?,
        expectedUID: String?,
        overrideUID: String?,
        order: PriorityOrder,
        sinceSettle: Duration?
    ) -> Decision {
        guard let current, let expectedUID, current.uid != expectedUID, current.uid != overrideUID
        else { return .nothingToAdopt }

        if order.index(ofUID: current.uid) == nil { return .adopt(.newDevice) }
        if let sinceSettle, sinceSettle < settleGrace { return .leaveToPriority }
        return .adopt(.outsideChange)
    }
}
