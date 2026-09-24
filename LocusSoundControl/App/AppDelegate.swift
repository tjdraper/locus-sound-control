import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let updates = UpdateController()
    let outputDevices = OutputDeviceInventory()
    let priorityOrder = PriorityOrderStore()
    let override = OverrideStore()
    let dockIcon = DockIconPresence()
    let launchAtLogin = LaunchAtLoginStore()

    private lazy var outputSwitching = OutputSwitchingCoordinator(
        outputDevices: outputDevices,
        priorityOrder: priorityOrder,
        override: override
    )
    private lazy var iCloudSync = ICloudSyncCoordinator(priorityOrder: priorityOrder)
    private lazy var bluetoothAccess = BluetoothAccessStore { [outputDevices] in
        outputDevices.rereadDevices()
    }
    private lazy var settingsWindow = SettingsWindowPresenter(
        updates: updates,
        launchAtLogin: launchAtLogin,
        bluetoothAccess: bluetoothAccess,
        iCloudSync: iCloudSync,
        dockIcon: dockIcon
    )
    private lazy var soundDevicesWindow = SoundDevicesWindowPresenter(
        outputDevices: outputDevices,
        priorityOrder: priorityOrder,
        override: override,
        bluetoothAccess: bluetoothAccess,
        dockIcon: dockIcon
    )
    private lazy var firstRunWindow = FirstRunWindowPresenter(
        updates: updates,
        launchAtLogin: launchAtLogin,
        bluetoothAccess: bluetoothAccess,
        priorityOrder: priorityOrder,
        dockIcon: dockIcon,
        showSoundDevices: { [soundDevicesWindow] in soundDevicesWindow.show() }
    )
    private lazy var menuBar = MenuBarPresenter(
        outputDevices: outputDevices,
        priorityOrder: priorityOrder,
        override: override,
        updates: updates,
        showSoundDevices: { [soundDevicesWindow] in soundDevicesWindow.show() },
        showSettings: { [settingsWindow] in settingsWindow.show() },
        showSetupChecklist: { [firstRunWindow] in firstRunWindow.show() }
    )

    func applicationDidFinishLaunching(_: Notification) {
        MainMenu.install(
            appName: "Locus Sound Control",
            fileMenu: soundDevicesWindow.fileMenu,
            viewItems: [soundDevicesWindow.debugInfo.makeMenuItem()]
        )
        // Settled before Sparkle starts, which marks every install as launched before.
        let isFirstRun = FirstRunStatus().settleAtLaunch() == .pending
        // Before the updater starts, since accepting the move relaunches from the new location.
        // On a first run the setup checklist makes the offer instead.
        if !isFirstRun {
            ApplicationsFolderMoveWorkflow().offerIfNeeded()
        }
        // Answered before Sparkle's first check, which would otherwise still look for betas.
        BetaTrackExitWorkflow().offerIfNeeded()
        updates.start()
        outputDevices.start()
        outputSwitching.start()
        iCloudSync.start()
        menuBar.start()
        if isFirstRun {
            firstRunWindow.show()
        }
    }

    /// Clicking the Dock icon, or opening the app again from Finder while it runs, is a request
    /// to see the window, whether it is minimized, buried behind other apps or closed.
    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        soundDevicesWindow.show()
        return false
    }

    /// Reached through the responder chain from the main menu's Settings item.
    @objc func showSettings(_: Any?) {
        settingsWindow.show()
    }
}
