## 2026.0.4

Locus Sound Control now switches your sound output. Give your devices a priority order, and it plays through the highest one that’s connected.

### Added
- Drag devices up and down in the Sound Devices window to set their priority. When a device higher in the list connects, sound moves to it. When it disconnects, sound falls back to the next one down.
- On first launch, the list starts with whatever is connected, with the device you’re already listening to at the top, so nothing switches until you change the order.
- Devices are remembered after they disconnect. They stay in their place in the list, dimmed and marked Not Connected.
- A device connected for the first time goes to the bottom of the list, so it doesn’t take over your sound until you move it up.
- If nothing in the list is connected, Locus Sound Control leaves the output alone.
- Alert sounds follow the output, so they don’t keep playing through a device you’ve moved away from. On Bluetooth, macOS decides when alerts move to your headphones, since moving them early can make shared AirPods drop back to the speakers.
- While the Sound Devices window is open, Locus Sound Control has a Dock icon and appears in the `⌘Tab` switcher, so the window is easy to get back to. Clicking the Dock icon brings the window forward.

### Changed
- The menu lists devices in priority order.
- The Sound Devices window explains the priority order at the top. It mentions overrides, which arrive in a later release; until then, clicking a device in the menu or double-clicking one in the window does nothing.
- The Sound Devices window can no longer grow wider than is useful.
- Devices that report they can’t be used as the sound output, such as Microsoft Teams’ internal audio device, are no longer listed.
- The menu bar icon changes straight to a remembered device’s icon when it connects, instead of briefly showing a generic speaker.
