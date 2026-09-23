import SwiftUI

struct SoundDevicesView: View {
    let outputDevices: OutputDeviceInventory
    let priorityOrder: PriorityOrderStore
    let override: OverrideStore

    @State private var selection: Set<DeviceEntry.ID> = []

    var body: some View {
        VStack(spacing: 0) {
            PriorityOrderHeader()
            List(selection: $selection) {
                ForEach(priorityOrder.order.entries) { entry in
                    let device = connectedDevice(for: entry)
                    OutputDeviceRow(
                        entry: entry,
                        device: device,
                        isCurrentOutput: device != nil && device?.uid == outputDevices.currentOutputUID,
                        isOverride: device != nil && device?.uid == override.uid,
                        isSelected: selection.contains(entry.id)
                    )
                }
                .onMove { priorityOrder.move(fromOffsets: $0, toOffset: $1) }
            }
            // A list row has no double-click action of its own. On macOS, this primary action is what
            // a double-click on a row runs.
            .contextMenu(forSelectionType: DeviceEntry.ID.self, menu: { _ in EmptyView() }, primaryAction: overrideWithDevice)
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

    private func connectedDevice(for entry: DeviceEntry) -> AudioOutputDevice? {
        outputDevices.devices.first { entry.uids.contains($0.uid) }
    }

    private func overrideWithDevice(_ ids: Set<DeviceEntry.ID>) {
        guard ids.count == 1,
              let entry = priorityOrder.order.entries.first(where: { ids.contains($0.id) }),
              let device = connectedDevice(for: entry)
        else { return }
        override.set(device.uid)
    }
}
