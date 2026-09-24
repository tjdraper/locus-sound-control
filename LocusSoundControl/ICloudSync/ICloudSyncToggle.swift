import SwiftUI

struct ICloudSyncToggle: View {
    @Bindable var sync: ICloudSyncCoordinator

    var body: some View {
        Toggle(isOn: $sync.isEnabled) {
            Text("Sync with iCloud")
            Text("""
            Keeps the priority order, hidden devices, icons and new devices the same on your other \
            Macs. An override stays on this Mac.
            """)
        }
    }
}
