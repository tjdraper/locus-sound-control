import SwiftUI

/// Heads a part of the Sound Devices list with what it is and how to use it.
///
/// A row rather than a section header. A list gives section headers a fixed height, which cuts
/// the explanation off once it wraps.
struct ListHeaderPanel: View {
    let symbolName: String
    let title: String
    let message: String
    let color: Color

    private let panel = RoundedRectangle(cornerRadius: 10, style: .continuous)

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color(nsColor: .alternateSelectedControlTextColor))
                .frame(width: 36, height: 36)
                .background(color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Opacity rather than fixed tints, so the panel sits lighter than its color over a light
        // window and darker over a dark one.
        .background(color.opacity(0.05), in: panel)
        .overlay(panel.strokeBorder(color.opacity(0.25), lineWidth: 1))
        .padding(.vertical, 8)
        .listRowSeparator(.hidden)
        .selectionDisabled()
    }
}
