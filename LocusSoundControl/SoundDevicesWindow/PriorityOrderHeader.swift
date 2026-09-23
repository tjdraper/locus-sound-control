import SwiftUI

struct PriorityOrderHeader: View {
    private let panel = RoundedRectangle(cornerRadius: 10, style: .continuous)

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.up.arrow.down")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color(nsColor: .alternateSelectedControlTextColor))
                .frame(width: 36, height: 36)
                .background(.tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Priority Order")
                    .font(.headline)
                Text(
                    """
                    Drag devices to change the priority order. Unless an override is active, sound will play \
                    through the connected device that is the highest in the priority list. To override, double \
                    click or click on a device in the menu.
                    """
                )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Opacity rather than fixed tints of the accent, so the panel sits lighter than the accent
        // over a light window and darker over a dark one.
        .background(.tint.opacity(0.07), in: panel)
        .overlay(panel.strokeBorder(.tint.opacity(0.35), lineWidth: 1))
        .padding([.horizontal, .top], 16)
        .padding(.bottom, 8)
    }
}
