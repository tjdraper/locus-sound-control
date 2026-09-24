import SwiftUI

struct SoundDevicesView: View {
    let outputDevices: OutputDeviceInventory
    let priorityOrder: PriorityOrderStore
    let override: OverrideStore
    let commands: DeviceCommandCoordinator

    var body: some View {
        @Bindable var commands = commands
        List(selection: $commands.selection) {
            ForEach(entries.filter { !$0.isHidden }) { entry in
                row(for: entry)
            }
            .onMove { priorityOrder.moveVisible(fromOffsets: $0, toOffset: $1) }

            let hidden = entries.filter(\.isHidden)
            if !hidden.isEmpty {
                Section {
                    ForEach(hidden) { entry in
                        row(for: entry)
                    }
                } header: {
                    HiddenDevicesHeader()
                }
            }
        }
        // A list row has no double-click action of its own. On macOS, this primary action is what
        // a double-click on a row runs.
        .contextMenu(forSelectionType: DeviceEntry.ID.self, menu: contextMenu, primaryAction: commands.toggleOverride)
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
            if entries.isEmpty {
                ContentUnavailableView(
                    "No Output Devices",
                    systemImage: "speaker.slash",
                    description: Text("Nothing on this Mac can play sound right now.")
                )
            }
        }
        .confirmationDialog(
            forgetTitle,
            isPresented: Binding(get: { !commands.forgetting.isEmpty }, set: { if !$0 { commands.forgetting = [] } })
        ) {
            Button("Forget", role: .destructive, action: commands.confirmForget)
        } message: {
            Text(forgetMessage)
        }
        .frame(minWidth: 520, idealWidth: 620, maxWidth: 760, minHeight: 360, idealHeight: 480)
    }

    private var entries: [DeviceEntry] {
        priorityOrder.order.entries
    }

    private func row(for entry: DeviceEntry) -> some View {
        let device = commands.connectedDevice(for: entry)
        return OutputDeviceRow(
            entry: entry,
            device: device,
            isCurrentOutput: device != nil && device?.uid == outputDevices.currentOutputUID,
            isOverride: device != nil && device?.uid == override.uid,
            isSelected: commands.selection.contains(entry.id),
            commands: commands.groups(for: [entry.id]).flatMap(\.self),
            perform: commands.perform
        )
        .popover(
            isPresented: Binding(
                get: { commands.choosingIconFor == entry.id },
                set: { if !$0 { commands.choosingIconFor = nil } }
            ),
            arrowEdge: .trailing
        ) {
            DeviceIconPicker(entry: entry) { commands.chooseIcon($0, for: entry.id) }
        }
    }

    private func contextMenu(_ ids: Set<DeviceEntry.ID>) -> some View {
        ForEach(Array(commands.groups(for: ids).enumerated()), id: \.offset) { index, group in
            if index > 0 { Divider() }
            ForEach(group, id: \.self) { command in
                Button(command.title) { commands.perform(command) }
            }
        }
    }

    private var forgetTitle: String {
        let forgetting = entries.filter { commands.forgetting.contains($0.id) }
        guard forgetting.count == 1, let entry = forgetting.first else { return "Forget \(forgetting.count) Sound Devices?" }
        return "Forget “\(entry.name)”?"
    }

    private var forgetMessage: String {
        guard commands.forgetting.count == 1 else {
            return "Their places in the priority order and their icons are removed. Any that connect again arrive as new devices."
        }
        return "Its place in the priority order and its icon are removed. If it connects again, it arrives as a new device."
    }

    private var overridden: DeviceEntry? {
        override.uid.flatMap { priorityOrder.order.entry(forUID: $0) }
    }
}
