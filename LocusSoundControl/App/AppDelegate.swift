import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let updates = UpdateController()
    let outputDevices = OutputDeviceInventory()
    let priorityOrder = PriorityOrderStore()
    let override = OverrideStore()
    let dockIcon = DockIconPresence()

    private lazy var outputSwitching = OutputSwitchingCoordinator(
        outputDevices: outputDevices,
        priorityOrder: priorityOrder,
        override: override
    )
    private lazy var iCloudSync = ICloudSyncCoordinator(priorityOrder: priorityOrder)
    private lazy var soundDevicesWindow = SoundDevicesWindowPresenter(
        outputDevices: outputDevices,
        priorityOrder: priorityOrder,
        override: override,
        dockIcon: dockIcon
    )
    private lazy var menuBar = MenuBarPresenter(
        outputDevices: outputDevices,
        priorityOrder: priorityOrder,
        override: override,
        updates: updates,
        showSoundDevices: { [soundDevicesWindow] in soundDevicesWindow.show() }
    )

    func applicationDidFinishLaunching(_: Notification) {
        MainMenu.install(appName: "Locus Sound Control", fileMenu: soundDevicesWindow.fileMenu)
        // Before the updater starts, since accepting the move relaunches from the new location.
        ApplicationsFolderMoveWorkflow().offerIfNeeded()
        updates.start()
        outputDevices.start()
        outputSwitching.start()
        iCloudSync.start()
        menuBar.start()
    }

    /// Clicking the Dock icon, or opening the app again from Finder while it runs, is a request
    /// to see the window, whether it is minimized, buried behind other apps or closed.
    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        soundDevicesWindow.show()
        return false
    }
}
