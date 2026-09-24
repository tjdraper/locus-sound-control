import SwiftUI

struct OutputDeviceRow: View {
    let entry: DeviceEntry

    /// Absent when the device is not connected.
    let device: AudioOutputDevice?

    let isCurrentOutput: Bool
    let isOverride: Bool
    let isSelected: Bool

    /// What the row's own buttons offer. Always for this device alone, whatever else is selected.
    let commands: [DeviceCommand]
    let perform: (DeviceCommand) -> Void

    @AppStorage(DebugInfoToggle.defaultsKey) private var showsDebugInfo = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: DrawableSymbol.name(entry.symbolName))
                    .font(.title3)
                    .frame(width: 28, alignment: .center)
                    .foregroundStyle(iconStyle)

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.name)
                        .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }

                    // Not selectable: selecting text starts on the same drag that reorders the row.
                    Text(connectionLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // The identifiers devices are matched on, shown because they are the whole
                    // reason matching is hard and this is where they can be read against a real
                    // setup. Every UID an entry covers is listed, so a merge the app made on its
                    // own is visible rather than guessed at.
                    if showsDebugInfo {
                        ForEach(uids.dropFirst(), id: \.self) { uid in
                            Text(uid)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let modelUID = entry.modelUID {
                            Text(modelUID)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .opacity(device == nil ? 0.5 : 1)

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 6) {
                    // A space rather than nothing, so this line still sets where the row's first
                    // baseline is and the buttons below stay at the bottom.
                    Text(status ?? " ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(status == nil)
                    if isOverride {
                        overrideTag
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: 2) {
                    ForEach(commands, id: \.self) { command in
                        Button { perform(command) } label: {
                            Label(command.title, systemImage: command.symbolName)
                                .labelStyle(.iconOnly)
                                .frame(width: 20, height: 18)
                        }
                        .help(command.title)
                    }
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
            .frame(maxHeight: .infinity)
        }
        // Lets the trailing column grow to the row's full height, which is what puts the buttons
        // at the bottom.
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 4)
    }

    /// A selected row is highlighted in the accent color, so a tinted icon would disappear into it.
    private var iconStyle: AnyShapeStyle {
        isCurrentOutput && !isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary)
    }

    /// How the device is connected, and with debug info on, the first of its UIDs.
    private var connectionLine: String {
        ([entry.transport.displayName] + (showsDebugInfo ? uids.prefix(1) : [])).joined(separator: " · ")
    }

    /// The connected one first.
    private var uids: [String] {
        let rest = entry.uids.subtracting([device?.uid].compactMap(\.self)).sorted()
        return (device.map { [$0.uid] } ?? []) + rest
    }

    /// Said in words so that a device's state never rests on dimming alone.
    private var status: String? {
        if isCurrentOutput { return "Current Output" }
        return device == nil ? "Not Connected" : nil
    }

    /// A selected row is already filled with the accent color, so the tag steps back to the
    /// row's own text color there instead of disappearing into it.
    private var overrideTag: some View {
        // Not a Label: a Label sets where the list's separator starts, and would pull this row's
        // separator across to the tag.
        HStack(spacing: 4) {
            Image(systemName: "pin.fill")
            Text("Override")
        }
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.tint))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(isSelected ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.tint.opacity(0.15)), in: Capsule())
    }
}
