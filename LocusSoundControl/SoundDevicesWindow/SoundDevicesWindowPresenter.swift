import AppKit
import SwiftUI

/// The Sound Devices window. A plain AppKit window hosting a SwiftUI view, because the menu that
/// opens it is AppKit and SwiftUI's `openWindow` only reaches scenes.
final class SoundDevicesWindowPresenter: NSObject, NSWindowDelegate {
    private let outputDevices: OutputDeviceInventory
    private let priorityOrder: PriorityOrderStore
    private let override: OverrideStore
    private let bluetoothAccess: BluetoothAccessStore
    private let dockIcon: DockIconPresence
    private let commands: DeviceCommandCoordinator
    private lazy var window = makeWindow()

    /// The target of the View menu's item, which does not retain it.
    let debugInfo = DebugInfoToggle()

    /// The File menu's delegate, which the main menu does not retain.
    private(set) lazy var fileMenu = SoundDevicesFileMenu(commands: commands) { [weak self] in
        // Asked through the delegate, since reading `window` would build it.
        NSApp.keyWindow?.delegate === self
    }

    init(
        outputDevices: OutputDeviceInventory,
        priorityOrder: PriorityOrderStore,
        override: OverrideStore,
        bluetoothAccess: BluetoothAccessStore,
        dockIcon: DockIconPresence
    ) {
        self.outputDevices = outputDevices
        self.priorityOrder = priorityOrder
        self.override = override
        self.bluetoothAccess = bluetoothAccess
        self.dockIcon = dockIcon
        commands = DeviceCommandCoordinator(outputDevices: outputDevices, priorityOrder: priorityOrder, override: override)
    }

    func show() {
        dockIcon.windowWillShow(window)
        AppActivation.bringToFront()
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_: Notification) {
        dockIcon.windowWillClose(window)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(
            rootView: SoundDevicesView(
                outputDevices: outputDevices,
                priorityOrder: priorityOrder,
                override: override,
                commands: commands,
                bluetoothAccess: bluetoothAccess
            )
        ))
        window.title = "Sound Devices"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        RememberedWindowPlacement(autosaveName: "SoundDevices").apply(to: window)
        return window
    }
}
