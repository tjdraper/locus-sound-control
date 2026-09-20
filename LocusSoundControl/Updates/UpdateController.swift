import Sparkle
import SwiftUI

/// Owns the Sparkle updater and mirrors its readiness so the menu item can disable itself
/// while a check is already running.
@Observable
final class UpdateController {
    private let updaterController: SPUStandardUpdaterController
    private var readinessObservation: NSKeyValueObservation?

    private(set) var canCheckForUpdates = false

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
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
