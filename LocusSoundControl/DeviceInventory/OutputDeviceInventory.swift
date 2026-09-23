import AppKit
import CoreAudio
import OSLog

/// The connected output devices and which one the system is currently playing through, kept up to
/// date as devices come and go.
///
/// Nothing is switched here. This is the read-only half of the problem, so that the CoreAudio
/// observation is settled before slice 3 starts making decisions on top of it.
@Observable
final class OutputDeviceInventory {
    private(set) var devices: [AudioOutputDevice] = []
    private(set) var currentOutputUID: String?

    /// True while a device list change is still being waited out. macOS picks its own fallback
    /// output in this window, which is not a choice anyone made.
    private(set) var isSettling = false

    /// macOS's fallback can also land just after the list holds still, so the moment it did is
    /// kept as well as whether it is still settling.
    private(set) var settledAt: ContinuousClock.Instant?

    @ObservationIgnored private var watchers: [Task<Void, Never>] = []
    @ObservationIgnored private var settleTask: Task<Void, Never>?
    @ObservationIgnored private var wakeEndsAt: ContinuousClock.Instant?

    var currentDevice: AudioOutputDevice? {
        devices.first { $0.uid == currentOutputUID }
    }

    deinit {
        // The CoreAudio listeners are removed when the streams they feed are torn down, and the
        // streams end when the tasks reading them are cancelled.
        for watcher in watchers { watcher.cancel() }
        settleTask?.cancel()
    }

    func start() {
        // The streams register their CoreAudio listeners as they are built, and they buffer, so
        // taking them before the first read leaves no gap for a change to fall through.
        let deviceChanges = AudioHardwareChanges.stream(for: kAudioHardwarePropertyDevices)
        let outputChanges = AudioHardwareChanges.stream(for: kAudioHardwarePropertyDefaultOutputDevice)

        devices = OutputDeviceReader.connectedOutputs()
        currentOutputUID = OutputDeviceReader.currentOutputUID()

        watchers = [
            Task { [weak self] in
                for await _ in deviceChanges {
                    self?.deviceListChanged()
                }
            },
            Task { [weak self] in
                for await _ in outputChanges {
                    self?.currentOutputUID = OutputDeviceReader.currentOutputUID()
                }
            },
            Task { [weak self] in
                let center = NSWorkspace.shared.notificationCenter
                for await _ in center.notifications(named: NSWorkspace.didWakeNotification) {
                    self?.wokeUp()
                }
            },
        ]
    }

    /// How long the device list has to hold still before it is believed.
    private enum Pace {
        /// Plugging a device in or pulling it out fires several notifications in a row, and a
        /// Bluetooth device is listed for a moment before it is usable.
        case connect

        /// Waking and logging in re-enumerate everything over several seconds, displays well
        /// before Bluetooth.
        case wake

        var quietWindow: Duration {
            switch self {
            case .connect: .milliseconds(600)
            case .wake: .seconds(2)
            }
        }

        var name: String {
            switch self {
            case .connect: "connect"
            case .wake: "wake"
            }
        }
    }

    /// Slice 3 switches the output device on what settles here, so when it picks the wrong one
    /// the question is always what this saw and when. Rare events only — a device coming or
    /// going, and waking — so it stays readable. Device names are left out: they carry people's
    /// names, and a count answers the question just as well.
    private static let log = Logger(subsystem: "com.buzzingpixel.LocusSoundControl", category: "DeviceInventory")

    /// A list that never holds still is published anyway rather than never.
    private static let settleLimit = Duration.seconds(15)

    /// How long after a wake the wider window is used. The first device back arrives long before
    /// the last one, so the pace cannot be decided by the arrival that triggered this.
    private static let wakeLasts = Duration.seconds(20)

    private var pace: Pace {
        guard let wakeEndsAt, ContinuousClock.now < wakeEndsAt else { return .connect }
        return .wake
    }

    private func wokeUp() {
        Self.log.info("Woke from sleep, so the device list settles at the wider pace from here")
        wakeEndsAt = ContinuousClock.now.advanced(by: Self.wakeLasts)
        deviceListChanged()
    }

    private func deviceListChanged() {
        settleTask?.cancel()
        isSettling = true
        settleTask = Task { [weak self, pace] in
            let settled = await Self.stableList(pace: pace)
            guard let self, !Task.isCancelled else { return }

            // Assigning an equal list would still invalidate every view observing it.
            // Whether it changed, not just that it settled: a wake produces several settles that
            // publish nothing, and a log that cannot tell them apart is a trap for slice 3.
            let changed = devices != settled
            if changed { devices = settled }
            Self.log.info(
                """
                Device list settled at the \(pace.name, privacy: .public) pace: \
                \(settled.count) outputs, \(changed ? "changed" : "unchanged", privacy: .public)
                """
            )
            currentOutputUID = OutputDeviceReader.currentOutputUID()
            settledAt = .now
            isSettling = false
            settleTask = nil
        }
    }

    /// Reads the list until two reads in a row agree, so the intermediate states a connect or a
    /// wake passes through are never published. Slice 3 resolves against the finished list once
    /// instead of switching output through every step.
    private static func stableList(pace: Pace) async -> [AudioOutputDevice] {
        var previous = OutputDeviceReader.connectedOutputs()
        let deadline = ContinuousClock.now.advanced(by: settleLimit)

        while !Task.isCancelled, ContinuousClock.now < deadline {
            try? await Task.sleep(for: pace.quietWindow)
            let current = OutputDeviceReader.connectedOutputs()
            if current == previous { return current }
            previous = current
        }
        return previous
    }
}
