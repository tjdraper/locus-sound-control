import Sparkle
import SwiftUI

/// Keeps an update found by a scheduled check out of the user's way. Instead of Sparkle's window
/// jumping to the front, the update waits behind a quiet item in the menu until the user asks to
/// see it. https://sparkle-project.org/documentation/gentle-reminders
/// An update the user saw and put off keeps the sign up too, so it isn't forgotten.
///
/// Without a Dock icon there is nothing to bring the app forward, so Sparkle's windows would
/// otherwise open behind whatever the user is working in.
@Observable
final class UpdateReminder: NSObject, SPUStandardUserDriverDelegate {
    var waitingVersion: String? {
        scheduledVersion ?? dismissedVersion
    }

    /// Found by a scheduled check, and held by Sparkle until the user looks at it.
    private var scheduledVersion: String?
    /// Seen and put off. Sparkle ends its session and forgets the update, so clicking the sign
    /// starts a new check, which shows the window again.
    private var dismissedVersion: String?

    /// Called by the updater's delegate, just before Sparkle ends the session.
    func userDidMake(_ choice: SPUUserUpdateChoice, forVersion version: String) {
        dismissedVersion = choice == .dismiss ? version : nil
    }

    /// The check finds the update again if it's still there.
    func userWillCheckForUpdates() {
        dismissedVersion = nil
    }

    nonisolated var supportsGentleScheduledUpdateReminders: Bool {
        true
    }

    /// Sparkle proposes showing the update right away shortly after launch, but for an app that
    /// opens at login that's an arbitrary moment too, so the sign handles every scheduled update.
    nonisolated func standardUserDriverShouldHandleShowingScheduledUpdate(
        _: SUAppcastItem,
        andInImmediateFocus _: Bool
    ) -> Bool {
        false
    }

    nonisolated func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state _: SPUUserUpdateState
    ) {
        let version = update.displayVersionString
        onMain {
            if handleShowingUpdate {
                AppActivation.bringToFront()
            } else {
                scheduledVersion = version
            }
        }
    }

    nonisolated func standardUserDriverDidReceiveUserAttention(forUpdate _: SUAppcastItem) {
        onMain {
            scheduledVersion = nil
        }
    }

    nonisolated func standardUserDriverWillFinishUpdateSession() {
        onMain {
            scheduledVersion = nil
        }
    }

    nonisolated func standardUserDriverWillShowModalAlert() {
        onMain {
            AppActivation.bringToFront()
        }
    }

    // Sparkle calls its user driver delegate on the main thread.
    private nonisolated func onMain(_ body: @MainActor () -> Void) {
        MainActor.assumeIsolated(body)
    }
}
