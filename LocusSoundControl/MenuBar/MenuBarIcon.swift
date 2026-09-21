import AppKit

/// The image in the menu bar, showing the kind of device the Mac is playing through. Slice 6
/// draws the new-device badge into it.
nonisolated enum MenuBarIcon {
    /// A symbol name the user assigned in slice 5 stops resolving if Apple renames or drops that
    /// symbol, and an empty menu bar would leave no way to reach the app at all.
    static func image(symbolName: String, deviceName: String?) -> NSImage? {
        let description = deviceName.map { "Sound output: \($0)" } ?? "Sound output"
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: description)
            ?? NSImage(systemSymbolName: OutputDeviceSymbol.generic, accessibilityDescription: description)
        image?.isTemplate = true
        return image
    }
}
