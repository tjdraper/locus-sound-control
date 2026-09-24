import SwiftUI

/// The first launch seeds the order from whatever happens to be connected, which is a guess, so
/// the checklist shows it for checking.
struct PriorityOrderRows: View {
    let priorityOrder: PriorityOrderStore
    let showSoundDevices: () -> Void

    /// The top of the order is where a wrong guess shows. Every row makes the checklist taller, and
    /// Arrange… shows the rest.
    private let shownCount = 3

    var body: some View {
        LabeledContent {
            Button("Arrange…", action: showSoundDevices)
        } label: {
            Text("Priority order")
            Text(priorityOrder.isUnarrangedSeed
                ? "Guessed from what’s connected now. Sound plays through the highest device that’s connected."
                : "Sound plays through the highest device that’s connected.")
        }

        let placed = priorityOrder.order.placed
        ForEach(Array(placed.prefix(shownCount).enumerated()), id: \.element.id) { index, entry in
            HStack(spacing: 8) {
                Text("\(index + 1)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 16, alignment: .trailing)
                Image(systemName: DrawableSymbol.name(entry.symbolName))
                    .frame(width: 20)
                Text(entry.name)
            }
        }

        if placed.count > shownCount {
            Text("\(placed.count - shownCount) more in Sound Devices")
                .foregroundStyle(.secondary)
        }
    }
}
