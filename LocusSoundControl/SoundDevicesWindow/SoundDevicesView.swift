import SwiftUI

struct SoundDevicesView: View {
    let outputDevices: OutputDeviceInventory
    let priorityOrder: PriorityOrderStore
    let override: OverrideStore

    @State private var selection: Set<DeviceEntry.ID> = []

    var body: some View {
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
        // At the bottom rather than the top, so setting an override does not push the list down
        // under the pointer that just double-clicked it. As an inset rather than a sibling, the
        // last row can still scroll clear of it.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let overridden {
                ActiveOverridePanel(entry: overridden) { override.cancel() }
                    .padding(16)
                    .glassEffect(.regular, in: .rect)
            }
        }
        // An inset like the override panel, so a long list or a short window scrolls under it
        // the same way.
        .safeAreaInset(edge: .top, spacing: 0) {
            PriorityOrderHeader()
                .glassEffect(.regular, in: .rect)
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
        .frame(minWidth: 520, idealWidth: 620, maxWidth: 760, minHeight: 360, idealHeight: 480)
    }

    private var overridden: DeviceEntry? {
        override.uid.flatMap { priorityOrder.order.entry(forUID: $0) }
    }

    private func connectedDevice(for entry: DeviceEntry) -> AudioOutputDevice? {
        outputDevices.devices.first { entry.uids.contains($0.uid) }
    }

    private func overrideWithDevice(_ ids: Set<DeviceEntry.ID>) {
        guard ids.count == 1,
              let entry = priorityOrder.order.entries.first(where: { ids.contains($0.id) }),
              let device = connectedDevice(for: entry)
        else { return }
        // The same toggle as choosing it again in the menu.
        if device.uid == override.uid {
            override.cancel()
        } else {
            override.set(device.uid)
        }
    }
}
