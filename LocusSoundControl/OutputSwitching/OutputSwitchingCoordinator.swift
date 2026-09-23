import Foundation
import OSLog

/// Keeps the Mac playing through the connected device highest in the priority order, deciding
/// again whenever the settled device list or the order changes.
final class OutputSwitchingCoordinator {
    private let outputDevices: OutputDeviceInventory
    private let priorityOrder: PriorityOrderStore
    private var task: Task<Void, Never>?

    /// Every switch lands here with the reason for it, since a wrong switch is heard long after
    /// the moment that caused it. Positions and counts only, never device names.
    private static let log = Logger(subsystem: "com.buzzingpixel.LocusSoundControl", category: "OutputSwitching")

    init(outputDevices: OutputDeviceInventory, priorityOrder: PriorityOrderStore) {
        self.outputDevices = outputDevices
        self.priorityOrder = priorityOrder
    }

    deinit {
        task?.cancel()
    }

    func start() {
        task = Task { [weak self, outputDevices, priorityOrder] in
            for await (devices, order) in Observations({ (outputDevices.devices, priorityOrder.order) }) {
                self?.devicesOrOrderChanged(devices: devices, order: order)
            }
        }
    }

    private func devicesOrOrderChanged(devices: [AudioOutputDevice], order: PriorityOrder) {
        priorityOrder.record(devices, currentOutputUID: outputDevices.currentOutputUID)
        // Recording a new device changes the order, which comes straight back around; deciding on
        // the order from before it would be deciding twice.
        guard priorityOrder.order == order else { return }

        let resolution = OutputResolver.resolve(order: order, connected: devices, overrideUID: nil)
        guard case let .device(uid, reason) = resolution else {
            Self.log.info("None of the \(order.entries.count) devices in the priority order is connected, so the output is left alone")
            return
        }

        let outcome = DefaultOutputWriter.select(uid: uid)
        Self.log.info(
            """
            Output belongs on \(Self.describe(reason), privacy: .public) of \(order.entries.count), \
            with \(devices.count) connected: \(Self.describe(outcome), privacy: .public)
            """
        )
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
