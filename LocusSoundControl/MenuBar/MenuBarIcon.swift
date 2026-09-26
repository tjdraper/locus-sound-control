import AppKit

/// The image in the menu bar, showing the kind of device the Mac is playing through, whether an
/// override is holding it there, and whether new devices or an update are waiting on the user.
nonisolated enum MenuBarIcon {
    /// A symbol name the user assigned stops resolving if Apple renames or drops that
    /// symbol, and an empty menu bar would leave no way to reach the app at all.
    static func image(
        symbolName: String,
        deviceName: String?,
        isOverridden: Bool,
        hasDevicesToSort: Bool,
        hasUpdateWaiting: Bool
    ) -> NSImage? {
        var description = deviceName.map { "Sound output: \($0)" } ?? "Sound output"
        if isOverridden { description += ", override active" }
        if hasDevicesToSort { description += ", new devices to sort" }
        if hasUpdateWaiting { description += ", update available" }
        let isBadged = hasDevicesToSort || hasUpdateWaiting

        guard let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: description)
            ?? NSImage(systemSymbolName: OutputDeviceSymbol.generic, accessibilityDescription: description)
        else { return nil }

        if isOverridden {
            let plate = plate(symbol, description: description)
            return isBadged ? badge(plate, description: description) : plate
        }
        guard isBadged else {
            symbol.isTemplate = true
            return symbol
        }
        return badge(tinted(symbol, in: .labelColor), description: description)
    }

    /// A template cannot carry the red badge or sit on the accent plate, so the glyph is colored by
    /// hand, in a color that resolves each time it is drawn. Filling the template's shape keeps it
    /// identical to the plain glyph, where a palette color flattens hierarchical layers.
    private static func tinted(_ symbol: NSImage, in color: NSColor) -> NSImage {
        // Drawn as a template, a symbol keeps faint fills in some of its layers — the inside of
        // `display`, the far bud of `airpods.pro` — which a menu bar template never shows.
        let glyph = symbol.copy() as? NSImage ?? symbol
        glyph.isTemplate = false
        return NSImage(size: symbol.size, flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.beginTransparencyLayer(auxiliaryInfo: nil)
            glyph.draw(in: rect)
            color.setFill()
            rect.fill(using: .sourceAtop)
            context.endTransparencyLayer()
            return true
        }
    }

    private static let plateInset = NSSize(width: 4, height: 2)

    /// The symbol on a rounded rectangle filled with the accent color, the way macOS marks a menu
    /// bar item that is holding something on. It changes the whole shape rather than a corner, so
    /// it still reads apart from the badge.
    ///
    /// Not a template, since a template cannot carry a color. The colors resolve each time the
    /// image is drawn, so a change of accent color only needs the image set again.
    private static func plate(_ symbol: NSImage, description: String) -> NSImage {
        let size = NSSize(
            width: symbol.size.width + plateInset.width * 2,
            height: symbol.size.height + plateInset.height * 2
        )
        let glyph = tinted(symbol, in: .alternateSelectedControlTextColor)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.controlAccentColor.setFill()
            NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4).fill()
            glyph.draw(in: rect.insetBy(dx: plateInset.width, dy: plateInset.height))
            return true
        }
        image.accessibilityDescription = description
        return image
    }

    private static let badgeDiameter: CGFloat = 6

    /// Clear space cut around the badge, so it reads as separate from whatever glyph is under it.
    /// That costs the glyph a corner, which is why the corner is fixed rather than chosen per symbol.
    private static let badgeGap: CGFloat = 1.5

    private static func badge(_ image: NSImage, description: String) -> NSImage {
        let badged = NSImage(size: image.size, flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            let badge = CGRect(
                x: rect.maxX - badgeDiameter,
                y: rect.maxY - badgeDiameter,
                width: badgeDiameter,
                height: badgeDiameter
            )
            // The layer keeps the clear ring to this image. Without it the ring could punch through
            // whatever the image is drawn onto.
            context.beginTransparencyLayer(auxiliaryInfo: nil)
            image.draw(in: rect)
            context.setBlendMode(.clear)
            context.fillEllipse(in: badge.insetBy(dx: -badgeGap, dy: -badgeGap))
            context.setBlendMode(.normal)
            NSColor.systemRed.setFill()
            context.fillEllipse(in: badge)
            context.endTransparencyLayer()
            return true
        }
        badged.accessibilityDescription = description
        return badged
    }
}
