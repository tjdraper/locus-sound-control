import AppKit

/// The standard key equivalents. An accessory app never displays a menu bar of its own, but
/// AppKit still routes ⌘C, ⌘W and the rest through the main menu, so a window without one cannot
/// copy or close. SwiftUI's `App` built this; the menu bar item is AppKit, so this is built here.
enum MainMenu {
    /// - Parameter fileMenu: fills the File menu each time it opens. Not retained.
    static func install(appName: String, fileMenu: NSMenuDelegate) {
        let main = NSMenu()
        main.addItem(submenu(named: appName, items: [
            NSMenuItem(
                title: "About \(appName)",
                action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                keyEquivalent: ""
            ),
            .separator(),
            NSMenuItem(title: "Hide \(appName)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"),
            .separator(),
            NSMenuItem(title: "Quit \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"),
        ]))

        let file = submenu(named: "File", items: [])
        file.submenu?.delegate = fileMenu
        file.submenu?.autoenablesItems = false
        main.addItem(file)

        main.addItem(submenu(named: "Edit", items: [
            NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"),
            NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z"),
            .separator(),
            NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"),
            NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"),
            NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"),
            NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"),
        ]))

        let windowMenu = submenu(named: "Window", items: [
            NSMenuItem(title: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m"),
            NSMenuItem(title: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"),
        ])
        main.addItem(windowMenu)

        NSApp.mainMenu = main
        NSApp.windowsMenu = windowMenu.submenu
    }

    private static func submenu(named name: String, items: [NSMenuItem]) -> NSMenuItem {
        let parent = NSMenuItem()
        let menu = NSMenu(title: name)
        for item in items { menu.addItem(item) }
        parent.submenu = menu
        return parent
    }
}
