import CoreBluetooth
import SwiftUI

/// Explains, where the icons are being looked at, why a Bluetooth speaker wears a headphones icon.
struct BluetoothAccessDeniedNote: View {
    let store: BluetoothAccessStore

    var body: some View {
        HStack(spacing: 6) {
            if store.authorization == .restricted {
                Text("This Mac’s administrator doesn’t allow Bluetooth access, so some Bluetooth speakers show a headphones icon.")
            } else {
                Text("Bluetooth access is off, so some Bluetooth speakers show a headphones icon.")
                Button("Open System Settings") {
                    store.openBluetoothSettings()
                }
                .buttonStyle(.link)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 8)
        .listRowSeparator(.hidden)
        .selectionDisabled()
    }
}
