import Testing

struct OutputResolverTests {
    private let order = PriorityOrder(entries: ["airpods", "display", "speakers"].map {
        DeviceEntry(device: device($0))
    })

    @Test
    func theHighestConnectedDeviceWins() {
        // Arrange
        let connected = [device("speakers"), device("display")]

        // Act
        let resolution = OutputResolver.resolve(order: order, connected: connected, overrideUID: nil)

        // Assert
        #expect(resolution == .device(uid: "display", reason: .priority(index: 1)))
    }

    @Test
    func aHiddenDeviceIsPassedOver() {
        // Arrange
        var order = order
        order.entries[0].isHidden = true
        let connected = [device("airpods"), device("speakers")]

        // Act
        let resolution = OutputResolver.resolve(order: order, connected: connected, overrideUID: nil)

        // Assert
        #expect(resolution == .device(uid: "speakers", reason: .priority(index: 2)))
    }

    @Test
    func anOverrideWinsOverPriority() {
        // Arrange
        let connected = [device("airpods"), device("speakers")]

        // Act
        let resolution = OutputResolver.resolve(order: order, connected: connected, overrideUID: "speakers")

        // Assert
        #expect(resolution == .device(uid: "speakers", reason: .override))
    }

    @Test
    func anOverrideOnADeviceThatIsGoneIsIgnored() {
        // Arrange
        let connected = [device("display"), device("speakers")]

        // Act
        let resolution = OutputResolver.resolve(order: order, connected: connected, overrideUID: "airpods")

        // Assert
        #expect(resolution == .device(uid: "display", reason: .priority(index: 1)))
    }

    @Test
    func theSystemIsLeftAloneWhenNothingListedIsConnected() {
        // Arrange
        let connected = [device("unlisted")]

        // Act
        let resolution = OutputResolver.resolve(order: order, connected: connected, overrideUID: nil)

        // Assert
        #expect(resolution == .leaveAlone)
    }

    @Test
    func anEntryResolvesToWhicheverOfItsUIDsIsConnected() {
        // Arrange
        var dock = DeviceEntry(device: device("dock-port-1"))
        dock.uids.insert("dock-port-2")
        let order = PriorityOrder(entries: [dock])

        // Act
        let resolution = OutputResolver.resolve(order: order, connected: [device("dock-port-2")], overrideUID: nil)

        // Assert
        #expect(resolution == .device(uid: "dock-port-2", reason: .priority(index: 0)))
    }
}

private func device(_ uid: String) -> AudioOutputDevice {
    AudioOutputDevice(uid: uid, name: uid, modelUID: nil, transport: .usb, symbolName: "hifispeaker")
}
