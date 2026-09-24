import AppKit

/// A stored symbol name stops resolving if Apple renames or drops that symbol, and SwiftUI's
/// `Image(systemName:)` then draws nothing at all, leaving a gap where the device's icon was.
enum DrawableSymbol {
    static func name(_ symbolName: String) -> String {
        NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) == nil ? OutputDeviceSymbol.generic : symbolName
    }
}
