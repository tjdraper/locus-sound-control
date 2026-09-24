import Sparkle
import SwiftUI

/// Owns the Sparkle updater and mirrors its readiness so the menu item can disable itself
/// while a check is already running.
@Observable
final class UpdateController {
    private let updaterDelegate: UpdaterDelegate
    private let reminder: UpdateReminder
    private let updaterController: SPUStandardUpdaterController
    private var readinessObservation: NSKeyValueObservation?

    private(set) var canCheckForUpdates = false

    /// The version of an update a scheduled check found, until the user looks at it or it's dismissed.
    var waitingUpdateVersion: String? {
        reminder.waitingVersion
    }

    var automaticallyChecksForUpdates: Bool {
        get {
            access(keyPath: \.automaticallyChecksForUpdates)
            return updaterController.updater.automaticallyChecksForUpdates
        }
        set {
            withMutation(keyPath: \.automaticallyChecksForUpdates) {
                updaterController.updater.automaticallyChecksForUpdates = newValue
            }
        }
    }

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
        let reminder = UpdateReminder()
        let updaterDelegate = UpdaterDelegate(reminder: reminder)
        self.reminder = reminder
        self.updaterDelegate = updaterDelegate
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: updaterDelegate,
            userDriverDelegate: reminder
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

    /// Turns automatic checks on unless the user already chose, which is what Sparkle's own prompt
    /// suggests. Once a choice is stored, Sparkle never shows that prompt.
    func defaultToAutomaticChecks() {
        guard UserDefaults.standard.object(forKey: "SUEnableAutomaticChecks") == nil else { return }
        automaticallyChecksForUpdates = true
    }

    /// Also brings a waiting update's window forward. Sparkle doesn't announce that, so the app
    /// comes to the front first.
    func checkForUpdates() {
        reminder.userWillCheckForUpdates()
        AppActivation.bringToFront()
        updaterController.checkForUpdates(nil)
    }
}

private final class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    private let reminder: UpdateReminder

    init(reminder: UpdateReminder) {
        self.reminder = reminder
    }

    /// Beta items in the appcast are only offered to updaters that name the channel here.
    /// Everyone else sees the default channel alone.
    nonisolated func allowedChannels(for _: SPUUpdater) -> Set<String> {
        UpdateChannelPreference().allowedChannels
    }

    /// Sparkle asks on the second launch, which for an app that opens at login is an arbitrary
    /// moment, so the setup checklist asks instead. Installs from before the checklist never see
    /// it, so Sparkle still asks them.
    nonisolated func updaterShouldPromptForPermissionToCheck(forUpdates _: SPUUpdater) -> Bool {
        FirstRunStatus().state == .existingInstall
    }

    nonisolated func updater(
        _: SPUUpdater,
        userDidMake choice: SPUUserUpdateChoice,
        forUpdate updateItem: SUAppcastItem,
        state _: SPUUserUpdateState
    ) {
        let version = updateItem.displayVersionString
        // Sparkle calls its delegates on the main thread.
        MainActor.assumeIsolated {
            reminder.userDidMake(choice, forVersion: version)
        }
    }
}
