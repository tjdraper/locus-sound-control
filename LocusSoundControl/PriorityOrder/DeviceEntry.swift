import Foundation

/// One device in the priority order, remembered whether or not it is connected.
///
/// It holds a set of UIDs rather than one, because a UID is not a device: a dock takes a new one
/// for every port it is plugged into, and `ModelMatch` folds each of them into the one entry.
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

    /// Waiting in the new device queue, where it is never chosen automatically, until the user
    /// places it in the order or hides it.
    var isQueued: Bool

    init(device: AudioOutputDevice, isQueued: Bool = false) {
        id = UUID()
        name = device.name
        modelUID = device.modelUID
        transport = device.transport
        uids = [device.uid]
        automaticSymbolName = device.symbolName
        assignedSymbolName = nil
        isHidden = false
        self.isQueued = isQueued
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

nonisolated extension DeviceEntry {
    private enum CodingKeys: String, CodingKey {
        case id, name, modelUID, transport, uids, automaticSymbolName, assignedSymbolName, isHidden, isQueued
    }

    /// Entries saved before the queue existed have no `isQueued`, and every one of them had
    /// already been placed in the order.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        modelUID = try container.decodeIfPresent(String.self, forKey: .modelUID)
        transport = try container.decode(AudioDeviceTransport.self, forKey: .transport)
        uids = try container.decode(Set<String>.self, forKey: .uids)
        automaticSymbolName = try container.decode(String.self, forKey: .automaticSymbolName)
        assignedSymbolName = try container.decodeIfPresent(String.self, forKey: .assignedSymbolName)
        isHidden = try container.decode(Bool.self, forKey: .isHidden)
        isQueued = try container.decodeIfPresent(Bool.self, forKey: .isQueued) ?? false
    }
}
