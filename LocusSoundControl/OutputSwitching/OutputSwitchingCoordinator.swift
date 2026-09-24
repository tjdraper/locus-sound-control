import Foundation
import OSLog

/// Keeps the Mac playing through the override if there is one, and otherwise through the
/// connected device highest in the priority order, deciding again whenever the settled device
/// list, the order or the override changes.
final class OutputSwitchingCoordinator {
    private let outputDevices: OutputDeviceInventory
    private let priorityOrder: PriorityOrderStore
    private let override: OverrideStore
    private var task: Task<Void, Never>?

    /// What the app last wrote, or last chose to leave alone. The output landing anywhere else was
    /// someone else's doing.
    private var expectedUID: String?

    /// Every change to the output funnels through here, the app's own writes included, so this is
    /// what tells a change worth deciding on from the echo of one already made.
    private var lastDecided: Decided?

    private struct Decided: Equatable {
        let devices: [AudioOutputDevice]
        let order: PriorityOrder
        let overrideUID: String?
    }

    /// Every switch and every adopted override lands here with the reason for it, since a wrong
    /// one is heard long after the moment that caused it. Positions, counts and timings only,
    /// never device names.
    private static let log = Logger(subsystem: "com.buzzingpixel.LocusSoundControl", category: "OutputSwitching")

    init(outputDevices: OutputDeviceInventory, priorityOrder: PriorityOrderStore, override: OverrideStore) {
        self.outputDevices = outputDevices
        self.priorityOrder = priorityOrder
        self.override = override
    }

    deinit {
        task?.cancel()
    }

    func start() {
        task = Task { [weak self, outputDevices, priorityOrder, override] in
            let changes = Observations {
                (
                    outputDevices.isSettling,
                    outputDevices.devices,
                    outputDevices.currentOutputUID,
                    priorityOrder.order,
                    override.uid
                )
            }
            for await _ in changes {
                self?.somethingChanged()
            }
        }
    }

    /// Each step that changes the order or the override returns, since that change comes straight
    /// back around and deciding on what came before it would be deciding twice.
    private func somethingChanged() {
        // The list is still moving, and macOS's own fallback lands in this window.
        guard !outputDevices.isSettling else { return }
        let devices = outputDevices.devices

        if let overrideUID = override.uid, !devices.contains(where: { $0.uid == overrideUID }) {
            // It does not come back when the device reconnects. Reconnecting goes through priority
            // like any other device, which is what keeps a returning pair of AirPods from taking
            // over when something else has been chosen since.
            override.cancel()
            Self.log.info("The override's device is gone, so the override is cancelled and priority takes over")
            return
        }

        let adoption = OutsideChangeAdoption.decide(
            current: outputDevices.currentDevice,
            expectedUID: expectedUID,
            overrideUID: override.uid,
            order: priorityOrder.order,
            sinceSettle: sinceSettle
        )
        if case let .adopt(reason) = adoption, let current = outputDevices.currentDevice {
            override.set(current.uid)
            Self.log.info(
                "\(Self.describe(reason), privacy: .public) \(self.sinceSettleDescription, privacy: .public), adopted as the override"
            )
            return
        }

        let order = priorityOrder.order
        priorityOrder.record(devices, currentOutputUID: outputDevices.currentOutputUID)
        guard priorityOrder.order == order else { return }

        let inputs = Decided(devices: devices, order: order, overrideUID: override.uid)
        if adoption == .leaveToPriority {
            Self.log.info(
                """
                The output moved \(self.sinceSettleDescription, privacy: .public), \
                taken as macOS's own pick rather than a choice
                """
            )
        } else if lastDecided == inputs {
            return
        }
        lastDecided = inputs
        select(OutputResolver.resolve(order: inputs.order, connected: devices, overrideUID: inputs.overrideUID))
    }

    private func select(_ resolution: OutputResolver.Resolution) {
        let order = priorityOrder.order
        let connectedCount = outputDevices.devices.count
        guard case let .device(device, reason) = resolution else {
            expectedUID = outputDevices.currentOutputUID
            Self.log.info(
                """
                None of the \(order.entries.count) devices in the priority order is both connected and not hidden, \
                so the output is left alone
                """
            )
            return
        }

        let outcome = DefaultOutputWriter.select(device)
        switch outcome {
        case .alreadySelected, .switched: expectedUID = device.uid
        case .deviceNotFound, .failed: expectedUID = outputDevices.currentOutputUID
        }
        Self.log.info(
            """
            Output belongs on \(Self.describe(reason), privacy: .public) of \(order.entries.count), \
            with \(connectedCount) connected: \(Self.describe(outcome), privacy: .public)
            """
        )
    }

    private var sinceSettle: Duration? {
        outputDevices.settledAt.map { ContinuousClock.now - $0 }
    }

    private var sinceSettleDescription: String {
        guard let sinceSettle else { return "(no device list change since launch)" }
        let elapsed = sinceSettle.formatted(.units(allowed: [.seconds], fractionalPart: .show(length: 1)))
        return "(\(elapsed) after the device list settled)"
    }

    private static func describe(_ reason: OutsideChangeAdoption.Reason) -> String {
        switch reason {
        case .outsideChange: "The output was changed outside the app"
        case .newDevice: "macOS switched to a device never seen before"
        }
    }

    private static func describe(_ reason: OutputResolver.Reason) -> String {
        switch reason {
        case .override: "the override"
        case let .priority(index): "priority \(index + 1)"
        }
    }

    private static func describe(_ outcome: DefaultOutputWriter.Outcome) -> String {
        switch outcome {
        case .alreadySelected: "already there"
        case .switched: "switched"
        case .deviceNotFound: "not switched, the device was gone before it could be selected"
        case let .failed(status): "not switched, CoreAudio refused with status \(status)"
        }
    }
}
