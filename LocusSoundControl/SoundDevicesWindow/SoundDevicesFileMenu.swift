import AppKit

/// The File menu, offering the same commands as the Sound Devices list's context menu, for its
/// selection. A context menu alone hides them from anyone who does not think to right-click.
final class SoundDevicesFileMenu: NSObject, NSMenuDelegate {
    private let commands: DeviceCommandCoordinator
    private let isWindowKey: () -> Bool

    init(commands: DeviceCommandCoordinator, isWindowKey: @escaping () -> Bool) {
        self.commands = commands
        self.isWindowKey = isWindowKey
    }

    /// Rebuilt on every open, since the titles count the selection.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let groups = isWindowKey() ? commands.groups(for: commands.selection) : []

        guard !groups.isEmpty else {
            addSeparated(DeviceCommand.nothingSelectedTitles, to: menu) { title in
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.isEnabled = false
                item.refuseAutomaticImage()
                return item
            }
            return
        }

        addSeparated(groups, to: menu) { command in
            let item = NSMenuItem(title: command.title, action: #selector(performCommand), keyEquivalent: "")
            item.target = self
            item.isEnabled = true
            item.representedObject = command
            item.refuseAutomaticImage()
            return item
        }
    }

    @objc private func performCommand(_ sender: NSMenuItem) {
        guard let command = sender.representedObject as? DeviceCommand else { return }
        commands.perform(command)
    }

    private func addSeparated<Element>(_ groups: [[Element]], to menu: NSMenu, item: (Element) -> NSMenuItem) {
        for (index, group) in groups.enumerated() {
            if index > 0 { menu.addItem(.separator()) }
            for element in group {
                menu.addItem(item(element))
            }
        }
    }
}
