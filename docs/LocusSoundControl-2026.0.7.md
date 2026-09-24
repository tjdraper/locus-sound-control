## 2026.0.7

A Settings window, a setup checklist for new installs, and quieter update notices.

### Added
- Settings: Open Locus Sound Control at login, check or allow Bluetooth access, turn iCloud sync on or off, and choose whether to check for updates automatically and whether to get betas.
- A setup checklist on first launch. It offers to move the app to your Applications folder, shows the top of the priority order it guessed from what’s plugged in, and covers opening at login, Bluetooth access and update checks. Every step shows its real current state, so a change made in System Settings shows up there too.
- “Setup Checklist…” in the menu opens the checklist again. Existing installs skip it on update, so this is the way to see it.
- A “View” menu with “Show Debug Info”, which shows the identifiers each device is matched on in the “Sound Devices” window.

### Changed
- An update found by a scheduled check no longer brings a window to the front. The menu shows “Install Update…” with the version instead, and the window opens when you choose it.
- The Sound Devices window shows how each device is connected, such as USB, Bluetooth or Built-in, and says when an entry is merged from several devices. The identifiers each entry covers are hidden unless Show Debug Info is on.
- With an override active, the menu bar icon draws the device’s symbol the same way as without one. Displays and laptops no longer show a filled-in screen.
