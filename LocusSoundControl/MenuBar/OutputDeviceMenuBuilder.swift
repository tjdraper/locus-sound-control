import AppKit

/// Builds the device rows of the menu bar menu.
enum OutputDeviceMenuBuilder {
    private static let iconPointSize: CGFloat = 14

    static func rows(
        for devices: [AudioOutputDevice],
        currentOutputUID: String?,
        target: AnyObject,
        action: Selector
    ) -> [NSMenuItem] {
        devices.map { device in
            let isCurrentOutput = device.uid == currentOutputUID
            let row = NSMenuItem(title: device.name, action: action, keyEquivalent: "")
            row.target = target
            row.isEnabled = true
            row.representedObject = device
            row.image = icon(device.symbolName, tint: isCurrentOutput ? .accent : nil)
            // macOS 27 hides menu item images by default; an item has to ask for its own.
            if #available(macOS 27.0, *) { row.preferredImageVisibility = .visible }
            row.state = isCurrentOutput ? .on : .off
            return row
        }
    }

    /// The highlight behind a row is drawn in the accent color too, so the tinted icon would
    /// disappear into it. Only that row needs swapping: every other image is a template, which
    /// the menu recolors for the highlight by itself.
    static func applyHighlight(_ highlighted: NSMenuItem?, in menu: NSMenu) {
        for row in menu.items where row.state == .on {
            guard let device = row.representedObject as? AudioOutputDevice else { continue }
            row.image = icon(device.symbolName, tint: row === highlighted ? .highlighted : .accent)
        }
    }

    private enum Tint {
        case accent
        case highlighted

        var color: NSColor {
            switch self {
            case .accent: .controlAccentColor
            case .highlighted: .selectedMenuItemTextColor
            }
        }
    }

    /// Palette colors are what make an image carry its own color, and asking for them is also
    /// what stops it being a template. No tint leaves it a template, following the menu's text.
    private static func icon(_ symbolName: String, tint: Tint?) -> NSImage? {
        var configuration = NSImage.SymbolConfiguration(pointSize: iconPointSize, weight: .regular)
        if let tint {
            configuration = configuration.applying(
                NSImage.SymbolConfiguration(paletteColors: [tint.color])
            )
        }
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
            ?? NSImage(systemSymbolName: OutputDeviceSymbol.generic, accessibilityDescription: nil)
        return image?.withSymbolConfiguration(configuration)
    }
}
