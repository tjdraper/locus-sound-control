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
                        .help(mergeExplanation ?? "")

                    // The identifiers devices are matched on, shown because they are the whole
                    // reason matching is hard and this is where they can be read against a real
                    // setup. Every UID an entry covers is listed, so which ones a merge joined can
                    // be read rather than guessed at.
                    if showsDebugInfo {
                        ForEach(uids, id: \.self) { uid in
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

    /// How the device is connected, and whether this row stands for more than one device macOS
    /// reports. The app merges some on its own, such as a dock seen through a different port, so
    /// a merge the user never asked for is said here rather than left for them to wonder about.
    private var connectionLine: String {
        let merged = entry.uids.count > 1 ? "Merged from \(entry.uids.count) devices" : nil
        return [entry.transport.displayName, merged].compactMap(\.self).joined(separator: " · ")
    }

    private var mergeExplanation: String? {
        guard entry.uids.count > 1 else { return nil }
        return "macOS has reported this device \(entry.uids.count) different ways, for example once for "
            + "each port it has been plugged into. If they are not really one device, split them apart."
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
