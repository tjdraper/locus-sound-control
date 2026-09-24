import AppKit
import SwiftUI

/// Every setup step on one page. Each row shows the setting's real state, so a change made in
/// System Settings or the Sound Devices window shows up here too.
struct FirstRunView: View {
    @Bindable var updates: UpdateController
    let launchAtLogin: LaunchAtLoginStore
    let bluetoothAccess: BluetoothAccessStore
    let priorityOrder: PriorityOrderStore
    let screenFit: ScreenFit
    let showSoundDevices: () -> Void
    let onDone: () -> Void

    var body: some View {
        Form {
            Section {
                welcome
            }

            if ApplicationsFolderMoveWorkflow.isAvailable {
                Section {
                    ApplicationsFolderRow()
                }
            }

            Section {
                PriorityOrderRows(priorityOrder: priorityOrder, showSoundDevices: showSoundDevices)
            }

            Section {
                BluetoothAccessRow(store: bluetoothAccess)
            } header: {
                Text("Permissions")
            } footer: {
                Text("""
                Optional. Bluetooth access tells a Bluetooth speaker from headphones, so each gets \
                the right icon. Locus Sound Control reads what kind each paired device is, and never \
                scans for or connects to devices. Skip it if you like, and allow it later in Settings.
                """)
                .foregroundStyle(.secondary)
            }

            Section {
                LaunchAtLoginToggle(store: launchAtLogin)
            }

            Section("Updates") {
                Toggle("Check for updates automatically", isOn: $updates.automaticallyChecksForUpdates)
            }
        }
        .formStyle(.grouped)
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack {
                Spacer()
                Button("Done", action: onDone)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .glassEffect(.regular, in: .rect)
        }
        .frame(width: 480)
        // Only as tall as the steps need, unless the screen is shorter, when the steps scroll.
        .frame(maxHeight: screenFit.maxContentHeight)
        .fixedSize()
        .task {
            refresh()
            for await _ in NotificationCenter.default.notifications(named: NSApplication.didBecomeActiveNotification) {
                refresh()
            }
        }
    }

    private var welcome: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome to Locus Sound Control")
                    .font(.title2.bold())
                Text("Set up Locus Sound Control here. You can open this again from the menu bar.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }

    private func refresh() {
        launchAtLogin.refresh()
        bluetoothAccess.refresh()
    }
}
