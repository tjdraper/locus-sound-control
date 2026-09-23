import Testing

struct OutsideChangeAdoptionTests {
    private let order = PriorityOrder(entries: ["airpods", "display", "speakers"].map {
        DeviceEntry(device: device($0))
    })

    private let longSettled = Duration.seconds(60)

    @Test
    func aChangeMadeOutsideTheAppIsAdopted() {
        // Act
        let decision = decide(current: "speakers", expected: "display", sinceSettle: longSettled)

        // Assert
        #expect(decision == .adopt(.outsideChange))
    }

    @Test
    func theAppsOwnWriteIsNotAdopted() {
        // Act
        let decision = decide(current: "display", expected: "display", sinceSettle: longSettled)

        // Assert
        #expect(decision == .nothingToAdopt)
    }

    @Test
    func theOutputAlreadyOverriddenIsNotAdoptedAgain() {
        // Act
        let decision = decide(current: "speakers", expected: "display", override: "speakers", sinceSettle: longSettled)

        // Assert
        #expect(decision == .nothingToAdopt)
    }

    @Test
    func nothingIsAdoptedBeforeTheAppHasDecidedAnything() {
        // Act
        let decision = decide(current: "speakers", expected: nil, sinceSettle: longSettled)

        // Assert
        #expect(decision == .nothingToAdopt)
    }

    @Test
    func anOutputThatIsNotAConnectedDeviceIsNotAdopted() {
        // Act
        let decision = OutsideChangeAdoption.decide(
            current: nil,
            expectedUID: "display",
            overrideUID: nil,
            order: order,
            sinceSettle: longSettled
        )

        // Assert
        #expect(decision == .nothingToAdopt)
    }

    @Test
    func aChangeJustAfterTheListSettledIsLeftToPriority() {
        // Act
        let decision = decide(current: "speakers", expected: "airpods", sinceSettle: .milliseconds(200))

        // Assert
        #expect(decision == .leaveToPriority)
    }

    @Test
    func aChangeBeforeTheListHasEverSettledIsAdopted() {
        // Act
        let decision = decide(current: "speakers", expected: "display", sinceSettle: nil)

        // Assert
        #expect(decision == .adopt(.outsideChange))
    }

    @Test
    func aKnownDeviceArrivingDoesNotTakeOverAnOverride() {
        // Act
        let decision = decide(current: "airpods", expected: "speakers", override: "speakers", sinceSettle: .zero)

        // Assert
        #expect(decision == .leaveToPriority)
    }

    @Test
    func aDeviceNeverSeenBeforeIsAdoptedEvenAsTheListSettles() {
        // Act
        let decision = decide(current: "headset", expected: "speakers", override: "speakers", sinceSettle: .zero)

        // Assert
        #expect(decision == .adopt(.newDevice))
    }

    private func decide(
        current: String,
        expected: String?,
        override: String? = nil,
        sinceSettle: Duration?
    ) -> OutsideChangeAdoption.Decision {
        OutsideChangeAdoption.decide(
            current: device(current),
            expectedUID: expected,
            overrideUID: override,
            order: order,
            sinceSettle: sinceSettle
        )
    }
}

private func device(_ uid: String) -> AudioOutputDevice {
    AudioOutputDevice(uid: uid, name: uid, modelUID: nil, transport: .usb, symbolName: "hifispeaker")
}
