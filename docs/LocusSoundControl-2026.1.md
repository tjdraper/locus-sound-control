## 2026.1

The first full release of Locus Sound Control. Put your sound devices in order once, and your Mac plays through the highest priority ordered device that’s connected, switching for you as you plug in, unplug, dock, or pair.

### Why I made it

If, like me, your Mac is always docking and undocking, connecting to different sound devices and scenarios, you’ve probably experienced macOS’s forgetfulness about which sound device (or devices) should be used, and in which order.

I built Locus Sound Control to solve this problem. Set up the priority order of your devices, and it will use the highest priority output available.

And, from the menu bar, you can always override to the device of your choosing, and cancel the override when you’re done.

— TJ

### Changed
- If you ran the betas, Locus Launcher asks whether you want to keep getting betas now that you’re on a full release.

### Added
- A menu bar icon that shows what you’re listening through, and changes as your sound moves between speakers, headphones, a dock, or a display. AirPods, Powerbeats, and most Beats models get their own icon. Anything else is recognized by how it’s connected: Bluetooth headphones, a Bluetooth speaker, car audio, a display, or the Mac’s own speakers.
- Click the menu bar icon to see your sound devices in priority order, with the one playing checked.
- Drag devices up and down in the Sound Devices window to set their priority. When a device higher in the list connects, sound moves to it. When it disconnects, sound falls back to the next one down.
- On first launch, the list starts with whatever is connected, with the device you’re already listening to at the top, so nothing switches until you change the order.
- Devices are remembered after they disconnect. They keep their place in the list, dimmed and marked Not Connected.
- When a device connects or disconnects, macOS sometimes moves your sound on its own. Locus Sound Control puts it back where your priority order says it belongs.
- After waking from sleep or docking, Locus Sound Control waits for your devices to settle instead of reacting to every step.
- Alert sounds follow your sound output, so they don’t keep playing through a device you’ve moved away from.
- Overrides: click a device in the menu, or double-click one in the Sound Devices window, to override the priority order and play through it instead. Changing the output from Control Center, System Settings, or another app counts as an override too, so Locus Sound Control goes along with your choice instead of switching back.
- While an override is active, a device connecting doesn’t take your sound away. AirPods reconnecting on their own won’t interrupt what you chose to listen to. The menu bar icon is ringed in your accent color so you can tell at a glance.
- An override lasts until you cancel it, with “Cancel Override” or by choosing the same device again, or until its device disconnects. It survives quitting and relaunching.
- A device connected for the first time waits in a New Devices list instead of joining the priority order, and the menu bar icon shows a red badge until you decide what you want to do with it. Drag it into the order, or choose “Add to Priority Order” to put it at the bottom. It’s never chosen automatically while it waits.
- Hide a device you never want chosen automatically. Hidden devices drop out of the menu, and go back to their place in the order when unhidden.
- Forget a disconnected device to remove it from the list.
- Merge entries that are really the same device, and split them apart again—because sometimes devices don't offer a good way to be identified and the Mac thinks they're different devices when plugged into a different port.
- The priority order, hidden devices, custom icons, and new devices sync through iCloud to every Mac signed in to the same account. A newly set up Mac picks up the order from your other Macs. Overrides stay on the Mac where you set them.
- A setup checklist on first launch. It offers to move the app to your Applications folder, shows the priority order it guessed from what’s plugged in, and covers opening at login, Bluetooth access, and update checks. Reopen it any time with “Setup Checklist…” in the menu.
- Settings to open Locus Sound Control at login, allow Bluetooth access, turn iCloud sync on or off, and choose whether to check for updates automatically and whether to get betas.
- Automatic updates. When an update is ready, the menu bar icon shows a red badge and the menu shows “Install Update…”, instead of a window interrupting you. “Check for Updates…” checks right away.
- While the Sound Devices window is open, Locus Sound Control appears in the Dock and the `⌘Tab` switcher, so the window is easy to get back to.
- Bluetooth access is only used to tell headphones from speakers, so the icon is right. Locus Sound Control never scans for or connects to devices, and saying no only means Bluetooth devices show a headphones icon.
