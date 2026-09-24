import AppKit
import SwiftUI

/// Shows Settings in a plain AppKit window. SwiftUI's `Settings` scene can only be opened from
/// inside a SwiftUI view, and the menu that opens it is AppKit.
final class SettingsWindowPresenter: NSObject, NSWindowDelegate {
    private let updates: UpdateController
    private let launchAtLogin: LaunchAtLoginStore
    private let bluetoothAccess: BluetoothAccessStore
    private let iCloudSync: ICloudSyncCoordinator
    private let dockIcon: DockIconPresence
    private lazy var window = makeWindow()

    init(
        updates: UpdateController,
        launchAtLogin: LaunchAtLoginStore,
        bluetoothAccess: BluetoothAccessStore,
        iCloudSync: ICloudSyncCoordinator,
        dockIcon: DockIconPresence
    ) {
        self.updates = updates
        self.launchAtLogin = launchAtLogin
        self.bluetoothAccess = bluetoothAccess
        self.iCloudSync = iCloudSync
        self.dockIcon = dockIcon
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
            rootView: SettingsView(
                updates: updates,
                launchAtLogin: launchAtLogin,
                bluetoothAccess: bluetoothAccess,
                iCloudSync: iCloudSync
            )
        ))
        window.title = "Locus Sound Control Settings"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        RememberedWindowPlacement(autosaveName: "Settings").apply(to: window)
        return window
    }
}
