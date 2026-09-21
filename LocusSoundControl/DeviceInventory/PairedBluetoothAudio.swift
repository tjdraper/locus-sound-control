import IOBluetooth

/// What kind each paired Bluetooth audio device is, ready to look up by audio device UID.
///
/// Reading the paired list needs no permission and takes well under a millisecond, so it is read
/// fresh with every device list rather than cached and kept in step.
nonisolated struct PairedBluetoothAudio {
    private let kindsByAddress: [String: BluetoothAudioKind]

    init() {
        let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? []
        kindsByAddress = paired.reduce(into: [:]) { kinds, device in
            guard device.deviceClassMajor == UInt32(kBluetoothDeviceClassMajorAudio),
                  let address = device.addressString?.lowercased(), !address.isEmpty,
                  let kind = BluetoothAudioKind(minorClass: device.deviceClassMinor)
            else { return }
            kinds[address] = kind
        }
    }

    /// A Bluetooth output device's UID is built from the device's address, as in
    /// `18-e6-71-0f-43-7d:output`, so the address is what the UID starts with.
    func kind(forDeviceUID uid: String) -> BluetoothAudioKind? {
        let uid = uid.lowercased()
        return kindsByAddress.first { uid.hasPrefix($0.key) }?.value
    }
}
