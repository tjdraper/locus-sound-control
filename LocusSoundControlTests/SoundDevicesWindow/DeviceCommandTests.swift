import Testing

struct DeviceCommandTests {
    @Test
    func oneDeviceIsNamedWithoutACount() {
        // Arrange
        let entry = entry("speakers")

        // Act
        let titles = titles(for: [entry], connected: [])

        // Assert
        #expect(titles == [["Change Icon…"], ["Hide Sound Device"], ["Forget Sound Device…"]])
    }

    @Test
    func severalDevicesAreCountedAndCannotShareAnIcon() {
        // Arrange
        let entries = [entry("a"), entry("b"), entry("c")]

        // Act
        let titles = titles(for: entries, connected: [])

        // Assert
        #expect(titles == [["Hide 3 Sound Devices"], ["Forget 3 Sound Devices…"]])
    }

    @Test
    func aMixedSelectionCountsWhatEachCommandWouldChange() {
        // Arrange
        let visible = entry("visible")
        var hidden = [entry("hidden-1"), entry("hidden-2")]
        for index in hidden.indices {
            hidden[index].isHidden = true
        }

        // Act
        let titles = titles(for: [visible] + hidden, connected: [visible.id])

        // Assert
        #expect(titles == [["Hide Sound Device", "Unhide 2 Sound Devices"]])
    }

    @Test
    func forgetIsNotOfferedWhileAnySelectedDeviceIsConnected() {
        // Arrange
        let connected = entry("connected")
        let gone = entry("gone")

        // Act
        let commands = DeviceCommand.groups(for: [connected, gone], connected: [connected.id]).flatMap(\.self)

        // Assert
        #expect(!commands.contains(.forget([connected.id, gone.id])))
    }

    @Test
    func aQueuedDeviceCanBeAddedToThePriorityOrder() {
        // Arrange
        var queued = entry("queued")
        queued.isQueued = true
        let placed = entry("placed")

        // Act
        let titles = titles(for: [queued, placed], connected: [queued.id, placed.id])

        // Assert
        #expect(titles == [["Add Sound Device to Priority Order"], ["Hide 2 Sound Devices"]])
    }

    @Test
    func nothingSelectedOffersNothing() {
        // Act
        let groups = DeviceCommand.groups(for: [], connected: [])

        // Assert
        #expect(groups.isEmpty)
    }

    private func titles(for entries: [DeviceEntry], connected: Set<DeviceEntry.ID>) -> [[String]] {
        DeviceCommand.groups(for: entries, connected: connected).map { $0.map(\.title) }
    }

    private func entry(_ uid: String) -> DeviceEntry {
        DeviceEntry(device: AudioOutputDevice(uid: uid, name: uid, modelUID: nil, transport: .usb, symbolName: "hifispeaker"))
    }
}
