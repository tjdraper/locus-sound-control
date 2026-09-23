import CoreAudio

/// How a device is attached, as CoreAudio reports it.
///
/// The case names are saved with the priority order, so renaming one loses it for every device
/// already stored.
nonisolated enum AudioDeviceTransport: String, Codable, Sendable {
    case builtIn
    case usb
    case bluetooth
    case displayPort
    case hdmi
    case thunderbolt
    case airPlay
    case virtual
    case aggregate
    case fireWire
    case pci
    case continuityCapture
    case unknown

    /// Transport types are four-character codes. An unmapped one becomes `unknown` rather than a
    /// decoded string, since nothing downstream can act on a code it does not recognise.
    init(rawTransport: UInt32) {
        self = Self.byRawTransport[rawTransport] ?? .unknown
    }

    private static let byRawTransport: [UInt32: AudioDeviceTransport] = [
        kAudioDeviceTransportTypeBuiltIn: .builtIn,
        kAudioDeviceTransportTypeUSB: .usb,
        kAudioDeviceTransportTypeBluetooth: .bluetooth,
        kAudioDeviceTransportTypeBluetoothLE: .bluetooth,
        kAudioDeviceTransportTypeDisplayPort: .displayPort,
        kAudioDeviceTransportTypeHDMI: .hdmi,
        kAudioDeviceTransportTypeThunderbolt: .thunderbolt,
        kAudioDeviceTransportTypeAirPlay: .airPlay,
        kAudioDeviceTransportTypeVirtual: .virtual,
        kAudioDeviceTransportTypeAggregate: .aggregate,
        kAudioDeviceTransportTypeFireWire: .fireWire,
        kAudioDeviceTransportTypePCI: .pci,
        kAudioDeviceTransportTypeContinuityCaptureWired: .continuityCapture,
        kAudioDeviceTransportTypeContinuityCaptureWireless: .continuityCapture,
    ]

    var displayName: String {
        switch self {
        case .builtIn: "Built-in"
        case .usb: "USB"
        case .bluetooth: "Bluetooth"
        case .displayPort: "DisplayPort"
        case .hdmi: "HDMI"
        case .thunderbolt: "Thunderbolt"
        case .airPlay: "AirPlay"
        case .virtual: "Virtual"
        case .aggregate: "Aggregate"
        case .fireWire: "FireWire"
        case .pci: "PCI"
        case .continuityCapture: "Continuity Capture"
        case .unknown: "Unknown"
        }
    }
}
