import SwiftUI

struct NewDevicesHeader: View {
    var body: some View {
        // Red, to match the badge on the menu bar icon that sends people here.
        ListHeaderPanel(
            symbolName: "sparkles",
            title: "New Devices",
            message: """
                Never chosen automatically until they are in the priority order. Drag each one into the \
                priority order below, or hide the ones you never want chosen.
                """,
            color: .red
        )
    }
}
