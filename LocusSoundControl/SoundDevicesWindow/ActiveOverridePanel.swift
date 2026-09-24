import SwiftUI

/// Shown while an override is active, since it means the priority order is not what is deciding the
/// output.
struct ActiveOverridePanel: View {
    let entry: DeviceEntry
    let cancel: () -> Void

    private let panel = RoundedRectangle(cornerRadius: 10, style: .continuous)

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.symbolName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color(nsColor: .alternateSelectedControlTextColor))
                .frame(width: 36, height: 36)
                .background(.tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Override Active")
                    .font(.headline)
                Text(
                    """
                    Sound stays on \(Text(entry.name).bold()) whatever the priority order says, until the \
                    override is cancelled or the device disconnects.
                    """
                )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Button("Cancel Override", action: cancel)
                .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Stronger than the priority order header, so the two read as state and explanation
        // rather than as a pair.
        .background(.tint.opacity(0.16), in: panel)
        .overlay(panel.strokeBorder(.tint, lineWidth: 1.5))
    }
}
