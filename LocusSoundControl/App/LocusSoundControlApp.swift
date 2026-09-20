import SwiftUI

@main
struct LocusSoundControlApp: App {
    var body: some Scene {
        MenuBarExtra("Locus Sound Control", systemImage: "hifispeaker") {
            MenuBarMenu()
        }

        Window("Sound Devices", id: SoundDevicesWindow.id) {
            SoundDevicesWindow()
        }
    }
}
