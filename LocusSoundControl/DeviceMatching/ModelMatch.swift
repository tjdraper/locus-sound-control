import Foundation

/// Recognizes a device arriving under a UID no entry holds as a device already remembered.
///
/// A USB audio UID ends in a serial number for some devices and a port address for others, and
/// nothing in the string says which. A dock moved to another port, or re-identified because
/// something above it in the chain moved, arrives under a new UID. Its model identifier and
/// transport do not change, so those are matched instead.
nonisolated enum ModelMatch {
    /// - Parameter connectedUIDs: Every UID connected right now. Two devices present at once
    ///   cannot be the same device, so an entry with any of its UIDs connected is never matched.
    ///   That keeps two units of the same model apart whenever they are plugged in together.
    static func entryIndex(
        for device: AudioOutputDevice,
        in entries: [DeviceEntry],
        connectedUIDs: Set<String>
    ) -> Int? {
        // A Bluetooth UID is the device's own address, so it never drifts, and a new one is a
        // different unit — a second pair of the same AirPods — rather than a known one moved.
        guard let modelUID = device.modelUID, device.transport != .bluetooth else { return nil }

        return entries.firstIndex { entry in
            entry.modelUID == modelUID
                && entry.transport == device.transport
                && entry.uids.isDisjoint(with: connectedUIDs)
        }
    }
}
