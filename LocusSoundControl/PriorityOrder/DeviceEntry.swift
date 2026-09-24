import CryptoKit
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

    init(device: AudioOutputDevice, id: UUID? = nil, isQueued: Bool = false) {
        self.id = id ?? Self.id(forUID: device.uid)
        name = device.name
        modelUID = device.modelUID
        transport = device.transport
        uids = [device.uid]
        automaticSymbolName = device.symbolName
        assignedSymbolName = nil
        isHidden = false
        self.isQueued = isQueued
    }

    /// A new entry for one of this entry's UIDs, starting with everything else this one has.
    func splittingOff(_ uid: String) -> DeviceEntry {
        DeviceEntry(copying: self, uid: uid)
    }

    private init(copying entry: DeviceEntry, uid: String) {
        id = UUID()
        name = entry.name
        modelUID = entry.modelUID
        transport = entry.transport
        uids = [uid]
        automaticSymbolName = entry.automaticSymbolName
        assignedSymbolName = entry.assignedSymbolName
        isHidden = entry.isHidden
        isQueued = entry.isQueued
    }

    /// The same on every Mac, so two Macs that meet a device before either has synced it make one
    /// entry between them rather than two.
    static func id(forUID uid: String) -> UUID {
        var bytes = Array(SHA256.hash(data: Data(uid.utf8)).prefix(16))
        // Version 8, which RFC 9562 gives to a UUID built from a SHA-256 hash (appendix B.2).
        bytes[6] = (bytes[6] & 0x0F) | 0x80
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: bytes.withUnsafeBytes { $0.loadUnaligned(as: uuid_t.self) })
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
