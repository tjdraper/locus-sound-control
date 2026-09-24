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
   - `Scripts/install-test-build.sh`, also ported: notarizes and staples the working tree as it is, without bumping the version or touching the appcast, quits the copy in `/Applications`, trashes it, installs the new build in its place and opens it. It matches the running copy by path so a Debug build from Xcode is left alone. This is how anything that only behaves correctly in a real installed, signed app gets tested — launch at login, the Sparkle update flow, Gatekeeper, and the move-to-Applications prompt. Locus Launcher needed it for Accessibility access; this app needs Bluetooth, which has the same problem — a build launched from a terminal inherits the terminal's grants and hides the failure.
   - `Scripts/ExportOptions.plist` and `Scripts/sparkle-tools.sh` port across too, and `Scripts/README.md` gets rewritten for this app. Change the app name, bundle identifier, artifact name, GitHub repo, feed URL and notary profile (`LocusSoundControl`).
   - A Developer ID provisioning profile is needed, for the same reason locus-launcher needs one: slice 7 syncs through iCloud key-value storage, which is an entitlement a Developer ID build can only carry with a profile. `xcodebuild` on the command line cannot create one when it has no access to the Xcode account, so let Xcode create it once — Product → Archive, then Distribute App → Direct Distribution — and the export in `release.sh` finds it afterwards. Do this in slice 1 even though nothing uses the entitlement yet, so the release chain is proven in its final shape.
   - Sparkle, sharing Locus Launcher's signing key, with the feed at `https://tjdraper.github.io/locus-sound-control/appcast.xml`
   - The beta channel works from here, not from slice 8. `release.sh` can ship a beta on day one, so an updater that cannot ask for the channel would make the first self-update test a no-op. `UpdateChannelPreference` and the `allowedChannels` delegate ship now; only the Settings toggle waits. Opting in meanwhile is a `defaults write`, and a build that is itself a beta receives the next beta without one.
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
   - The menu bar icon shows what the current output is, guessed from its model, its Bluetooth class of device, or its transport, in that order (see Decisions). Slice 5 lets this be overridden per device.
   - Clicking the icon lists the output devices, each with its own icon, and marks the current one (see Decisions). System order for now; slice 3 gives it a real order.
   - The Sound Devices window lists what was found, so there is something to look at while getting the CoreAudio layer right

3. **Priority list and the switching engine**

   - Sound Devices window: drag devices up and down to set priority
   - `OutputResolver`, a pure value type: given the priority order, the hidden set, the connected devices and the active override, it returns the device that should be selected. No CoreAudio inside it, so it goes in the test target (see Tests in `AGENTS.md`).
   - Re-resolve when the device list changes, when the priority order is edited, or when an override changes
   - Write both the default output and the system alert output, keeping them matched, except that alerts are left alone on Bluetooth (see Decisions)
   - When no listed device is connected, leave the system alone rather than forcing something
   - First launch seeds the priority list from the connected devices, current output first, and marks them all as seen
   - Storage: an ordered list of device entries in `UserDefaults`, each holding a set of UIDs rather than one (see Decisions). Slice 6 adds the matching that puts several UIDs in an entry and the UI to correct it; this slice only has to store the shape, so nothing needs migrating later.
   - The entry also carries an optional assigned symbol name, which slice 5 gives a picker. Store it here for the same reason as the UID set: adding a field in slice 5 means migrating what is already written.
   - The menu now lists devices in priority order
   - Devices that are not connected appear in the Sound Devices window for the first time here, since this is the slice that starts remembering them. They stay in place in the order, dimmed (see Decisions).

4. **Overrides**

   - Clicking a device in the menu sets an override, which wins over priority until it is canceled
   - Double-clicking a connected device in the Sound Devices window does the same. The window's header already says so, so this lands with the menu's click rather than after it.
   - Cancel from the same menu
   - A change made outside the app — Control Center, System Settings, another app — is adopted as an override (see Decisions). Changing output anywhere works, and the app never fights you.
   - Suppress adoption during the churn window after a device list change, so macOS's own fallback when a device disappears is not mistaken for a deliberate choice. The window runs until a few seconds after the list settles, because macOS's picks can land just after it holds still.
   - The one exception is a device never seen before. macOS switches to a device when it first connects, and that is adopted, so a new device plays instead of being switched away from straight back to whatever sits above it in the order. A known device arriving goes through priority, which is what stops reconnecting AirPods from replacing an override.
   - The override survives quit and restart
   - When the overridden device disappears, the override is cleared and priority takes over. It does not come back when the device reconnects.
   - The three-second adoption window is a first guess. The log records the timing of every adopted or suppressed change, so it can be tuned from real cases.

5. **Hidden and forgotten devices**

   - Hide a device: it stops being eligible for automatic selection and drops out of the menu. Virtual devices from other apps are the main reason this exists.
   - Assign a device its own icon, from a curated grid of SF Symbols (see Decisions). It shows in the menu bar when that device is current, in the menu's device list, and in the Sound Devices rows. The list is where it earns most of its keep, since icons make a column of similar names scannable.
   - Hidden devices stay in the Sound Devices window in their own area, and can be unhidden
   - Forget a device that is not currently connected: its record is deleted. If it ever reconnects it arrives as a new device again.
   - Forget is only offered for disconnected devices, since forgetting a connected one would immediately re-add it
   - Hiding and overrides meet here. The resolver lets an override win even on a hidden device, and a change made in Control Center to a hidden device is adopted like any other. Decide whether hiding the overridden device cancels its override.
   - The menu's device rows and its override banner draw `AudioOutputDevice.symbolName`, the guessed icon, so an assigned icon will not show there until they read the entry's `symbolName` instead. The menu bar icon and the Sound Devices window already use the entry.
   - SwiftUI's `Image(systemName:)` draws nothing for a name that does not resolve, so the Sound Devices rows and override panel need the same fallback to the generic speaker that the AppKit menu already has.
   - The Sound Devices list already has row selection and an empty `contextMenu(forSelectionType:)` (its primary action is the double-click override), which is the natural home for Hide, Forget and the icon picker.

6. **New device queue and badge**

   - A device the app has never seen goes into a queue instead of the priority list, and the menu bar icon gets a badge
   - The Sound Devices window shows the queue at the top, and dragging a device out of it into the priority list clears it
   - The window's "Priority Order" header sits at the top of the window today. Once the queue is above the list, the header belongs with the list, below the queue, or it reads as describing the queue.
   - A new device is not eligible for automatic selection while it sits in the queue. Plugging something in should not silently hijack audio.
   - macOS usually switches to a newly connected device on its own. Slice 4 adopts that as an override when the device has never been seen, so the new device does play, the badge says it needs sorting, and nothing is lost if it is never sorted. "Never seen" is decided against the priority order today. Once the queue exists, this slice has to decide whether a queued device reconnecting still counts as never seen, which decides whether it plays each time it comes back.
   - The badge is drawn into the menu bar image, the same approach as locus-launcher's `MenuBarIcon`
   - Screen sharing and AirPlay taps get a new UID per session (see Decisions). They never enter the queue and never badge, or the icon would light up after every screen share.
   - The Sound Devices window can **merge** two entries into one — these are the same device — and **split** a merged entry back apart. Both directions are needed: the automatic match cannot tell two units of the same model apart (see Decisions), and a device with no model identifier has nothing else to fall back on. A merged entry shows which identities it covers, so what the app decided is visible rather than guessed at.
   - **This slice needs the model-level match from slice 7, on a single Mac, with no sync involved.** A USB audio UID ends in either a serial number or a USB location ID, and a location ID changes with the port. CoreAudio's own records show the CalDigit dock on this Mac under eight location IDs, one per Thunderbolt port it has ever been in. Keyed on UID alone the dock would badge as a new device every time it moved sides, and would carry a separate priority entry for each port. Build the match here and let slice 7 reuse it, rather than the other way round.
   - Merge and Split go in `DeviceCommand`, which is where the File menu, the list's context menu and the row buttons all get their commands and titles. Merge needs two or more entries, so it shows in the menus but never as a row button, since those act only on their own row. Split acts on one entry that holds more than one UID, so it can be a row button.
   - A merge of a hidden entry with a visible one has to decide whether the result is hidden. The assigned icon is already settled: last writer wins (see Decisions).
   - Hidden entries keep their slots in the stored order, and dragging moves visible entries around them (`PriorityOrder.moveVisible`). Dropping a device from the queue into the list gives an offset among the visible rows, so it needs the same translation to a position in the full order.
   - Decide whether hiding a queued device also sorts it. It probably should: hiding is a decision about the device, and a virtual device nobody wants would otherwise keep the badge lit until it is dragged into a list it will never be chosen from.
   - A forgotten device that reconnects lands in the queue and badges. That is what "arrives as a new device" means once the queue exists, and the confirmation dialog says so.

7. **iCloud sync**

   Two Macs that move between the same docks, displays and headphones should not have to be taught the same order twice.

   - The priority order, the hidden flag, the assigned icon, and whether a device has been sorted all sync through iCloud key-value storage
   - Forgetting a device syncs too. If the other Mac is offline and has that device connected, it comes back there as a new device, which is self-correcting rather than wrong.
   - The active override never syncs. It is about what you are doing on that Mac right now.
   - Device equivalence is handled by slice 6's matching and merging. This slice syncs the result, so a merge made on one Mac holds on the other.
   - A single on/off for sync in Settings. Per-device sync choices would be more machinery than this earns.
   - On a second Mac's first run, an incoming synced order replaces the local seed rather than merging with it. The seed is a guess made from whatever happened to be plugged in; the synced order is something the user actually arranged.
   - A synced order naturally contains devices this Mac has never seen. The priority list already holds disconnected devices, so they list normally and simply never win.

8. **Settings**

   - A Settings window separate from Sound Devices (see Decisions)
   - Launch at login (`SMAppService`)
   - Bluetooth access: what it is granted as, what it is for, and a way to System Settings when it has been denied. This is the only place someone who said no can find out why a Bluetooth speaker shows a headphones icon.
   - Sync on/off (slice 7), with a line naming what it carries and what it does not
   - Beta updates toggle, bound to the `ReceiveBetaUpdates` default slice 1 already reads, with a line saying betas ship more often and may break. Also the prompt a Mac gets on its first full release after running betas, asking whether to stay on them.
   - Sparkle gentle reminders (https://sparkle-project.org/documentation/gentle-reminders). By default a scheduled check that finds an update throws Sparkle's window to the front at an arbitrary moment, which is exactly the interruption this app exists to avoid. Show a quiet sign instead and open the window when it is clicked. Sparkle logs a warning at launch until this is done.
   - Whether the update sign can live only in the menu bar icon depends on slice 10's decision about hiding the icon

9. **First-run wizard**

   - A one-page setup checklist on first launch, reopenable from the menu
   - Only fresh installs see it. Earlier installs are recognized by Sparkle's launched-before flag and skip it.
   - Move to `/Applications` if needed
   - Confirm the seeded priority order, since the seed is a guess
   - Launch at login
   - Ask for Bluetooth access here, which is where a permission request is expected and where it costs nothing to explain first (see Decisions). Say what it buys — telling a Bluetooth speaker from headphones — and that it can be skipped.
   - Ask about automatic update checks here. Sparkle otherwise raises its own prompt on the second launch, which for a login-item menu bar app lands at a random moment. Take it over with `SPUUpdaterDelegate.updaterShouldPromptForPermissionToCheckForUpdates`.
   - Each step reflects real current state, so a change made in System Settings updates the wizard

10. **Polish and first release**

   - App icon. The menu bar icons stay SF Symbols: slice 5 lets the user pick from a curated set of them, so replacing them with drawn artwork would mean drawing the whole set. Custom artwork for the default symbol alone is still on the table, and would have to keep working with the badge drawn over it.
   - Website download page, v1
   - Decide whether the menu bar icon can be hidden. macOS's own "Allow in the Menu Bar" covers hiding it, but this app's only affordance for setting an override is that menu, so hiding it removes a feature rather than just an indicator.
   - Remove the setup checklist row from Settings if it was added there. The menu still opens it.

## Decisions

- **Outside changes become overrides.** Setting the default output fires the same notification whether the app or something else did it, so the app compares the new device against what it last wrote. A match is its own write. A mismatch is someone else, and becomes an override. This is compared by resulting device rather than by tracking individual writes, so it cannot get out of step. The exception is the window right after a device list change, when macOS picks its own fallback; adoption is suppressed there, and the app switches back to what priority or the override says.

  That window lasts until three seconds after the list settles. Too short and macOS's late picks become overrides; too long and a real choice made right after plugging something in gets reverted. Every adoption and every suppressed change is logged with how long after the settle it came, so the number can be tuned from real cases rather than guessed.

  A device never seen before is adopted even inside the window. macOS switching to a device the moment it first connects is the only way it gets played at all, since it arrives at the bottom of the order. Known devices are not, because adopting macOS's switch to reconnecting AirPods would replace an override with them, which is the original complaint.

- **A connecting device takes over unless you chose the current one.** A higher-priority device arriving switches output immediately, even mid-playback — that is what a priority order means. The exception is an active override, which holds until it is cancelled or its device disappears. So the override is not just a way to depart from the order for a moment; it is how the user says "I am deliberately listening here, leave it alone." Since a change made in Control Center is adopted as an override too, that statement can be made from outside the app as well as inside it. This is the answer to the original complaint: AirPods reconnecting take over when nothing was chosen, and do not when something was.

- **Overrides do not re-arm.** When the overridden device disappears the override is cleared for good. Reconnecting it goes through the normal path: priority decides, and macOS's own switch to it lands in the churn window and is not adopted. Only a device the app has never seen is adopted that way (see "Outside changes become overrides").

- **Both output properties are written.** macOS tracks the default output and the system alert output separately and they drift apart, which is a common surprise. The app keeps them matched. Not every device can be the system alert output, so a failure there is ignored rather than retried.

  **Except on Bluetooth, where matching them drops the AirPods.** Found in slice 3's first real test. AirPods shared with an iPhone become the Mac's output provisionally when they connect, and are only claimed from the iPhone once real audio plays. macOS keeps alerts on the speakers meanwhile. The app moved alerts onto the AirPods, an iTerm notification played there, and an alert does not claim the AirPods — so after 1.5 seconds macOS gave up and moved everything to the speakers. The log line from `audioaccessoryd` is "Audio has been playing on virtual device for 1.5s. Route to speaker". Selecting the AirPods as the default output alone holds, and real audio then claims them. So on Bluetooth the alert output is left where macOS puts it.

  This also bears on slice 4. The move back to the speakers was macOS's own, arrived ten seconds after the device list settled, and would have been adopted as an override. The Bluetooth exception removes the case seen here, but macOS's AirPods routing can change the output on its own for other reasons, so watch for it when building adoption.

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

  There is a fourth: CoreAudio's own transient objects, named after the process that caused them — `CADefaultDeviceAggregate-90478-3`, `AudioTap-441263EC-…`. None were in the live output list when this was checked, so they are normally private, but they do arrive and leave. Exclude them with `kAudioDevicePropertyIsHidden` rather than by matching names, which is the supported signal and does not need updating when Apple renames something. Do not exclude by virtual transport: plenty of virtual devices, SoundSource's among them, are outputs someone might choose, and hiding one is the user's call.

- **A device that cannot be the default output is not an output.** Building slice 3 found that the Teams loopback device publishes output buffers but reports `kAudioDevicePropertyDeviceCanBeDefaultDevice` as false. Writing it as the default output returns no error and changes nothing, so the engine logged a switch that never happened. System Settings leaves such devices out of its output list, and the inventory now does the same. This takes the Teams device out of the "hide by hand" case above: it was never choosable in the first place.

- **The cross-Mac comparison came back clean, which relocates the problem.** Running the history script on both Macs and diffing: the Studio Display's two serials, the Dell's id, the AirPods' MAC, `BuiltInSpeakerDevice` and the Teams device are byte-identical on both. Even the dock's eight location IDs are the same eight, because two MacBook Pros of the same model number their Thunderbolt ports the same way. So matching across Macs by UID would in fact work for every device here. The identity work is not really about sync at all — it is about one Mac recognising its own dock across ports, which is why it belongs in slice 6 rather than slice 7.

- **Fold UIDs into one entry by model, not by parsing.** Telling a serial number from a location ID inside a UID string means guessing from its shape, and the Studio Display's `00008150-001262E821C2401C` against the dock's `22200000` is exactly the comparison that makes that guess unreliable. Skip it: match on `kAudioDevicePropertyModelUID` plus transport type instead, which is a model-level identifier CoreAudio hands over directly, and covers display audio as well as USB. The devices with no `modelUID` at all, the Dell among them, fall to the manual merge.

- **The model identifier was verified to hold when the UID moves.** Moving the CalDigit dock from behind the Studio Display to a direct connection changed its UID from `…:22200000:1` to `…:21200000:1` and changed nothing else: `modelUID` stayed `CalDigit Thunderbolt 3 Audio:2188:6533`, as did the name, manufacturer and transport. This is the assumption slice 6 rests on, so it was worth testing before writing code rather than after. Re-test it on a macOS major release, since the UID format is Apple's to change.

- **Two units of one model will be merged, and that is the accepted cost.** A model identifier is vendor and product — `Studio Display Audio Control:05AC:1118` — so it cannot distinguish two Studio Displays, and this setup has two. The simultaneity guard catches them whenever both are plugged in at once. When they are not, the second one adopts the first one's priority entry, and the fix is a split in the Sound Devices window. The alternative, asking before merging, means a prompt at the moment a device is plugged in, which is the interruption this app exists to remove. So merge silently, show the result, and make it reversible. The same reasoning covers two identical docks or two identical headsets.

- **A device is re-identified when something above it in the chain moves.** Putting the Studio Display on a different Thunderbolt port, with the dock behind it and never unplugged, changed the dock's UID from `…:22200000:1` to `…:20200000:1`. The display's own UID did not move at all, because it is built from the panel's serial number. Two USB devices in the same chain, one keyed on a serial and one on a location, and nothing distinguishes them until one of them moves. So the model-level match is not a repair for devices already known to be unstable — there is no way to know in advance which kind a device is, and a device that has never moved can be re-identified by its neighbour.

- **Reading the device history needs no developer tools.** `/Library/Preferences/Audio/com.apple.audio.SystemSettings.plist` is world-readable and `plutil` is stock, so the history script runs on a Mac that has never had Xcode or the Command Line Tools on it. The Swift dump shows more per device — model UID, manufacturer, which device is current — but only covers what is attached right now, and needs the Swift compiler. Use the history script for comparing two Macs and the Swift one for looking at a live setup.

- **The order is last-writer-wins; per-device flags merge.** An ordered list cannot be merged sensibly. A drag touches many positions at once, so per-position keys would still produce interleavings nobody chose, which is worse than losing a reorder. The whole order is one value with a timestamp, and reordering is rare and deliberate enough that redoing it costs seconds. The per-device flags — hidden, sorted, forgotten, assigned icon — are independent, so each device gets its own key and edits on two Macs merge cleanly. The assigned icon needs no machinery of its own for this reason; it is one more key per device, and a merge in slice 6 resolves two assignments the same last-writer way. This is the same split locus-launcher uses for hot keys.

- **The icon is guessed from the most specific thing known about a device.** Three signals, in order, each falling through to the next:

  1. **The model**, from `kAudioDevicePropertyModelUID`. This was written off at first — "macOS does not expose the model, so telling AirPods Pro from AirPods Max means matching the name" — and that was wrong twice over. The property carries a model-level identifier, and unlike the name it is neither localized nor changed by renaming the device. It comes in two shapes: Bluetooth reports `<product> <vendor>` in lower-case hex, and USB audio reports `<name>:<vendor>:<product>`.

     For Bluetooth there is no table to keep, because macOS already has one. Every accessory it knows is declared as a uniform type tagged with the accessory's Bluetooth vendor and product id, so `UTType(tag:tagClass:conformingTo:)` with the `public.bluetooth-vendor-product-id` tag class turns `2014 4c` into `com.apple.airpods-pro-gen2`. Apple files the range in three lines — `com.apple.airpods`, `com.apple.airpods-pro` and `com.apple.airpods-max` — and every model conforms to exactly one of them, so conformance picks the symbol and a model that ships with a later macOS is recognized with no change here. An id outside the catalog comes back as a type invented on the spot rather than as nothing, so a dynamic type is treated as no answer. The Beats range is deliberately left to step 2: Apple files the Beats Pill, a speaker, under `com.apple.beats-headphones`, and the class of device gets it right.

     USB has no equivalent tag class, so those are listed one at a time, matched on the tail of the identifier so that renaming the device cannot break the match. The Studio Display's `:05AC:1118` is the only entry, and each one has to be read off a real device.
  2. **The Bluetooth class of device**, for anything Bluetooth the table does not name. Every Bluetooth device advertises one, so this separates loudspeakers, car kits and headphones for every maker at once with no table to keep. `IOBluetoothDevice.pairedDevices()` reads it in well under a millisecond, and a Bluetooth output device's UID starts with the address that keys it. It is the one thing in the app that needs a permission (see Decisions). Hands-free is deliberately unmapped: it covers both car kits and speakerphones, so it says no more than the transport already did.
  3. **The transport**, which gives a coarse kind — built-in, Bluetooth, HDMI or DisplayPort, AirPlay, virtual. Where it says nothing useful — USB, Thunderbolt, aggregate, unknown — a generic speaker beats a guess.

  All three are still guesses, and slice 5's per-device assignment is how a miss gets fixed for good.

- **Assigned icons come from a curated set, not all of SF Symbols.** Twenty-two symbols in a grid, one screen, no search. The symbol has to read as a flat silhouette at 18pt, and almost none of the six thousand mean anything for an audio device. A stored symbol name is a string that `NSImage(systemSymbolName:)` can fail to resolve if Apple renames or drops one, so an unresolved name falls back to the generic speaker rather than leaving the menu bar empty. The set, chosen by rendering every candidate at 18pt and reading it at size:

  - speakers: `hifispeaker` (the default), `hifispeaker.2`, `speaker.wave.2`, `speaker.wave.3`
  - worn: `headphones`, `airpods.max`, `airpods.pro`, `airpods`, `hearingdevice.ear`
  - room: `homepod`, `tv`, `appletv`
  - screens and Macs: `display`, `laptopcomputer`, `desktopcomputer`
  - other: `car`, `waveform`, `airplayaudio`, `dot.radiowaves.left.and.right`, `cable.connector.horizontal`, `music.note`, `pianokeys`

- **The curated set is outline-only, and excludes the hierarchical symbols.** Mixing `.fill` and outline variants in one grid reads as a mistake, so the set holds one style. Separately, `homepod` draws its main shape as a light grey stroke, which flattens to something visibly fainter than its neighbours in a template image; it is kept because it is the only smart-speaker glyph. The bud variants that are indistinguishable from `airpods.pro` at 18pt are dropped. Note that `airpods.max` and `airpodsmax` are two spellings of one glyph, as are `airpods.pro` and `airpodspro` — store the dotted form.

- **"The Beats symbols are too faint" was true of exactly one of them.** They were all dropped on that reasoning, and re-rendering them with `Scripts/render-sf-symbols.swift` showed it holds only for `beats.headphones`, whose ear cups really are a light grey stroke. `beats.powerbeatspro`, `beats.powerbeats3`, `beats.powerbeats`, `beats.fitpro`, `beats.studiobuds`, `beats.solobuds`, `beats.pill` and `beats.earphones` are solid at 18pt and each says something a plain `headphones` cannot. So the automatic icon uses them, and only the lines Apple files under its `com.apple.beats-headphones` catch-all — Solo, Studio, Beats 360 — fall back to `headphones`.

  This leaves the automatic icon able to pick symbols that slice 5's grid does not offer, so a user who changes one cannot choose it again. Slice 5 answers that with an "Automatic" choice in the picker rather than by growing the grid, which would mean adding every Beats glyph to a set chosen to be one screen.

- **macOS names a symbol for each accessory, and it is not good enough to use.** Control Center's output list draws the same glyphs this app does, and the reason is that the accessory catalog carries `UTTypeIcons.UTTypeSymbolName` next to the vendor and product id — `com.apple.power-beats-pro` names `beats.powerbeatspro` outright. It was worth checking whether to read that instead of choosing symbols here. It is not:

  - `UTType` exposes `tags` but not `UTTypeIcons`, so there is no public way in. It would mean parsing `CoreTypes.bundle`'s own plists across its fourteen sub-bundles, and giving up the public lookup that makes the rest of this work.
  - It is empty exactly where it matters. `com.apple.airpods-pro-gen2` — the AirPods Pro most people own — names no symbol at all, nor do AirPods Max 2024, AirPods Max 2, the USB-C AirPods Pro 2, Beats Solo 4 or Beats Fit Pro 2025. Matching on the parent type covers every one of them.
  - `com.apple.power-beats-pro-gen2` names `40262ECA475D4CCF9722443885EC78D8`, a private unnamed asset rather than a symbol.
  - It mixes styles, naming `beats.pill.fill` where the rest are outlines.

  The generation-specific glyphs it points at — `airpods.pro.gen1`, `airpods.pro.gen3`, `airpods.gen3`, `airpods.gen4` — are real and do resolve. They are not used, because the models that name none would sit next to them looking generic, which is worse than every AirPods line looking alike.

- **An active override is shown by the menu bar icon's shape.** The symbol sits on a rounded rectangle filled with the accent color, the way macOS marks a menu bar item that is holding something on. That makes it the one menu bar image that is not a template, so it is set again when the accent color changes. An override means the priority order has stopped deciding, which is worth seeing without opening the menu. It changes the whole shape rather than a corner, so it stays distinct from slice 6's badge. Slice 6 has to draw the badge over this shape as well as over the plain symbol.

- **The badge does not constrain which symbol is drawn.** `MenuBarIcon` punches clear space around the badge before filling it, so the badge reads as separate over any glyph. It costs a corner of whatever symbol is underneath, which is why the corner is fixed rather than chosen per symbol.

- **Every menu row carries its device's icon, and the current one is tinted as well as checked.** The menu is a column of similar-looking names, so the icon is what makes a row findable at a glance — the same reason it earns its keep in the Sound Devices list. The row for the current output draws its icon in the accent colour and keeps the checkmark. Tint is what the eye lands on; the checkmark is the state AppKit reserves a column for and the one VoiceOver reads, so replacing it with colour alone would trade an accessible signal for nothing, and would leave anyone who cannot separate the two colours with no mark at all. Control Center's own output list marks the current device the same way.

  The colour is `NSColor.controlAccentColor`, which follows Accent colour in System Settings. Highlight colour is a separate setting — it is the selection background — and reading it here would be wrong even though the two usually agree. An accent set to Multicolour reports blue, so the mark is blue on those Macs rather than following anything.

- **The menu bar item is AppKit, not `MenuBarExtra`.** A SwiftUI `MenuBarExtra` menu draws no icons at all: not the icon of a `Label`, and not an `Image(nsImage:)` either. The cause is that macOS 27 hides menu item images unless the item sets `preferredImageVisibility` to `.visible`, and SwiftUI offers no way to reach that property. Since every row carries an icon, the menu is an `NSStatusItem` with an `NSMenu` that is rebuilt each time it opens.

  That decides the rest of the app's shape. With no scene left, the entry point is AppKit, and the standard key equivalents SwiftUI's `App` was providing have to be rebuilt: an accessory app never shows a menu bar of its own, but AppKit still routes ⌘C, ⌘W and ⌘Q through `NSApp.mainMenu`, so a window without one cannot copy or close. Both windows are AppKit hosting SwiftUI views, which is what this plan already called for and what locus-launcher does.

- **Other audio software can be doing the same job.** SoundSource, and anything else that switches the default device, will fight this app: each change it makes is adopted as an override here, and whatever it does in response is adopted again. There is no reliable way to tell another app's writes from a user's, because they are the same write. Do not try to detect it. If both run the user sees it immediately, so say so in the read-me and leave it there.

- **SoundSource is installed on both Macs during development.** It is being retired once this app can replace it, which means slices 3 onward are built and tested on machines where a competing switcher is live. Quit it before testing anything that writes the default device, or the override adoption in slice 4 will chase it and the results will be nonsense. Its HAL driver in `/Library/Audio/Plug-Ins/HAL/ARK.driver` keeps publishing devices after the app is gone; those are ordinary devices the user can hide.

- **No notifications, ever.** The app does not link `UserNotifications`. The reason the app exists is that Sound Source announces every switch. The menu bar badge for unsorted devices is the only thing that ever asks for attention, and it sits still until it is dealt with.

- **No App Sandbox.** Matches locus-launcher. Signing and notarization still work, and App Store distribution is not a goal, so there is no need to establish whether HAL default-device writes survive the sandbox.

- **One permission, asked for where it is expected.** Reading and setting the default output device needs no user grant, and there is no global hotkey, so no Accessibility access either. Bluetooth is the exception: the class of device that tells a Bluetooth speaker from headphones is privacy-sensitive, so `NSBluetoothAlwaysUsageDescription` is required and macOS kills the app outright without it.

  It is asked for in slice 9's setup checklist, which is where a permission request is expected, and where there is room to say what it buys before the system prompt appears. A prompt that arrives unannounced weeks later, at the moment someone puts headphones on, is the arbitrary interruption this app exists to remove.

  The checklist cannot be the only route, because only fresh installs see it and the step can be skipped. So the request is also deferred to the point of use: the paired devices are read only when a Bluetooth device is actually among the outputs, which means a Mac that never plays through one is never asked at all, and an upgrade is asked the first time one connects. The wording says what is read and that the app never scans for or connects to anything.

  Being denied has to be visible, or the only symptom is a Bluetooth speaker wearing a headphones icon with nothing to explain it. Both the checklist and Settings show the current state and offer the way to System Settings, and the Sound Devices window says so in one quiet line when access is denied and a Bluetooth device is listed — the place where the wrong icon is actually being looked at.

  This only shows up in a real installed build. A build launched from a terminal is attributed to the terminal's own permissions, so it will appear to work while the same code crashes on a double-click. Test anything touching a permission with `Scripts/install-test-build.sh`.

- **A device that is not connected is dimmed in place, not moved.** The priority list is one order, so lifting absent devices into their own area would show an order different from the one stored, and leaving them out of the window altogether would hide the thing "Forget" acts on. They stay where they are, with the row and its icon dimmed. Hidden devices and the new device queue get areas of their own because they are genuinely separate lists; a disconnected device is an ordinary member of the priority list that happens not to be here right now.

  The right-hand label says the state in words — "Current Output" for the one playing, nothing for a device that is connected, "Not Connected" for the rest — so the difference never rests on dimming alone.

- **Hiding the overridden device cancels its override.** Hiding says "not this one", and an override left in place would keep the sound on the device just hidden, with nothing in the menu to show why. Choosing a hidden device afterwards still sets an override: double-clicking it in the window, or picking it in Control Center, which is adopted like any other outside change. The resolver lets an override win on a hidden device for that reason.

- **A hidden device keeps its place in the order.** Hidden devices are listed in their own area, but their entries stay where they were in the stored order, and dragging the visible ones moves them around those slots. Unhiding puts a device back where it was rather than at the bottom, so hiding by mistake costs nothing.

- **The menu keeps a hidden device while it is playing.** Hidden devices drop out of the menu, except the current output. With every connected device hidden the app leaves the output alone, and macOS may land on a hidden one; a menu with no checked row would stop saying where the sound is going.

- **Every window centers on the primary display the first time and is where you left it after that.** This binds any window the app ever grows, not just the two it has now. A window that reopens where it was is the difference between a tool and something that has to be dragged back into place each time, and the cost is a line at the point the window is built — locus-launcher's `RememberedWindowPlacement(autosaveName:)`, ported with one fix.

  Applied as each window is built rather than swept up at the end, since a window that ships without it teaches people where it lands and then moves.

  The fix: a window built from an `NSHostingController` measures 1x32 until something asks its content for a size, so `NSWindow.center()` puts the corner where the middle should be. locus-launcher reaches for `NSWindow.layoutIfNeeded()`, which does not settle it, and neither does `layoutSubtreeIfNeeded()` on the content view. Reading `fittingSize` does. Measured here on a 1512-wide display: a 520-wide window landed at x=755, the screen's midpoint, instead of 496. **locus-launcher has the same bug and its windows are off center on first open.**

- **An open window gives the app a Dock icon.** A menu bar app's window is otherwise missing from ⌘Tab and the Dock, so once another app covers it the only way back is the menu bar. While any window is open the app is a regular app, and it goes back to menu bar only when the last one closes. Clicking the Dock icon, or opening the app again from Finder, shows Sound Devices. Like window placement, this binds every window the app grows: each presenter reports its window to `DockIconPresence` when it shows and closes. Ported from locus-launcher.

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

- The whole of `Scripts/` ports over, as detailed in slice 1. The Sparkle key ports as it is: Sparkle's own guidance is one signing key per publisher rather than per app, and `generate_keys` reuses the existing one.
- `Plans/ReleaseSetupChecklist.md` is the checklist for the account-holder steps, including the provisioning profile, which this app does need after all.
- `.swiftlint.yml`, the Architecture docs, the `.icon` workflow, and the `MenuBarIcon` badge drawing.
- The launch-at-login, Sparkle gentle reminders, and iCloud key-value storage work is close enough to copy. The hotkey work is not needed here.
