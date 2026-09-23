import SwiftUI

struct SoundDevicesView: View {
    let outputDevices: OutputDeviceInventory
    let priorityOrder: PriorityOrderStore

    var body: some View {
        VStack(spacing: 0) {
            PriorityOrderHeader()
            List {
                ForEach(priorityOrder.order.entries) { entry in
                    let device = outputDevices.devices.first { entry.uids.contains($0.uid) }
                    OutputDeviceRow(
                        entry: entry,
                        device: device,
                        isCurrentOutput: device != nil && device?.uid == outputDevices.currentOutputUID
                    )
                }
                .onMove { priorityOrder.move(fromOffsets: $0, toOffset: $1) }
            }
            .overlay {
                if priorityOrder.order.entries.isEmpty {
                    ContentUnavailableView(
                        "No Output Devices",
                        systemImage: "speaker.slash",
                        description: Text("Nothing on this Mac can play sound right now.")
                    )
                }
            }
        }
        .frame(minWidth: 520, idealWidth: 620, maxWidth: 760, minHeight: 360, idealHeight: 480)
    }
}
