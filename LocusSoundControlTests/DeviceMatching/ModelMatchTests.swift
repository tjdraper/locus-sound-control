import Testing

struct ModelMatchTests {
    private let dockModel = "CalDigit Thunderbolt 3 Audio:2188:6533"

    @Test
    func aDockOnANewPortKeepsItsEntry() {
        // Arrange
        var order = PriorityOrder.seeded(from: [device("dock-port-1", model: dockModel), device("speakers")], currentOutputUID: nil)

        // Act
        let recorded = order.record([device("dock-port-2", model: dockModel), device("speakers")])

        // Assert
        #expect(recorded == PriorityOrder.Recorded(recognized: 1, queued: 0))
        #expect(order.entries.map(\.uids) == [["dock-port-1", "dock-port-2"], ["speakers"]])
    }

    @Test
    func twoUnitsOfOneModelConnectedTogetherStayApart() {
        // Arrange
        var order = PriorityOrder.seeded(from: [device("display-1", model: "Studio Display:05AC:1118")], currentOutputUID: nil)

        // Act
        order.record([device("display-1", model: "Studio Display:05AC:1118"), device("display-2", model: "Studio Display:05AC:1118")])

        // Assert
        #expect(order.placed.map(\.uids) == [["display-1"]])
        #expect(order.queued.map(\.uids) == [["display-2"]])
    }

    @Test
    func twoNewUnitsArrivingTogetherClaimOnlyOneEntry() {
        // Arrange
        var order = PriorityOrder.seeded(from: [device("dock-port-1", model: dockModel)], currentOutputUID: nil)

        // Act
        order.record([device("dock-port-2", model: dockModel), device("dock-port-3", model: dockModel)])

        // Assert
        #expect(order.placed.map(\.uids) == [["dock-port-1", "dock-port-2"]])
        #expect(order.queued.map(\.uids) == [["dock-port-3"]])
    }

    @Test
    func aDeviceWithNoModelIsNeverMatched() {
        // Arrange
        let entries = [DeviceEntry(device: device("dell-1", model: nil))]

        // Act
        let index = ModelMatch.entryIndex(for: device("dell-2", model: nil), in: entries, connectedUIDs: ["dell-2"])

        // Assert
        #expect(index == nil)
    }

    @Test
    func theTransportHasToMatchAsWellAsTheModel() {
        // Arrange
        let entries = [DeviceEntry(device: device("usb", model: dockModel, transport: .usb))]

        // Act
        let index = ModelMatch.entryIndex(
            for: device("thunderbolt", model: dockModel, transport: .thunderbolt),
            in: entries,
            connectedUIDs: ["thunderbolt"]
        )

        // Assert
        #expect(index == nil)
    }

    @Test
    func aSecondPairOfTheSameHeadphonesIsANewDevice() {
        // Arrange
        let entries = [DeviceEntry(device: device("mine:output", model: "2014 4c", transport: .bluetooth))]

        // Act
        let index = ModelMatch.entryIndex(
            for: device("theirs:output", model: "2014 4c", transport: .bluetooth),
            in: entries,
            connectedUIDs: ["theirs:output"]
        )

        // Assert
        #expect(index == nil)
    }

    @Test
    func aHiddenDeviceStaysHiddenOnANewPort() {
        // Arrange
        var order = PriorityOrder.seeded(from: [device("dock-port-1", model: dockModel)], currentOutputUID: nil)
        order.setHidden(true, for: [order.entries[0].id])

        // Act
        order.record([device("dock-port-2", model: dockModel)])

        // Assert
        #expect(order.entries.count == 1)
        #expect(order.entries[0].isHidden)
    }

    private func device(_ uid: String, model: String?, transport: AudioDeviceTransport = .usb) -> AudioOutputDevice {
        AudioOutputDevice(uid: uid, name: uid, modelUID: model, transport: transport, symbolName: "hifispeaker")
    }

    private func device(_ uid: String) -> AudioOutputDevice {
        device(uid, model: nil)
    }
}
