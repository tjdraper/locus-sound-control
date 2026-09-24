import Foundation
import SwiftUI

/// The selection in the Sound Devices window and the commands that act on it. Held outside the
/// view so that the File menu, which is AppKit, sees the same selection the list does.
@Observable
final class DeviceCommandCoordinator {
    var selection: Set<DeviceEntry.ID> = []

    /// The device whose icon picker is open.
    var choosingIconFor: DeviceEntry.ID?

    /// The devices waiting on the user to confirm forgetting them.
    var forgetting: Set<DeviceEntry.ID> = []

    @ObservationIgnored private let outputDevices: OutputDeviceInventory
    @ObservationIgnored private let priorityOrder: PriorityOrderStore
    @ObservationIgnored private let override: OverrideStore

    init(outputDevices: OutputDeviceInventory, priorityOrder: PriorityOrderStore, override: OverrideStore) {
        self.outputDevices = outputDevices
        self.priorityOrder = priorityOrder
        self.override = override
    }

    func groups(for ids: Set<DeviceEntry.ID>) -> [[DeviceCommand]] {
        let chosen = priorityOrder.order.entries.filter { ids.contains($0.id) }
        let connected = chosen.filter { connectedDevice(for: $0) != nil }.map(\.id)
        return DeviceCommand.groups(for: chosen, connected: Set(connected))
    }

    func perform(_ command: DeviceCommand) {
        switch command {
        case let .changeIcon(id): choosingIconFor = id
        case let .hide(ids): hide(ids)
        case let .unhide(ids): priorityOrder.setHidden(false, for: ids)
        case let .forget(ids): forgetting = ids
        }
    }

    func chooseIcon(_ symbolName: String?, for id: DeviceEntry.ID) {
        priorityOrder.assignSymbol(symbolName, to: id)
        choosingIconFor = nil
    }

    func confirmForget() {
        priorityOrder.forget(forgetting)
        selection.subtract(forgetting)
        forgetting = []
    }

    /// A double-click, and the same toggle as choosing the device again in the menu.
    func toggleOverride(_ ids: Set<DeviceEntry.ID>) {
        guard ids.count == 1,
              let entry = priorityOrder.order.entries.first(where: { ids.contains($0.id) }),
              let device = connectedDevice(for: entry)
        else { return }
        if device.uid == override.uid {
            override.cancel()
        } else {
            override.set(device.uid)
        }
    }

    func connectedDevice(for entry: DeviceEntry) -> AudioOutputDevice? {
        outputDevices.devices.first { entry.uids.contains($0.uid) }
    }

    /// Hiding a device says "not this one", so an override holding the sound on it is cancelled
    /// with it. Choosing a hidden device afterwards still sets one, here or in Control Center.
    private func hide(_ ids: Set<DeviceEntry.ID>) {
        priorityOrder.setHidden(true, for: ids)
        if let overrideUID = override.uid, let overridden = priorityOrder.order.entry(forUID: overrideUID), ids.contains(overridden.id) {
            override.cancel()
        }
    }
}
