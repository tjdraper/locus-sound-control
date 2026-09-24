import SwiftUI

struct OutputDeviceRow: View {
    let entry: DeviceEntry

    /// Absent when the device is not connected.
    let device: AudioOutputDevice?

    let isCurrentOutput: Bool
    let isOverride: Bool
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: entry.symbolName)
                    .font(.title3)
                    .frame(width: 28, alignment: .center)
                    .foregroundStyle(iconStyle)

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.name)
                        .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }

                    // The identifiers slice 6 matches on, shown because they are the whole reason
                    // that slice is hard and this is where they can be read against a real setup.
                    // Not selectable: selecting text starts on the same drag that reorders the row.
                    Text("\(entry.transport.displayName) · \(uids)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let modelUID = entry.modelUID {
                        Text(modelUID)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .opacity(device == nil ? 0.5 : 1)

            Spacer(minLength: 12)

            HStack(spacing: 6) {
                if let status {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if isOverride {
                    overrideTag
                }
            }
        }
        .padding(.vertical, 4)
    }

    /// A selected row is highlighted in the accent color, so a tinted icon would disappear into it.
    private var iconStyle: AnyShapeStyle {
        isCurrentOutput && !isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary)
    }

    private var uids: String {
        device?.uid ?? entry.uids.sorted().joined(separator: ", ")
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
