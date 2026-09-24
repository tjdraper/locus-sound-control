import Foundation

/// One device in the priority order, remembered whether or not it is connected.
///
/// It holds a set of UIDs rather than one, because a UID is not a device: a dock takes a new one
/// for every port it is plugged into. Slice 6 folds those into one entry; the shape is stored from
/// the start so that nothing already saved has to be migrated then.
nonisolated struct DeviceEntry: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var modelUID: String?
    var transport: AudioDeviceTransport
    var uids: Set<String>

    /// Kept so a device that is not connected can still show the symbol it had when it was.
    var automaticSymbolName: String

    /// Chosen by the user, and wins over the guessed one.
    var assignedSymbolName: String?

    var isHidden: Bool

    init(device: AudioOutputDevice) {
        id = UUID()
        name = device.name
        modelUID = device.modelUID
        transport = device.transport
        uids = [device.uid]
        automaticSymbolName = device.symbolName
        assignedSymbolName = nil
        isHidden = false
    }

    var symbolName: String {
        assignedSymbolName ?? automaticSymbolName
    }

    /// A device can be renamed, and its symbol guessed better once Bluetooth access is granted.
    mutating func refresh(from device: AudioOutputDevice) {
        name = device.name
        modelUID = device.modelUID
        transport = device.transport
        automaticSymbolName = device.symbolName
    }
}
