import Foundation
import OSLog
import SwiftUI

/// The priority order as the user arranged it, saved in `UserDefaults`.
@Observable
final class PriorityOrderStore {
    private(set) var order: PriorityOrder

    @ObservationIgnored private let defaults: UserDefaults

    /// Only a Mac that has never saved an order is seeded. An empty saved order is still the
    /// user's, and the devices that arrive after it go to the new device queue.
    @ObservationIgnored private var hasSavedOrder: Bool

    private static let key = "PriorityOrder"
    private static let log = Logger(subsystem: "com.buzzingpixel.LocusSoundControl", category: "PriorityOrder")

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        guard let data = defaults.data(forKey: Self.key) else {
            order = PriorityOrder(entries: [])
            hasSavedOrder = false
            return
        }

        do {
            order = PriorityOrder(entries: try JSONDecoder().decode([DeviceEntry].self, from: data))
            hasSavedOrder = true
        } catch {
            Self.log.error("The saved priority order could not be read, so it starts again: \(error, privacy: .public)")
            order = PriorityOrder(entries: [])
            hasSavedOrder = false
        }
    }

    func record(_ connected: [AudioOutputDevice], currentOutputUID: String?) {
        guard hasSavedOrder else {
            order = .seeded(from: connected, currentOutputUID: currentOutputUID)
            Self.log.info("Seeded the priority order from \(connected.count) connected outputs")
            save()
            return
        }

        var next = order
        next.record(connected)
        // Assigning an equal order would still wake everything observing it, the switching engine included.
        guard next != order else { return }

        let added = next.entries.count - order.entries.count
        order = next
        if added > 0 { Self.log.info("Queued \(added) new outputs") }
        save()
    }

    func movePlaced(fromOffsets source: IndexSet, toOffset destination: Int) {
        order.movePlaced(fromOffsets: source, toOffset: destination)
        save()
    }

    func place(_ id: DeviceEntry.ID, atPlacedOffset offset: Int) {
        order.place(id, atPlacedOffset: offset)
        Self.log.info("Placed a queued device at priority \(offset + 1) of \(self.order.placed.count)")
        save()
    }

    func setHidden(_ isHidden: Bool, for ids: Set<DeviceEntry.ID>) {
        order.setHidden(isHidden, for: ids)
        Self.log.info("\(isHidden ? "Hid" : "Unhid", privacy: .public) \(ids.count) devices")
        save()
    }

    func assignSymbol(_ symbolName: String?, to id: DeviceEntry.ID) {
        order.assignSymbol(symbolName, to: id)
        save()
    }

    func forget(_ ids: Set<DeviceEntry.ID>) {
        order.forget(ids)
        Self.log.info("Forgot \(ids.count) devices")
        save()
    }

    private func save() {
        do {
            defaults.set(try JSONEncoder().encode(order.entries), forKey: Self.key)
            hasSavedOrder = true
        } catch {
            Self.log.error("The priority order could not be saved: \(error, privacy: .public)")
        }
    }
}
