import Foundation

/// Picks the symbol for a device, from the most specific thing known about it down to the
/// coarsest: the exact model, then what kind of Bluetooth device it is, then how it is attached.
///
/// Everything here is a guess the user can overrule in slice 5. Where nothing identifies the
/// shape of the device, a plain speaker beats a wrong guess.
nonisolated enum OutputDeviceSymbol {
    static let generic = "hifispeaker"

    /// - Parameter builtInSpeakers: what the Mac's own speakers look like, which depends on the
    ///   Mac. See `BuiltInSpeakerSymbol`.
    static func name(
        for transport: AudioDeviceTransport,
        modelUID: String?,
        bluetoothKind: BluetoothAudioKind?,
        builtInSpeakers: String
    ) -> String {
        if let modelUID {
            if let accessory = AppleAccessorySymbol.name(forModelUID: modelUID) { return accessory }
            if let known = knownModel(modelUID) { return known }
        }
        if let bluetoothKind { return bluetoothKind.symbolName }

        switch transport {
        case .builtIn: return builtInSpeakers
        case .bluetooth: return "headphones"
        case .displayPort, .hdmi: return "display"
        case .airPlay: return "airplayaudio"
        case .virtual: return "waveform"
        case .usb, .thunderbolt, .aggregate, .fireWire, .pci, .continuityCapture, .unknown: return generic
        }
    }

    /// Devices named one at a time, because nothing on the Mac names them. `AppleAccessorySymbol`
    /// covers Bluetooth by asking macOS, but there is no uniform type tagged with USB ids, so USB
    /// audio is matched here on the tail of its `<name>:<vendor>:<product>` model identifier —
    /// skipping the name means renaming the device cannot break the match.
    ///
    /// Only identifiers read off a real device belong here. Verified on macOS 27; the shape of
    /// the string is Apple's to change.
    private static let byModel = [
        ":05AC:1118": "display", // Apple Studio Display
    ]

    private static func knownModel(_ modelUID: String) -> String? {
        byModel.first { modelUID.hasSuffix($0.key) }?.value
    }
}
