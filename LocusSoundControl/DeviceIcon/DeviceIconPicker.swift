import SwiftUI

/// Chooses the icon a device is shown with in the menu bar, the menu and the Sound Devices window.
struct DeviceIconPicker: View {
    let entry: DeviceEntry

    /// Nil goes back to the guessed icon.
    let choose: (String?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Icon for \(entry.name)")
                .font(.headline)
                .lineLimit(1)

            Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 4) {
                ForEach(AssignableSymbols.groups, id: \.self) { group in
                    GridRow {
                        ForEach(group, id: \.self) { symbolName in
                            SymbolChoice(
                                symbolName: symbolName,
                                isChosen: entry.assignedSymbolName == symbolName
                            ) { choose(symbolName) }
                        }
                    }
                }
            }

            Divider()

            HStack(spacing: 8) {
                SymbolChoice(
                    symbolName: DrawableSymbol.name(entry.automaticSymbolName),
                    isChosen: entry.assignedSymbolName == nil
                ) { choose(nil) }
                Text("Automatic")
                Text("Chosen from what the device reports about itself")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
    }
}

private struct SymbolChoice: View {
    let symbolName: String
    let isChosen: Bool
    let choose: () -> Void

    @State private var isHovered = false

    private let cell = RoundedRectangle(cornerRadius: 7, style: .continuous)

    var body: some View {
        Button(action: choose) {
            Image(systemName: symbolName)
                .font(.title3)
                .frame(width: 36, height: 36)
                .foregroundStyle(isChosen ? AnyShapeStyle(Color(nsColor: .alternateSelectedControlTextColor)) : AnyShapeStyle(.primary))
                .background(background, in: cell)
                .contentShape(cell)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(symbolName)
        .accessibilityLabel(symbolName)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }

    private var background: AnyShapeStyle {
        if isChosen { return AnyShapeStyle(.tint) }
        return isHovered ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear)
    }
}
