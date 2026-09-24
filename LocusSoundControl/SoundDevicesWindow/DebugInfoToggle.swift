import AppKit

/// The View menu's Show Debug Info item, which shows each Sound Devices row's transport, UIDs and
/// model identifier. Hidden by default: they are how matching is checked against a real setup and
/// how a merge the app made on its own is seen, which is diagnosis rather than everyday use.
final class DebugInfoToggle: NSObject, NSMenuItemValidation {
    static let defaultsKey = "ShowDebugInfo"

    func makeMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Show Debug Info", action: #selector(toggle), keyEquivalent: "")
        item.target = self
        if #available(macOS 27.0, *) { item.preferredImageVisibility = .hidden }
        return item
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        menuItem.state = UserDefaults.standard.bool(forKey: Self.defaultsKey) ? .on : .off
        return true
    }

    @objc private func toggle(_: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.set(!defaults.bool(forKey: Self.defaultsKey), forKey: Self.defaultsKey)
    }
}
