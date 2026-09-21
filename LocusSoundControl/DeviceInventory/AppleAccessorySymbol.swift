import UniformTypeIdentifiers

/// Names the exact Apple audio accessory a device is, from the model identifier CoreAudio reports.
///
/// macOS declares every accessory it knows about as a uniform type carrying the accessory's
/// Bluetooth vendor and product id as a tag, which makes this Apple's own catalog rather than a
/// table of product ids kept by hand. Matching on the parent type rather than the exact one means
/// a later generation is recognized without a change here: `com.apple.power-beats-pro-gen2`
/// conforms to `com.apple.power-beats-pro`, and `com.apple.airpods-gen5` to `com.apple.airpods`.
nonisolated enum AppleAccessorySymbol {
    static func name(forModelUID modelUID: String) -> String? {
        guard let accessory = accessory(forModelUID: modelUID) else { return nil }
        return symbolsByType.first { accessory.conforms(to: $0.type) }?.symbolName
    }

    /// Ordered most specific first. Apple keeps a catch-all, `com.apple.beats-headphones`, that
    /// several of these also conform to — the Beats Pill among them, which is a speaker.
    ///
    /// The lines Apple files only under that catch-all — Solo, Studio, Beats 360 — are left out,
    /// so they fall through to the Bluetooth class of device and a plain `headphones`. The symbol
    /// for them, `beats.headphones`, draws its ear cups as a light grey stroke that flattens to
    /// something visibly fainter than its neighbours at menu bar size. The rest of the Beats
    /// symbols were checked the same way, with `Scripts/render-sf-symbols.swift`, and hold up.
    private static let symbolsByType: [(type: UTType, symbolName: String)] = [
        ("com.apple.airpods-pro", "airpods.pro"),
        ("com.apple.airpods-max", "airpods.max"),
        ("com.apple.airpods", "airpods"),
        ("com.apple.power-beats-pro", "beats.powerbeatspro"),
        ("com.apple.power-beats-3", "beats.powerbeats3"),
        ("com.apple.power-beats-4", "beats.powerbeats"),
        ("com.apple.beats-fit-pro", "beats.fitpro"),
        ("com.apple.beats-studio-buds", "beats.studiobuds"),
        ("com.apple.beats-solo-buds", "beats.solobuds"),
        ("com.apple.beats-pill", "beats.pill"),
        ("com.apple.beats-x", "beats.earphones"),
        ("com.apple.beats-flex", "beats.earphones"),
    ].compactMap { identifier, symbolName in
        UTType(identifier).map { (type: $0, symbolName: symbolName) }
    }

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
