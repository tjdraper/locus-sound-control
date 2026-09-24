import AppKit

/// The image in the menu bar, showing the kind of device the Mac is playing through. Slice 6
/// draws the new-device badge into it.
nonisolated enum MenuBarIcon {
    /// A symbol name the user assigned stops resolving if Apple renames or drops that
    /// symbol, and an empty menu bar would leave no way to reach the app at all.
    static func image(symbolName: String, deviceName: String?, isOverridden: Bool) -> NSImage? {
        var description = deviceName.map { "Sound output: \($0)" } ?? "Sound output"
        if isOverridden { description += ", override active" }

        guard let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: description)
            ?? NSImage(systemSymbolName: OutputDeviceSymbol.generic, accessibilityDescription: description)
        else { return nil }

        guard isOverridden else {
            symbol.isTemplate = true
            return symbol
        }
        return plate(symbol, description: description)
    }

    private static let plateInset = NSSize(width: 4, height: 2)

    /// The symbol on a rounded rectangle filled with the accent color, the way macOS marks a menu
    /// bar item that is holding something on. It changes the whole shape rather than a corner, so
    /// it still reads apart from slice 6's badge.
    ///
    /// Not a template, since a template cannot carry a color. The colors resolve each time the
    /// image is drawn, so a change of accent color only needs the image set again.
    private static func plate(_ symbol: NSImage, description: String) -> NSImage {
        let size = NSSize(
            width: symbol.size.width + plateInset.width * 2,
            height: symbol.size.height + plateInset.height * 2
        )
        let glyph = symbol.withSymbolConfiguration(
            NSImage.SymbolConfiguration(paletteColors: [.alternateSelectedControlTextColor])
        ) ?? symbol
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.controlAccentColor.setFill()
            NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4).fill()
            glyph.draw(in: rect.insetBy(dx: plateInset.width, dy: plateInset.height))
            return true
        }
        image.accessibilityDescription = description
        return image
    }
}
