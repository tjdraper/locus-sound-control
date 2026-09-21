import Foundation

/// Picks the symbol for a device from what CoreAudio says about it.
///
/// This is a coarse guess the user can overrule in slice 5. Where nothing identifies the shape of
/// the device, a plain speaker beats a wrong guess.
nonisolated enum OutputDeviceSymbol {
    static let generic = "hifispeaker"

    /// - Parameter builtInSpeakers: what the Mac's own speakers look like, which depends on the
    ///   Mac. See `BuiltInSpeakerSymbol`.
    static func name(for transport: AudioDeviceTransport, modelUID: String?, builtInSpeakers: String) -> String {
        if let modelUID, let known = knownModel(modelUID) { return known }

        switch transport {
        case .builtIn: return builtInSpeakers
        case .bluetooth: return "headphones"
        case .displayPort, .hdmi: return "display"
        case .airPlay: return "airplayaudio"
        case .virtual: return "waveform"
        case .usb, .thunderbolt, .aggregate, .fireWire, .pci, .continuityCapture, .unknown: return generic
        }
    }

    /// Transport cannot tell a Studio Display from a dock, because both are USB audio, but the
    /// model identifier can. Its last two fields are the USB vendor and product, which no rename
    /// and no change of language touches — unlike the device name, which is both. Only devices
    /// whose shape is actually known belong here.
    private static let byVendorAndProduct = [
        ":05AC:1118": "display", // Apple Studio Display
    ]

    private static func knownModel(_ modelUID: String) -> String? {
        byVendorAndProduct.first { modelUID.hasSuffix($0.key) }?.value
    }
}
