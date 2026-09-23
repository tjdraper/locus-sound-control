import AppKit

/// Gives the app a Dock icon while any of its windows is open, so they show up in Cmd+Tab and can
/// be found again after the user switches away.
final class DockIconPresence {
    private var openWindows: Set<ObjectIdentifier> = []

    func windowWillShow(_ window: NSWindow) {
        openWindows.insert(ObjectIdentifier(window))
        NSApp.setActivationPolicy(.regular)
    }

    func windowWillClose(_ window: NSWindow) {
        openWindows.remove(ObjectIdentifier(window))
        if openWindows.isEmpty {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
