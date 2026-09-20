import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let updates = UpdateController()

    func applicationDidFinishLaunching(_: Notification) {
        // Before the updater starts, since accepting the move relaunches from the new location.
        ApplicationsFolderMoveWorkflow().offerIfNeeded()
        updates.start()
    }
}
