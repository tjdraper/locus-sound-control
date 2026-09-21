import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let updates = UpdateController()
    let outputDevices = OutputDeviceInventory()

    private lazy var soundDevicesWindow = SoundDevicesWindowPresenter(outputDevices: outputDevices)
    private lazy var menuBar = MenuBarPresenter(
        outputDevices: outputDevices,
        updates: updates,
        showSoundDevices: { [soundDevicesWindow] in soundDevicesWindow.show() }
    )

    func applicationDidFinishLaunching(_: Notification) {
        MainMenu.install(appName: "Locus Sound Control")
        // Before the updater starts, since accepting the move relaunches from the new location.
        ApplicationsFolderMoveWorkflow().offerIfNeeded()
        updates.start()
        outputDevices.start()
        menuBar.start()
    }
}
