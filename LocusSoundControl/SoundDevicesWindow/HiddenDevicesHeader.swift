import SwiftUI

struct HiddenDevicesHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Hidden")
            Text("Never chosen automatically, and left out of the menu. Double-click one to override with it.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 12)
    }
}
