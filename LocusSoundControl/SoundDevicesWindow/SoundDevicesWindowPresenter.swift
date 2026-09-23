import AppKit
import SwiftUI

/// The Sound Devices window. A plain AppKit window hosting a SwiftUI view, because the menu that
/// opens it is AppKit and SwiftUI's `openWindow` only reaches scenes.
final class SoundDevicesWindowPresenter: NSObject, NSWindowDelegate {
    private let outputDevices: OutputDeviceInventory
    private let priorityOrder: PriorityOrderStore
    private let dockIcon: DockIconPresence
    private lazy var window = makeWindow()

    init(outputDevices: OutputDeviceInventory, priorityOrder: PriorityOrderStore, dockIcon: DockIconPresence) {
        self.outputDevices = outputDevices
        self.priorityOrder = priorityOrder
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
            rootView: SoundDevicesView(outputDevices: outputDevices, priorityOrder: priorityOrder)
        ))
        window.title = "Sound Devices"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        RememberedWindowPlacement(autosaveName: "SoundDevices").apply(to: window)
        return window
    }
}
