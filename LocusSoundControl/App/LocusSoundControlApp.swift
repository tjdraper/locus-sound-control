import SwiftUI

@main
struct LocusSoundControlApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Locus Sound Control", systemImage: "hifispeaker") {
            MenuBarMenu(updates: appDelegate.updates)
        }

        Window("Sound Devices", id: SoundDevicesWindow.id) {
            SoundDevicesWindow()
        }
    }
}
