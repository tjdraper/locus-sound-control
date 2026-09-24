import AppKit
import SwiftUI

/// Shows the setup checklist on a first run, and again whenever the user asks for it.
final class FirstRunWindowPresenter: NSObject, NSWindowDelegate {
    private let updates: UpdateController
    private let launchAtLogin: LaunchAtLoginStore
    private let bluetoothAccess: BluetoothAccessStore
    private let priorityOrder: PriorityOrderStore
    private let dockIcon: DockIconPresence
    private let showSoundDevices: () -> Void
    private let screenFit = ScreenFit()
    private lazy var window = makeWindow()

    init(
        updates: UpdateController,
        launchAtLogin: LaunchAtLoginStore,
        bluetoothAccess: BluetoothAccessStore,
        priorityOrder: PriorityOrderStore,
        dockIcon: DockIconPresence,
        showSoundDevices: @escaping () -> Void
    ) {
        self.updates = updates
        self.launchAtLogin = launchAtLogin
        self.bluetoothAccess = bluetoothAccess
        self.priorityOrder = priorityOrder
        self.dockIcon = dockIcon
        self.showSoundDevices = showSoundDevices
    }

    func show() {
        updates.defaultToAutomaticChecks()
        screenFit.update(for: window)
        dockIcon.windowWillShow(window)
        AppActivation.bringToFront()
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_: Notification) {
        dockIcon.windowWillClose(window)
    }

    // These two arrive while `makeWindow()` is still sizing the window, when reading `window`
    // would build it again, so they take it from the notification.
    func windowDidChangeScreen(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        screenFit.update(for: window)
    }

    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        screenFit.keepOnScreen(window)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(
            rootView: FirstRunView(
                updates: updates,
                launchAtLogin: launchAtLogin,
                bluetoothAccess: bluetoothAccess,
                priorityOrder: priorityOrder,
                screenFit: screenFit,
                showSoundDevices: showSoundDevices,
                // Only Done finishes the first run. Closing the window or quitting, including the
                // relaunch after moving to Applications, brings the checklist back next launch.
                onDone: { [weak self] in
                    FirstRunStatus().markCompleted()
                    self?.window.close()
                }
            )
        ))
        window.title = "Set Up Locus Sound Control"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        screenFit.update(for: window)
        RememberedWindowPlacement(autosaveName: "Setup").apply(to: window)
        return window
    }
}
