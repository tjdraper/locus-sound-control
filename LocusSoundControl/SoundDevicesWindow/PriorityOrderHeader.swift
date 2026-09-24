import SwiftUI

struct PriorityOrderHeader: View {
    var body: some View {
        ListHeaderPanel(
            symbolName: "arrow.up.arrow.down",
            title: "Priority Order",
            message: """
                Drag devices to change the priority order. Unless an override is active, sound will play \
                through the connected device that is the highest in the priority list. To override, double \
                click or click on a device in the menu.
                """,
            color: .accentColor
        )
    }
}
