import AppKit
import CoreBluetooth

/// Whether the app may read the paired Bluetooth devices, which is how a Bluetooth speaker is told
/// apart from headphones. The user can change it in System Settings, which doesn't announce
/// changes, so callers refresh when the app comes forward.
@Observable
final class BluetoothAccessStore: NSObject {
    private(set) var authorization = CBManager.authorization

    /// The icons already guessed for connected devices were guessed without access, and nothing
    /// else prompts them to be guessed again.
    @ObservationIgnored private let onGranted: () -> Void

    /// Creating a central manager is what raises macOS's prompt, and its state update is how the
    /// answer arrives. It is never asked to scan or connect.
    @ObservationIgnored private var requester: CBCentralManager?

    init(onGranted: @escaping () -> Void) {
        self.onGranted = onGranted
    }

    var isGranted: Bool {
        authorization == .allowedAlways
    }

    /// Denied by the user, or not theirs to allow. Either way macOS will not ask again.
    var wasRefused: Bool {
        authorization == .denied || authorization == .restricted
    }

    func refresh() {
        let wasGranted = isGranted
        authorization = CBManager.authorization
        if isGranted, !wasGranted { onGranted() }
    }

    /// macOS only shows its prompt while the answer is undecided, so after that the way to change
    /// it is System Settings.
    func requestAccess() {
        guard authorization == .notDetermined else {
            openBluetoothSettings()
            return
        }
        requester = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionShowPowerAlertKey: false]
        )
    }

    func openBluetoothSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

extension BluetoothAccessStore: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_: CBCentralManager) {
        // The manager was created with no queue, which delivers its updates on the main queue.
        MainActor.assumeIsolated {
            refresh()
            if authorization != .notDetermined { requester = nil }
        }
    }
}
