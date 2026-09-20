import Sparkle
import SwiftUI

/// Owns the Sparkle updater and mirrors its readiness so the menu item can disable itself
/// while a check is already running.
@Observable
final class UpdateController {
    private let updaterDelegate = UpdaterDelegate()
    private let updaterController: SPUStandardUpdaterController
    private var readinessObservation: NSKeyValueObservation?

    private(set) var canCheckForUpdates = false

    var receivesBetaUpdates: Bool {
        get {
            access(keyPath: \.receivesBetaUpdates)
            return UpdateChannelPreference().receivesBetaUpdates
        }
        set {
            withMutation(keyPath: \.receivesBetaUpdates) {
                UpdateChannelPreference().receivesBetaUpdates = newValue
            }
        }
    }

    var isRunningBeta: Bool {
        UpdateChannelPreference().isRunningBeta
    }

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: updaterDelegate,
            userDriverDelegate: nil
        )
        readinessObservation = updaterController.updater.observe(
            \.canCheckForUpdates,
            options: [.initial, .new]
        ) { [weak self] updater, _ in
            // Sparkle mutates this on the main thread, so the observer fires there too.
            MainActor.assumeIsolated {
                self?.canCheckForUpdates = updater.canCheckForUpdates
            }
        }
    }

    func start() {
        updaterController.startUpdater()
    }

    /// Also brings a waiting update's window forward. Sparkle doesn't announce that, so the app
    /// comes to the front first.
    func checkForUpdates() {
        AppActivation.bringToFront()
        updaterController.checkForUpdates(nil)
    }
}

private final class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    /// Beta items in the appcast are only offered to updaters that name the channel here.
    /// Everyone else sees the default channel alone.
    nonisolated func allowedChannels(for _: SPUUpdater) -> Set<String> {
        UpdateChannelPreference().allowedChannels
    }
}
