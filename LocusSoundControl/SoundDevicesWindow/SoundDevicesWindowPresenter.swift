import AppKit
import SwiftUI

/// The Sound Devices window. A plain AppKit window hosting a SwiftUI view, because the menu that
/// opens it is AppKit and SwiftUI's `openWindow` only reaches scenes.
final class SoundDevicesWindowPresenter {
    private let outputDevices: OutputDeviceInventory
    private let priorityOrder: PriorityOrderStore
    private lazy var window = makeWindow()

    init(outputDevices: OutputDeviceInventory, priorityOrder: PriorityOrderStore) {
        self.outputDevices = outputDevices
        self.priorityOrder = priorityOrder
    }

    func show() {
        AppActivation.bringToFront()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(
            rootView: SoundDevicesView(outputDevices: outputDevices, priorityOrder: priorityOrder)
        ))
        window.title = "Sound Devices"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        RememberedWindowPlacement(autosaveName: "SoundDevices").apply(to: window)
        return window
    }
}
