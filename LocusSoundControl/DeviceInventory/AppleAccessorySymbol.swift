import UniformTypeIdentifiers

/// Tells AirPods, AirPods Pro and AirPods Max apart, from the model identifier CoreAudio reports.
///
/// macOS declares every accessory it knows about as a uniform type carrying the accessory's
/// Bluetooth vendor and product id as a tag, which makes this Apple's own catalog rather than a
/// table of product ids kept by hand. A model that ships with a later macOS is recognized without
/// a change here, because it arrives conforming to the same parent type.
nonisolated enum AppleAccessorySymbol {
    static func name(forModelUID modelUID: String) -> String? {
        guard let accessory = accessory(forModelUID: modelUID) else { return nil }

        // Apple files these as three separate lines rather than one with variants, and no
        // AirPods Pro conforms to `com.apple.airpods`, so the order of these does not matter.
        if let airPodsPro, accessory.conforms(to: airPodsPro) { return "airpods.pro" }
        if let airPodsMax, accessory.conforms(to: airPodsMax) { return "airpods.max" }
        if let airPods, accessory.conforms(to: airPods) { return "airpods" }

        // The rest of what Apple names is the Beats range, which is left to the Bluetooth class
        // of device: it separates their speakers from their headphones, and this cannot — Apple
        // files the Beats Pill, a speaker, under `com.apple.beats-headphones`.
        return nil
    }

    private static let airPods = UTType("com.apple.airpods")
    private static let airPodsPro = UTType("com.apple.airpods-pro")
    private static let airPodsMax = UTType("com.apple.airpods-max")

    /// A Bluetooth device's model identifier is `<product> <vendor>` in lower-case hex. Anything
    /// else is some other kind of device and not in this catalog.
    private static func accessory(forModelUID modelUID: String) -> UTType? {
        let fields = modelUID.split(separator: " ")
        guard fields.count == 2,
              let product = Int(fields[0], radix: 16),
              let vendor = Int(fields[1], radix: 16) else { return nil }

        let accessory = UTType(
            tag: "\(vendor):\(product)",
            tagClass: UTTagClass(rawValue: "public.bluetooth-vendor-product-id"),
            conformingTo: nil
        )
        // An id the catalog does not know comes back as a type invented on the spot, not as nil.
        return accessory?.isDynamic == false ? accessory : nil
    }
}
