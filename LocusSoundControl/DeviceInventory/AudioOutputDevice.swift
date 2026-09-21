import Foundation

/// One connected output device, as read from CoreAudio.
///
/// A UID is not a stable identity for a device across ports or reboots — slice 6 folds several of
/// them into one stored entry — but it is what identifies a device that is connected right now.
nonisolated struct AudioOutputDevice: Identifiable, Equatable, Sendable {
    let uid: String
    let name: String

    /// A model-level identifier, vendor and product. Absent on devices that do not publish one.
    let modelUID: String?

    let transport: AudioDeviceTransport

    /// The symbol shown for this device until slice 5 lets the user assign one.
    let symbolName: String

    var id: String { uid }
}
