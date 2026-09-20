import SwiftUI

struct SoundDevicesWindow: View {
    static let id = "sound-devices"

    var body: some View {
        Text("No output devices yet.")
            .foregroundStyle(.secondary)
            .frame(minWidth: 420, minHeight: 320)
    }
}
