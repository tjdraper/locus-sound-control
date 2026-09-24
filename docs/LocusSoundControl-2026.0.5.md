## 2026.0.5

Overrides arrive. Choose a device and Locus Sound Control keeps your sound there, whatever the priority order says, until you cancel it or the device disconnects.

### Added
- Click a device in the menu, or double-click a connected one in the Sound Devices window, to override the priority order and play through it.
- Changing the output anywhere else — Control Center, System Settings, another app — counts as an override too, so Locus Sound Control goes along with your choice instead of switching back.
- While an override is active, a device connecting doesn’t take your sound away from it. AirPods reconnecting on their own no longer interrupt what you chose to listen to.
- A device connected for the very first time plays when macOS switches to it, instead of being moved straight back to whatever sits above it in the list.
- Cancel an override with the Cancel Override button at the top of the menu or at the bottom of the Sound Devices window, or by choosing the same device again. Choosing it again also works from the keyboard.
- When an override is active, the menu bar icon is surrounded by the system settings accent color so you can tell without opening the menu.
- The overridden device is tagged Override in the Sound Devices window.
- An override survives quitting and relaunching. It ends when its device disconnects, and doesn’t come back when the device reconnects.

### Changed
- When a device connects or disconnects, macOS sometimes moves the output on its own. Locus Sound Control recognizes that as macOS’s choice rather than yours, and puts the output back where the priority order or your override says it belongs.
- The priority order explanation stays at the top of the Sound Devices window while the list scrolls under it.
- Clicking a device in the Sound Devices window selects it.
