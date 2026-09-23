import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let updates = UpdateController()
    let outputDevices = OutputDeviceInventory()
    let priorityOrder = PriorityOrderStore()

    private lazy var outputSwitching = OutputSwitchingCoordinator(
        outputDevices: outputDevices,
        priorityOrder: priorityOrder
    )
    private lazy var soundDevicesWindow = SoundDevicesWindowPresenter(
        outputDevices: outputDevices,
        priorityOrder: priorityOrder
    )
    private lazy var menuBar = MenuBarPresenter(
        outputDevices: outputDevices,
        priorityOrder: priorityOrder,
        updates: updates,
        showSoundDevices: { [soundDevicesWindow] in soundDevicesWindow.show() }
    )

    func applicationDidFinishLaunching(_: Notification) {
        MainMenu.install(appName: "Locus Sound Control")
        // Before the updater starts, since accepting the move relaunches from the new location.
        ApplicationsFolderMoveWorkflow().offerIfNeeded()
        updates.start()
        outputDevices.start()
        outputSwitching.start()
        menuBar.start()
    }
}
