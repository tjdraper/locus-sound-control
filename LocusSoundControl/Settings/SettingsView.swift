import AppKit
import SwiftUI

struct SettingsView: View {
    let updates: UpdateController
    let launchAtLogin: LaunchAtLoginStore
    let bluetoothAccess: BluetoothAccessStore
    let iCloudSync: ICloudSyncCoordinator

    var body: some View {
        Form {
            Section {
                LaunchAtLoginToggle(store: launchAtLogin)
            }

            Section {
                BluetoothAccessRow(store: bluetoothAccess)
            } header: {
                Text("Permissions")
            } footer: {
                Text("""
                Locus Sound Control reads what kind of device each paired Bluetooth device is. It \
                never scans for or connects to devices.
                """)
                .foregroundStyle(.secondary)
            }

            Section("Sync") {
                ICloudSyncToggle(sync: iCloudSync)
            }

            UpdateSettingsSection(updates: updates)
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize()
        .task {
            // These settings can change in System Settings while this window is open or closed.
            refresh()
            for await _ in NotificationCenter.default.notifications(named: NSApplication.didBecomeActiveNotification) {
                refresh()
            }
        }
    }

    private func refresh() {
        launchAtLogin.refresh()
        bluetoothAccess.refresh()
    }
}
