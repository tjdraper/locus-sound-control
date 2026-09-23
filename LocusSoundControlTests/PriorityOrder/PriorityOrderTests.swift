import Foundation
import Testing

struct PriorityOrderTests {
    @Test
    func seedingPutsTheCurrentOutputFirst() {
        // Arrange
        let connected = [device("speakers"), device("display"), device("airpods")]

        // Act
        let order = PriorityOrder.seeded(from: connected, currentOutputUID: "display")

        // Assert
        #expect(order.entries.map(\.uids) == [["display"], ["speakers"], ["airpods"]])
    }

    @Test
    func seedingWithNoCurrentOutputKeepsTheListedOrder() {
        // Arrange
        let connected = [device("speakers"), device("display")]

        // Act
        let order = PriorityOrder.seeded(from: connected, currentOutputUID: nil)

        // Assert
        #expect(order.entries.map(\.uids) == [["speakers"], ["display"]])
    }

    @Test
    func aDeviceNeverSeenBeforeGoesToTheBottom() {
        // Arrange
        var order = PriorityOrder.seeded(from: [device("speakers"), device("display")], currentOutputUID: "display")

        // Act
        order.record([device("speakers"), device("airpods")])

        // Assert
        #expect(order.entries.map(\.uids) == [["display"], ["speakers"], ["airpods"]])
    }

    @Test
    func aKnownDeviceKeepsItsPlaceAndPicksUpItsNewName() {
        // Arrange
        var order = PriorityOrder.seeded(from: [device("speakers"), device("airpods")], currentOutputUID: "airpods")
        let id = order.entries[0].id

        // Act
        order.record([device("airpods", name: "Renamed AirPods")])

        // Assert
        #expect(order.entries[0].id == id)
        #expect(order.entries[0].name == "Renamed AirPods")
        #expect(order.entries.count == 2)
    }

    @Test
    func anAssignedSymbolWinsOverTheGuessedOne() {
        // Arrange
        var entry = DeviceEntry(device: device("speakers"))

        // Act
        entry.assignedSymbolName = "pianokeys"

        // Assert
        #expect(entry.symbolName == "pianokeys")
    }

    @Test
    func devicesAreListedInPriorityOrderWithUnknownOnesLast() {
        // Arrange
        let order = PriorityOrder.seeded(from: [device("display"), device("speakers")], currentOutputUID: nil)
        let connected = [device("unknown"), device("speakers"), device("display")]

        // Act
        let sorted = order.inPriorityOrder(connected)

        // Assert
        #expect(sorted.map(\.uid) == ["display", "speakers", "unknown"])
    }

    @Test
    func anEntryIsFoundByAnyOfItsUIDs() {
        // Arrange
        var entry = DeviceEntry(device: device("dock-port-1"))
        entry.uids.insert("dock-port-2")
        let order = PriorityOrder(entries: [DeviceEntry(device: device("speakers")), entry])

        // Act
        let index = order.index(ofUID: "dock-port-2")

        // Assert
        #expect(index == 1)
    }

    @Test
    func anEntrySurvivesBeingSavedAndReadBack() throws {
        // Arrange
        var entry = DeviceEntry(device: device("airpods"))
        entry.assignedSymbolName = "headphones"

        // Act
        let data = try JSONEncoder().encode([entry])
        let decoded = try JSONDecoder().decode([DeviceEntry].self, from: data)

        // Assert
        #expect(decoded == [entry])
    }

    private func device(_ uid: String, name: String? = nil) -> AudioOutputDevice {
        AudioOutputDevice(uid: uid, name: name ?? uid, modelUID: nil, transport: .usb, symbolName: "hifispeaker")
    }
}
