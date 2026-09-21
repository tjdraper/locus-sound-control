import IOBluetooth

/// What a Bluetooth audio device is, from the class of device it advertises.
///
/// Transport type says only "Bluetooth", which is why a Bluetooth speaker used to show
/// headphones. Every Bluetooth device carries a class of device, so reading it tells speakers,
/// car kits and headphones apart for every maker at once, with no table of products to keep.
nonisolated enum BluetoothAudioKind: Sendable {
    case headphones
    case speaker
    case car
    case television

    /// Hands-free is left out on purpose: it covers both car kits and speakerphones, so it says
    /// no more than the transport already did.
    init?(minorClass: BluetoothDeviceClassMinor) {
        switch Int(minorClass) {
        case kBluetoothDeviceClassMinorAudioHeadset,
             kBluetoothDeviceClassMinorAudioHeadphones:
            self = .headphones
        case kBluetoothDeviceClassMinorAudioLoudspeaker,
             kBluetoothDeviceClassMinorAudioHiFi,
             kBluetoothDeviceClassMinorAudioPortable:
            self = .speaker
        case kBluetoothDeviceClassMinorAudioCar:
            self = .car
        case kBluetoothDeviceClassMinorAudioSetTopBox,
             kBluetoothDeviceClassMinorAudioVideoMonitor,
             kBluetoothDeviceClassMinorAudioVideoDisplayAndLoudspeaker:
            self = .television
        default:
            return nil
        }
    }

    var symbolName: String {
        switch self {
        case .headphones: "headphones"
        case .speaker: "hifispeaker"
        case .car: "car"
        case .television: "tv"
        }
    }
}
