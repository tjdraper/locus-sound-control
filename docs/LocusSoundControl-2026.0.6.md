## 2026.0.6

New devices wait for you to place them, you can hide the devices you never want and give each one its own icon, and your priority order syncs between your Macs.

### Added
- Your priority order syncs through iCloud to every Mac signed in to the same account. So do the devices you hide, the icons you assign, the devices waiting to be placed, and the devices you forget. Overrides stay on the Mac where you set them.
- On a Mac that has just been set up, the order synced from your other Macs replaces the one guessed from whatever was plugged in.
- If two of your Macs already have their own orders, the first Mac to update decides the order. Devices only the other Mac knows are added at the bottom, so update the Mac whose order you want to keep first.
- A device connected for the first time goes to a New Devices list at the top of the Sound Devices window instead of into the priority order, and the menu bar icon gets a red badge until you deal with it. It’s never chosen automatically while it waits there, but it still plays when macOS switches to it as it connects.
- Drag a new device into the priority order to place it, or choose Add to Priority Order to put it at the bottom. The “Sound Devices…” menu item shows how many are waiting.
- Hide a device so it’s never chosen automatically and drops out of the Menu Bar menu. Hidden devices get their own list in the Sound Devices window, keep their place in the order, and go back to it when unhidden. A hidden device can still be chosen by double-clicking it or from Control Center.
- Forget a disconnected device to delete it from the list. If it connects again, it arrives as a new device.
- Give a device its own icon with “Change Icon…”, from a set of symbols chosen to read clearly in the menu bar. Choose Automatic to go back to the one Locus Sound Control picks. The icon shows in the menu bar, the menu and the Sound Devices window.
- Merge two or more entries that are really the same device, and split a merged entry back into separate devices. Each entry lists every identifier it covers.
- These commands are in the new File menu and the right-click menu on the list. All but Merge are also buttons on each row.

### Changed
- A USB device such as a dock or display is recognized when it moves to a different port, instead of arriving as a new device each time. Two devices of the same model connected at once are still kept apart.
- Hiding the device you’ve overridden to cancels the override.
- The menu keeps showing a hidden device while it’s the one playing, so it always says where your sound is going.
- The priority order explanation sits with the priority order, below the New Devices list.
- Screen sharing’s audio device never appears as a new device, since it changes identity every session.
