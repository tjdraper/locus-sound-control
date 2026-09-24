import AppKit
import SwiftUI

/// The banner at the top of the menu while an override is active. An override stops the priority
/// order from doing its job, so it is drawn to be noticed rather than as one more row.
enum ActiveOverrideMenuItem {
    static func make(device: AudioOutputDevice, cancel: @escaping () -> Void) -> NSMenuItem {
        let view = NSHostingView(rootView: ActiveOverrideBanner(device: device, cancel: cancel))
        view.frame.size = view.fittingSize
        // The menu widens a view to its own width only when the view says it can stretch.
        view.autoresizingMask = [.width]

        let item = NSMenuItem()
        item.view = view
        return item
    }
}

private struct ActiveOverrideBanner: View {
    let device: AudioOutputDevice
    let cancel: () -> Void

    private let panel = RoundedRectangle(cornerRadius: 8, style: .continuous)

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: device.symbolName)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(nsColor: .alternateSelectedControlTextColor))
                .frame(width: 30, height: 30)
                .background(.tint, in: RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text("Override Active")
                    .font(.headline)
                Text(device.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 16)

            Button("Cancel Override", action: cancel)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(10)
        .background(.tint.opacity(0.12), in: panel)
        .overlay(panel.strokeBorder(.tint.opacity(0.4), lineWidth: 1))
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        // The menu's window never becomes key, so controls in it would otherwise follow whichever
        // window is, and draw inactive whenever the app's own window is not in front.
        .environment(\.controlActiveState, .key)
    }
}
