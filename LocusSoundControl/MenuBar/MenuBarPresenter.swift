import AppKit

/// Owns the menu bar item: its image follows the current output, and its menu is rebuilt each
/// time it opens.
///
/// This is AppKit rather than SwiftUI's `MenuBarExtra` because that menu draws no icons: neither
/// the icon of a `Label` nor an `Image(nsImage:)` appears. macOS 27 hides menu item images unless
/// the item sets `preferredImageVisibility`, and SwiftUI offers no way to reach it.
final class MenuBarPresenter: NSObject {
    private let outputDevices: OutputDeviceInventory
    private let priorityOrder: PriorityOrderStore
    private let override: OverrideStore
    private let updates: UpdateController
    private let showSoundDevices: () -> Void

    private lazy var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var iconTask: Task<Void, Never>?

    init(
        outputDevices: OutputDeviceInventory,
        priorityOrder: PriorityOrderStore,
        override: OverrideStore,
        updates: UpdateController,
        showSoundDevices: @escaping () -> Void
    ) {
        self.outputDevices = outputDevices
        self.priorityOrder = priorityOrder
        self.override = override
        self.updates = updates
        self.showSoundDevices = showSoundDevices
    }

    deinit {
        iconTask?.cancel()
    }

    func start() {
        let menu = NSMenu()
        menu.delegate = self
        // Automatic enabling asks the responder chain, which would enable "Check for Updates…"
        // whatever Sparkle says about it. Every item states its own instead.
        menu.autoenablesItems = false
        statusItem.menu = menu

        // macOS switches to a device the moment it connects, before the device list has settled
        // enough to include it. The remembered entry already knows its icon, so the menu bar does
        // not flash a generic speaker while the list catches up.
        iconTask = Task { [weak self, outputDevices, priorityOrder] in
            let current = Observations {
                (
                    outputDevices.currentOutputUID.flatMap { priorityOrder.order.entry(forUID: $0) },
                    outputDevices.currentDevice
                )
            }
            for await (entry, device) in current {
                self?.statusItem.button?.image = MenuBarIcon.image(
                    symbolName: entry?.symbolName ?? device?.symbolName ?? OutputDeviceSymbol.generic,
                    deviceName: entry?.name ?? device?.name
                )
            }
        }
    }

    @objc private func overrideWithDevice(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? AudioOutputDevice else { return }
        override.set(device.uid)
    }

    @objc private func cancelOverride() {
        override.cancel()
    }

    @objc private func openSoundDevices() {
        showSoundDevices()
    }

    @objc private func checkForUpdates() {
        updates.checkForUpdates()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

extension MenuBarPresenter: NSMenuDelegate {
    /// Rebuilt on every open rather than kept in step with the inventory, since the only moment
    /// its contents are visible is the moment after this runs.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let devices = OutputDeviceMenuBuilder.rows(
            for: priorityOrder.order.inPriorityOrder(outputDevices.devices),
            currentOutputUID: outputDevices.currentOutputUID,
            target: self,
            action: #selector(overrideWithDevice)
        )
        for row in devices {
            menu.addItem(row)
        }
        if override.uid != nil {
            menu.addItem(item(title: "Cancel Override", action: #selector(cancelOverride)))
        }

        if !devices.isEmpty { menu.addItem(.separator()) }
        menu.addItem(item(title: "Sound Devices…", action: #selector(openSoundDevices)))

        menu.addItem(.separator())
        let update = item(title: "Check for Updates…", action: #selector(checkForUpdates))
        update.isEnabled = updates.canCheckForUpdates
        menu.addItem(update)

        menu.addItem(.separator())
        menu.addItem(item(title: "Quit Locus Sound Control", action: #selector(quit), keyEquivalent: "q"))
    }

    func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?) {
        OutputDeviceMenuBuilder.applyHighlight(item, in: menu)
    }

    private func item(title: String, action: Selector, keyEquivalent: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        item.isEnabled = true
        return item
    }
}
