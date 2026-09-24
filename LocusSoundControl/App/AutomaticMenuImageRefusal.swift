import AppKit

extension NSMenuItem {
    /// macOS 26 and later give menu items with standard titles a symbol of their own choosing, such
    /// as a gear on "Settings…". macOS 27 lets an item decline it. macOS 26 has no way to, but only
    /// fills an item that has no image, so the item gets an empty one that draws nothing.
    func refuseAutomaticImage() {
        if #available(macOS 27.0, *) {
            preferredImageVisibility = .hidden
        } else {
            image = NSImage(size: NSSize(width: 1, height: 1))
        }
    }
}
