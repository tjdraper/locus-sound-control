import AppKit
import SwiftUI

struct MenuBarMenu: View {
    let updates: UpdateController

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Sound Devices…") {
            openWindow(id: SoundDevicesWindow.id)
            AppActivation.bringToFront()
        }

        Divider()

        Button("Check for Updates…") {
            updates.checkForUpdates()
        }
        .disabled(!updates.canCheckForUpdates)

        Divider()

        Button("Quit Locus Sound Control") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
