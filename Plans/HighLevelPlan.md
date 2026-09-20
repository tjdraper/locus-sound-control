# Locus Sound Control: High-Level Plan

A menu bar app that keeps the Mac's sound output on the device you actually want, ranked by a priority order you set, with no notifications and no popups. See [`stream-of-conciousness-about-this-app.md`](stream-of-conciousness-about-this-app.md) for the original motivation.

## Slices

1. **Scaffold and release pipeline**

   One slice, because a signed and updatable hello world is the smallest thing worth having. Gatekeeper, notarization and Sparkle problems are much cheaper to find before there is code to debug.

   - Xcode project, macOS 26 target, Swift 6 with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
   - SwiftLint before any feature code, running on every build with zero violations. Build tool plugin from `SimplyDanny/SwiftLintPlugins`; copy `.swiftlint.yml` from locus-launcher and repoint its `included` paths.
   - Menu bar only, no Dock icon (`LSUIElement`). A placeholder SF Symbol and a menu with Quit.
   - A "Sound Devices" window with nothing in it yet, opened from the menu
   - Developer ID signing and hardened runtime from day one. No App Sandbox (see Decisions).
   - `Scripts/release.sh`, ported from locus-launcher: archive, export a Developer ID build, notarize, staple, re-zip with `ditto -c -k --keepParent`, append to the appcast, then stop and print the `gh release create` and `git` commands. It never publishes on its own. Version shape picks the channel: `YYYY.N` is a release, `YYYY.N.B` is a beta. Release notes at `docs/LocusSoundControl-<version>.md` are required.
   - `Scripts/install-test-build.sh`, also ported: notarizes and staples the working tree as it is, without bumping the version or touching the appcast, quits the copy in `/Applications`, trashes it, installs the new build in its place and opens it. It matches the running copy by path so a Debug build from Xcode is left alone. This is how anything that only behaves correctly in a real installed, signed app gets tested — launch at login, the Sparkle update flow, Gatekeeper, and the move-to-Applications prompt. Locus Launcher needed it for Accessibility access; this app needs no permissions, but the other reasons still apply.
   - `Scripts/ExportOptions.plist` and `Scripts/sparkle-tools.sh` port across too, and `Scripts/README.md` gets rewritten for this app. Change the app name, bundle identifier, artifact name, GitHub repo, feed URL and notary profile (`LocusSoundControl`).
   - A Developer ID provisioning profile is needed, for the same reason locus-launcher needs one: slice 7 syncs through iCloud key-value storage, which is an entitlement a Developer ID build can only carry with a profile. `xcodebuild` on the command line cannot create one when it has no access to the Xcode account, so let Xcode create it once — Product → Archive, then Distribute App → Direct Distribution — and the export in `release.sh` finds it afterwards. Do this in slice 1 even though nothing uses the entitlement yet, so the release chain is proven in its final shape.
   - Sparkle, with a new signing key for this app and the feed at `https://tjdraper.github.io/locus-sound-control/appcast.xml`
   - On first launch outside `/Applications`, offer to move there. macOS runs apps opened from Downloads out of a hidden read-only location, which breaks Sparkle and launch at login.
   - MIT `LICENSE`, `.gitignore`, and a `Plans/ReleaseSetupChecklist.md` for the credentials and hosting steps only an account holder can do
   - Ship `2026.0.1`, then a throwaway `2026.0.2`, and let the installed `2026.0.1` update itself. Sparkle problems only show up on the second release.
   - Verify the download on a Mac that has never run the app: unzip in Downloads and open it. No Gatekeeper warning, and the offer to move to Applications.

2. **Device inventory and menu bar icon**

   Read-only. Nothing is switched yet, which keeps the CoreAudio observation work separate from the decision-making work.

   - Read the output device list from CoreAudio: UID, name, transport type. A device counts as an output when it has at least one buffer on the output scope.
   - Live updates when devices appear and disappear, and when the default output changes by any means
   - Debounce the churn. Connecting or disconnecting a device produces several notifications, and a Bluetooth device can be listed for a moment before it is usable.
   - Waking from sleep and logging in are the same problem at a larger scale: devices re-enumerate over several seconds, displays before Bluetooth. Wait for the device list to stay unchanged for a moment before treating it as settled, so slice 3 resolves once against the finished list instead of switching through every intermediate state. Get this right here, in the read-only slice, where a mistake is visible in a log rather than audible.
   - The menu bar icon shows the current output's kind, derived from transport type (see Decisions)
   - Clicking the icon lists the output devices and marks the current one. System order for now; slice 3 gives it a real order.
   - The Sound Devices window lists what was found, so there is something to look at while getting the CoreAudio layer right

3. **Priority list and the switching engine**

   - Sound Devices window: drag devices up and down to set priority
   - `OutputResolver`, a pure value type: given the priority order, the hidden set, the connected devices and the active override, it returns the device that should be selected. No CoreAudio inside it, so it goes in the test target (see Tests in `AGENTS.md`).
   - Re-resolve when the device list changes, when the priority order is edited, or when an override changes
   - Write both the default output and the system alert output, keeping them matched
   - When no listed device is connected, leave the system alone rather than forcing something
   - First launch seeds the priority list from the connected devices, current output first, and marks them all as seen
   - Storage: an ordered list of device entries in `UserDefaults`, each holding a set of UIDs rather than one (see Decisions). Slice 6 adds the matching that puts several UIDs in an entry and the UI to correct it; this slice only has to store the shape, so nothing needs migrating later.
   - The menu now lists devices in priority order

4. **Overrides**

   - Clicking a device in the menu sets an override, which wins over priority until it is canceled
   - Cancel from the same menu
   - A change made outside the app — Control Center, System Settings, another app — is adopted as an override (see Decisions). Changing output anywhere works, and the app never fights you.
   - Suppress adoption during the churn window after a device list change, so macOS's own fallback when a device disappears is not mistaken for a deliberate choice
   - The override survives quit and restart
   - When the overridden device disappears, the override is cleared and priority takes over. It does not come back when the device reconnects.

5. **Hidden and forgotten devices**

   - Hide a device: it stops being eligible for automatic selection and drops out of the menu. Virtual devices from other apps are the main reason this exists.
   - Hidden devices stay in the Sound Devices window in their own area, and can be unhidden
   - Forget a device that is not currently connected: its record is deleted. If it ever reconnects it arrives as a new device again.
   - Forget is only offered for disconnected devices, since forgetting a connected one would immediately re-add it

6. **New device queue and badge**

   - A device the app has never seen goes into a queue instead of the priority list, and the menu bar icon gets a badge
   - The Sound Devices window shows the queue at the top, and dragging a device out of it into the priority list clears it
   - A new device is not eligible for automatic selection while it sits in the queue. Plugging something in should not silently hijack audio.
   - macOS usually switches to a newly connected device on its own. Slice 4 adopts that as an override, so the new device does play, the badge says it needs sorting, and nothing is lost if it is never sorted.
   - The badge is drawn into the menu bar image, the same approach as locus-launcher's `MenuBarIcon`
   - Screen sharing and AirPlay taps get a new UID per session (see Decisions). They never enter the queue and never badge, or the icon would light up after every screen share.
   - The Sound Devices window can **merge** two entries into one — these are the same device — and **split** a merged entry back apart. Both directions are needed: the automatic match cannot tell two units of the same model apart (see Decisions), and a device with no model identifier has nothing else to fall back on. A merged entry shows which identities it covers, so what the app decided is visible rather than guessed at.
   - **This slice needs the model-level match from slice 7, on a single Mac, with no sync involved.** A USB audio UID ends in either a serial number or a USB location ID, and a location ID changes with the port. CoreAudio's own records show the CalDigit dock on this Mac under eight location IDs, one per Thunderbolt port it has ever been in. Keyed on UID alone the dock would badge as a new device every time it moved sides, and would carry a separate priority entry for each port. Build the match here and let slice 7 reuse it, rather than the other way round.

7. **iCloud sync**

   Two Macs that move between the same docks, displays and headphones should not have to be taught the same order twice.

   - The priority order, the hidden flag, and whether a device has been sorted all sync through iCloud key-value storage
   - Forgetting a device syncs too. If the other Mac is offline and has that device connected, it comes back there as a new device, which is self-correcting rather than wrong.
   - The active override never syncs. It is about what you are doing on that Mac right now.
   - Device equivalence is handled by slice 6's matching and merging. This slice syncs the result, so a merge made on one Mac holds on the other.
   - A single on/off for sync in Settings. Per-device sync choices would be more machinery than this earns.
   - On a second Mac's first run, an incoming synced order replaces the local seed rather than merging with it. The seed is a guess made from whatever happened to be plugged in; the synced order is something the user actually arranged.
   - A synced order naturally contains devices this Mac has never seen. The priority list already holds disconnected devices, so they list normally and simply never win.

8. **Settings**

   - A Settings window separate from Sound Devices (see Decisions)
   - Launch at login (`SMAppService`)
   - Sync on/off (slice 7), with a line naming what it carries and what it does not
   - Beta updates toggle, bound to Sparkle's `ReceiveBetaUpdates` default, with a line saying betas ship more often and may break
   - Sparkle gentle reminders (https://sparkle-project.org/documentation/gentle-reminders). By default a scheduled check that finds an update throws Sparkle's window to the front at an arbitrary moment, which is exactly the interruption this app exists to avoid. Show a quiet sign instead and open the window when it is clicked. Sparkle logs a warning at launch until this is done.
   - Whether the update sign can live only in the menu bar icon depends on slice 10's decision about hiding the icon

9. **First-run wizard**

   - A one-page setup checklist on first launch, reopenable from the menu
   - Only fresh installs see it. Earlier installs are recognized by Sparkle's launched-before flag and skip it.
   - Move to `/Applications` if needed
   - Confirm the seeded priority order, since the seed is a guess
   - Launch at login
   - Ask about automatic update checks here. Sparkle otherwise raises its own prompt on the second launch, which for a login-item menu bar app lands at a random moment. Take it over with `SPUUpdaterDelegate.updaterShouldPromptForPermissionToCheckForUpdates`.
   - Each step reflects real current state, so a change made in System Settings updates the wizard

10. **Polish and first release**

   - App icon and a custom menu bar icon set, replacing the SF Symbols. Each has to keep working with the badge drawn over it.
   - Website download page, v1
   - Windows open centered on the primary display the first time and then remember where they were put. `NSWindow.center()` runs before SwiftUI has sized the window, so it lands off center; locus-launcher has the workaround.
   - Decide whether the menu bar icon can be hidden. macOS's own "Allow in the Menu Bar" covers hiding it, but this app's only affordance for setting an override is that menu, so hiding it removes a feature rather than just an indicator.
   - Remove the setup checklist row from Settings if it was added there. The menu still opens it.

## Decisions

- **Outside changes become overrides.** Setting the default output fires the same notification whether the app or something else did it, so the app compares the new device against what it last wrote. A match is its own write. A mismatch is someone else, and becomes an override. This is compared by resulting device rather than by tracking individual writes, so it cannot get out of step. The exception is the window right after a device list change, when macOS picks its own fallback; adoption is suppressed there.

- **A connecting device takes over unless you chose the current one.** A higher-priority device arriving switches output immediately, even mid-playback — that is what a priority order means. The exception is an active override, which holds until it is cancelled or its device disappears. So the override is not just a way to depart from the order for a moment; it is how the user says "I am deliberately listening here, leave it alone." Since a change made in Control Center is adopted as an override too, that statement can be made from outside the app as well as inside it. This is the answer to the original complaint: AirPods reconnecting take over when nothing was chosen, and do not when something was.

- **Overrides do not re-arm.** When the overridden device disappears the override is cleared for good. Reconnecting it goes through the normal path, which means macOS's own switch to it is adopted as a fresh override anyway if macOS makes one.

- **Both output properties are written.** macOS tracks the default output and the system alert output separately and they drift apart, which is a common surprise. The app keeps them matched. Not every device can be the system alert output, so a failure there is ignored rather than retried.

- **A priority entry is a set of identities, not a UID.** This started out as "identity is the UID" and the measurements killed it: one dock holds eight UIDs on one Mac, and a device that never moved is re-identified when its neighbour does. So the stored unit is an entry — a display name, a model identifier, a transport, and the set of UIDs known to belong to it — and a live device is resolved to an entry rather than looked up by key. The set grows as new UIDs for a known device turn up. This shape has to be in place from slice 3, because retrofitting it in slice 6 means migrating everything already stored.

- **Storage is `UserDefaults`.** An ordered array of device records plus the active override UID. It is a small ordered list read at launch and written on edit; SwiftData would be overhead with no benefit.

- **Sync, and matching devices across Macs.** Two Macs sharing docks and displays should share one order. The hard part is deciding when a device on one Mac is the same device on the other, resolved in three steps:

  1. **The UID, when it travels.** Some UIDs are already identical across machines. The built-in speakers report `BuiltInSpeakerDevice` with no machine identity in the string, so internal speakers match for free. Bluetooth UIDs are built from the device's MAC address, so a pair of AirPods matches itself. Vendor virtual devices hardcode theirs; Teams reports `MSLoopbackDriverDevice_UID` on every Mac.
  2. **The model, when the UID does not travel.** USB audio UIDs take the shape `AppleUSBAudioEngine:<maker>:<product>:<serial or location>:<interface>`, and which of those two things lands in the fourth slot decides everything. The Studio Display puts its serial there and travels. The CalDigit dock puts `22200000` there, which has the shape of a USB location ID — a port address — and so does not. When a synced record matches no local UID, fall back to `kAudioDevicePropertyModelUID` plus transport type. It is a model-level identifier rather than an instance one, and the dock's `CalDigit Thunderbolt 3 Audio:2188:6533` is stable where its UID is not. Require the model to match rather than the name: "USB Audio Device" is a real name several unrelated docks use. Only auto-match a synced record that found no UID match anywhere, so a device sitting there under its own UID is never stolen.
  3. **By hand, in both directions.** The Sound Devices window can merge two entries into one and split a merged entry back apart. Merging is the only safety net when a device has neither a travelling UID nor a usable model — the Dell reports no `modelUID` at all. Splitting is what undoes a wrong automatic match. Both are once-per-device actions.

  Step 2 carries one guard: two devices connected at the same moment cannot be the same device, so never match across a pair that is simultaneously present. That covers the live case cheaply and correctly.

  The failure mode of an over-eager model match is merging two different units of the same model, which lands them at the same priority — mild, and usually what was wanted. Bluetooth is where it would bite, since two pairs of the same AirPods model share `2014 4c`, but Bluetooth UIDs are MAC addresses and always match, so the fallback never fires there.

- **The devices were dumped, and step 2 is load-bearing.** `Scripts/dump-audio-devices.swift` was run against a full setup: built-in speakers, CalDigit dock, Dell monitor, Studio Display, AirPods Pro and a Teams virtual device. Five of the six carry UIDs that travel — the built-in speakers by having no machine identity, the Studio Display and the Dell by embedding the panel's own serial or EDID, the AirPods by MAC address, Teams by hardcoding. The dock is the exception, and the dock is the device this feature exists for.

- **A UID is not a device, and three separate things make it drift.** `Scripts/dump-audio-device-history.sh` reads CoreAudio's own record of every device it has ever seen — 121 distinct UIDs on one Mac. Three families account for the churn:

  1. **USB, one identity per port.** The UID's fourth field is a serial number for some devices and a USB location ID for others, and a location ID changes with the port. The CalDigit dock has accumulated eight of them, an Audio-Technica microphone three, an LG UltraFine three.
  2. **Display audio, one identity per connection.** The Dell's EDID-derived id repeats with an `_XXXXXXXX` suffix, five variants for one panel.
  3. **Screen sharing and AirPlay taps, one identity per session.** These carry a session number that is new every time, so they can never be recognised again.

  Family 3 is different in kind: those are not devices anyone wants to prioritise, and queuing them would badge the icon after every screen share. Filter them out rather than trying to match them. Families 1 and 2 are real devices that need several UIDs folded into one entry.

  There is a fourth: CoreAudio's own transient objects, named after the process that caused them — `CADefaultDeviceAggregate-90478-3`, `AudioTap-441263EC-…`. None were in the live output list when this was checked, so they are normally private, but they do arrive and leave. Exclude them with `kAudioDevicePropertyIsHidden` rather than by matching names, which is the supported signal and does not need updating when Apple renames something. Do not exclude by virtual transport: the Teams device is virtual and is a device the user legitimately wants to hide by hand rather than have hidden for them.

- **The cross-Mac comparison came back clean, which relocates the problem.** Running the history script on both Macs and diffing: the Studio Display's two serials, the Dell's id, the AirPods' MAC, `BuiltInSpeakerDevice` and the Teams device are byte-identical on both. Even the dock's eight location IDs are the same eight, because two MacBook Pros of the same model number their Thunderbolt ports the same way. So matching across Macs by UID would in fact work for every device here. The identity work is not really about sync at all — it is about one Mac recognising its own dock across ports, which is why it belongs in slice 6 rather than slice 7.

- **Fold UIDs into one entry by model, not by parsing.** Telling a serial number from a location ID inside a UID string means guessing from its shape, and the Studio Display's `00008150-001262E821C2401C` against the dock's `22200000` is exactly the comparison that makes that guess unreliable. Skip it: match on `kAudioDevicePropertyModelUID` plus transport type instead, which is a model-level identifier CoreAudio hands over directly, and covers display audio as well as USB. The devices with no `modelUID` at all, the Dell among them, fall to the manual merge.

- **The model identifier was verified to hold when the UID moves.** Moving the CalDigit dock from behind the Studio Display to a direct connection changed its UID from `…:22200000:1` to `…:21200000:1` and changed nothing else: `modelUID` stayed `CalDigit Thunderbolt 3 Audio:2188:6533`, as did the name, manufacturer and transport. This is the assumption slice 6 rests on, so it was worth testing before writing code rather than after. Re-test it on a macOS major release, since the UID format is Apple's to change.

- **Two units of one model will be merged, and that is the accepted cost.** A model identifier is vendor and product — `Studio Display Audio Control:05AC:1118` — so it cannot distinguish two Studio Displays, and this setup has two. The simultaneity guard catches them whenever both are plugged in at once. When they are not, the second one adopts the first one's priority entry, and the fix is a split in the Sound Devices window. The alternative, asking before merging, means a prompt at the moment a device is plugged in, which is the interruption this app exists to remove. So merge silently, show the result, and make it reversible. The same reasoning covers two identical docks or two identical headsets.

- **A device is re-identified when something above it in the chain moves.** Putting the Studio Display on a different Thunderbolt port, with the dock behind it and never unplugged, changed the dock's UID from `…:22200000:1` to `…:20200000:1`. The display's own UID did not move at all, because it is built from the panel's serial number. Two USB devices in the same chain, one keyed on a serial and one on a location, and nothing distinguishes them until one of them moves. So the model-level match is not a repair for devices already known to be unstable — there is no way to know in advance which kind a device is, and a device that has never moved can be re-identified by its neighbour.

- **Reading the device history needs no developer tools.** `/Library/Preferences/Audio/com.apple.audio.SystemSettings.plist` is world-readable and `plutil` is stock, so the history script runs on a Mac that has never had Xcode or the Command Line Tools on it. The Swift dump shows more per device — model UID, manufacturer, which device is current — but only covers what is attached right now, and needs the Swift compiler. Use the history script for comparing two Macs and the Swift one for looking at a live setup.

- **The order is last-writer-wins; per-device flags merge.** An ordered list cannot be merged sensibly. A drag touches many positions at once, so per-position keys would still produce interleavings nobody chose, which is worse than losing a reorder. The whole order is one value with a timestamp, and reordering is rare and deliberate enough that redoing it costs seconds. The per-device flags — hidden, sorted, forgotten — are independent, so each device gets its own key and edits on two Macs merge cleanly. This is the same split locus-launcher uses for hot keys.

- **The menu bar icon is a heuristic.** Transport type gives a coarse kind — built-in, USB, Bluetooth, HDMI or DisplayPort, AirPlay, virtual, aggregate — and that drives the icon. macOS does not reliably expose the specific model, so telling AirPods Pro from AirPods Max means matching on the name, which breaks in other languages and on renamed devices. Fall back to a generic speaker icon rather than guessing wrong.

- **Other audio software can be doing the same job.** SoundSource, and anything else that switches the default device, will fight this app: each change it makes is adopted as an override here, and whatever it does in response is adopted again. There is no reliable way to tell another app's writes from a user's, because they are the same write. Do not try to detect it. If both run the user sees it immediately, so say so in the read-me and leave it there.

- **SoundSource is installed on both Macs during development.** It is being retired once this app can replace it, which means slices 3 onward are built and tested on machines where a competing switcher is live. Quit it before testing anything that writes the default device, or the override adoption in slice 4 will chase it and the results will be nonsense. Its HAL driver in `/Library/Audio/Plug-Ins/HAL/ARK.driver` keeps publishing devices after the app is gone; those are ordinary devices the user can hide.

- **No notifications, ever.** The app does not link `UserNotifications`. The reason the app exists is that Sound Source announces every switch. The menu bar badge for unsorted devices is the only thing that ever asks for attention, and it sits still until it is dealt with.

- **No App Sandbox.** Matches locus-launcher. Signing and notarization still work, and App Store distribution is not a goal, so there is no need to establish whether HAL default-device writes survive the sandbox.

- **No permissions needed.** Reading and setting the default output device needs no user grant. There is no global hotkey, so no Accessibility access either.

- **Two windows, not one.** Sound Devices is the main window and is the whole feature: priority, hidden devices, the new device queue. Settings holds app preferences — launch at login, updates — and stays short. Both are plain AppKit windows hosting SwiftUI views, not SwiftUI's `Settings` scene, which can only be opened from inside a SwiftUI view.

- **Quitting leaves the output where it is.** The app does not restore anything on the way out, because there is nothing sensible to restore to.

- **Updates:** Sparkle, release zips on GitHub Releases, appcast served from GitHub Pages. Betas ride the same feed on a Sparkle channel. Versions are `YYYY.N` for a release and `YYYY.N.B` for a beta, same as locus-launcher.

- **Distribution:** a notarized, stapled `.app` in a zip, not a DMG.

- **License:** MIT.

## Future versions

- **Input devices.** The same problem exists for microphones and is just as annoying. It is a second priority list, a second section in the menu, and a second set of properties to write (`kAudioHardwarePropertyDefaultInputDevice`). The engine and the storage shape are reused as they are. Held out of v1 to keep the first release's model and UI to one list, and because output is the part being used daily right now. Slices 3 through 7 should be built so that adding a second list is adding a second list, not rewriting the engine — but do not build the abstraction until the input work actually starts.

- **Per-device volume memory.** Remember the volume each device was last at and restore it on switch. Wanted, not needed for v1.

- **Profiles.** A named set of priority orders, switched by location or by connected display. Speculative; only build it if the single list turns out not to be enough.

- **Menu keyboard shortcuts.** A hotkey to cycle output, or a hotkey per device. Would pull in the `KeyboardShortcuts` package the way locus-launcher uses it.

## Public repo

The GitHub repo is public at `tjdraper/locus-sound-control`, and it hosts the release zips and the Sparkle appcast.

- Never commit secrets: signing certificates, notarization credentials, or the Sparkle private key. The release script reads them from the Keychain or environment variables.
- Write everything in the repo — code, comments, commit messages, plans, docs — as if the public will read it.
- `.gitignore` covers `.DS_Store`, `xcuserdata`, build output and local config from the start.
- The Sparkle feed URL is baked into every build and can never change. Moving hosting later means adding a custom domain to the same GitHub Pages site rather than picking a new URL. GitHub redirects the `github.io` address and Sparkle follows redirects, so installs in the wild keep updating.

## Useful from locus-launcher

- The whole of `Scripts/` ports over, as detailed in slice 1. The Sparkle key does not port; generate a new one.
- `Plans/ReleaseSetupChecklist.md` is the checklist for the account-holder steps, including the provisioning profile, which this app does need after all.
- `.swiftlint.yml`, the Architecture docs, the `.icon` workflow, and the `MenuBarIcon` badge drawing.
- The launch-at-login, Sparkle gentle reminders, and iCloud key-value storage work is close enough to copy. The hotkey work is not needed here.
