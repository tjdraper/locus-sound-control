import SwiftUI

struct SoundDevicesView: View {
    let outputDevices: OutputDeviceInventory

    var body: some View {
        List(outputDevices.devices) { device in
            OutputDeviceRow(
                device: device,
                isCurrentOutput: device.uid == outputDevices.currentOutputUID
            )
        }
        .overlay {
            if outputDevices.devices.isEmpty {
                ContentUnavailableView(
                    "No Output Devices",
                    systemImage: "speaker.slash",
                    description: Text("Nothing on this Mac can play sound right now.")
                )
            }
        }
        .frame(minWidth: 520, minHeight: 360)
    }
}
