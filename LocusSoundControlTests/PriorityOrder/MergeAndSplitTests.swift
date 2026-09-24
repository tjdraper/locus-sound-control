import Testing

struct MergeAndSplitTests {
    @Test
    func aMergedEntryKeepsTheHighestSlotAndEveryUID() {
        // Arrange
        var order = PriorityOrder.seeded(from: ["a", "dock-port-1", "b", "dock-port-2"].map { device($0) }, currentOutputUID: nil)
        let kept = order.entries[1].id

        // Act
        let merged = order.merge([order.entries[3].id, kept])

        // Assert
        #expect(merged == kept)
        #expect(order.entries.map(\.uids) == [["a"], ["dock-port-1", "dock-port-2"], ["b"]])
    }

    @Test
    func mergingWithAQueuedEntryPlacesIt() {
        // Arrange
        var order = PriorityOrder.seeded(from: [device("dock-port-1")], currentOutputUID: nil)
        order.record([device("dock-port-2")])

        // Act
        order.merge(Set(order.entries.map(\.id)))

        // Assert
        #expect(order.queued.isEmpty)
        #expect(order.placed.map(\.uids) == [["dock-port-1", "dock-port-2"]])
    }

    @Test
    func aMergedEntryIsHiddenOnlyIfEveryOneWas() {
        // Arrange
        var order = PriorityOrder.seeded(from: ["hidden", "visible", "also-hidden"].map { device($0) }, currentOutputUID: nil)
        order.setHidden(true, for: [order.entries[0].id, order.entries[2].id])
        var allHidden = order

        // Act
        order.merge([order.entries[0].id, order.entries[1].id])
        allHidden.merge([allHidden.entries[0].id, allHidden.entries[2].id])

        // Assert
        #expect(!order.entries[0].isHidden)
        #expect(allHidden.entries[0].isHidden)
    }

    @Test
    func aMergedEntryKeepsItsOwnIconOrTakesAnother() {
        // Arrange
        var order = PriorityOrder.seeded(from: ["a", "b", "c"].map { device($0) }, currentOutputUID: nil)
        order.assignSymbol("headphones", to: order.entries[1].id)
        order.assignSymbol("pianokeys", to: order.entries[2].id)
        var ownIcon = order
        ownIcon.assignSymbol("tv", to: ownIcon.entries[0].id)

        // Act
        order.merge(Set(order.entries.map(\.id)))
        ownIcon.merge(Set(ownIcon.entries.map(\.id)))

        // Assert
        #expect(order.entries[0].assignedSymbolName == "headphones")
        #expect(ownIcon.entries[0].assignedSymbolName == "tv")
    }

    @Test
    func mergingOneEntryDoesNothing() {
        // Arrange
        var order = PriorityOrder.seeded(from: ["a", "b"].map { device($0) }, currentOutputUID: nil)
        let before = order

        // Act
        let merged = order.merge([order.entries[0].id])

        // Assert
        #expect(merged == nil)
        #expect(order == before)
    }

    @Test
    func splittingGivesEachUIDAnEntryBelowTheOriginal() {
        // Arrange
        var order = PriorityOrder.seeded(from: ["a", "dock-port-1", "b"].map { device($0) }, currentOutputUID: nil)
        order.entries[1].uids = ["dock-port-1", "dock-port-2", "dock-port-3"]
        order.assignSymbol("pianokeys", to: order.entries[1].id)
        let original = order.entries[1].id

        // Act
        let splitOff = order.split(original, keepingUID: "dock-port-2")

        // Assert
        #expect(order.entries.map(\.uids) == [["a"], ["dock-port-2"], ["dock-port-1"], ["dock-port-3"], ["b"]])
        #expect(order.entries[1].id == original)
        #expect(splitOff == [order.entries[2].id, order.entries[3].id])
        #expect(order.entries[1...3].allSatisfy { $0.assignedSymbolName == "pianokeys" })
    }

    @Test
    func aSplitDeviceIsNotFoldedBackOnItsNextConnection() {
        // Arrange
        var order = PriorityOrder(entries: [DeviceEntry(device: device("display-1", model: "Studio Display:05AC:1118"))])
        order.entries[0].uids.insert("display-2")
        order.split(order.entries[0].id, keepingUID: nil)

        // Act
        order.record([device("display-2", model: "Studio Display:05AC:1118")])

        // Assert
        #expect(order.entries.map(\.uids) == [["display-1"], ["display-2"]])
    }

    private func device(_ uid: String, model: String? = nil) -> AudioOutputDevice {
        AudioOutputDevice(uid: uid, name: uid, modelUID: model, transport: .usb, symbolName: "hifispeaker")
    }
}
