import Foundation
import Testing

struct PriorityOrderSyncMergeTests {
    private let agreed = PriorityOrder.seeded(from: ["speakers", "dock", "airpods"].map { device($0) }, currentOutputUID: nil)

    @Test
    func aDeviceHiddenElsewhereIsHiddenHere() {
        // Arrange
        var cloud = agreed
        cloud.setHidden(true, for: [agreed.entries[1].id])

        // Act
        let outcome = merge(local: agreed, cloud: SyncedOrder(cloud), base: SyncedOrder(agreed))

        // Assert
        #expect(outcome.local == cloud)
        #expect(outcome.cloudChanges.isEmpty)
    }

    @Test
    func aChangeHereIsSentToICloud() {
        // Arrange
        var local = agreed
        local.assignSymbol("headphones", to: agreed.entries[2].id)

        // Act
        let outcome = merge(local: local, cloud: SyncedOrder(agreed), base: SyncedOrder(agreed))

        // Assert
        #expect(outcome.local == local)
        #expect(outcome.cloudChanges == .init(writes: [local.entries[2]]))
    }

    @Test
    func changesToDifferentDevicesOnTwoMacsBothHold() {
        // Arrange
        var local = agreed
        local.setHidden(true, for: [agreed.entries[0].id])
        var cloud = agreed
        cloud.assignSymbol("headphones", to: agreed.entries[2].id)

        // Act
        let outcome = merge(local: local, cloud: SyncedOrder(cloud), base: SyncedOrder(agreed))

        // Assert
        #expect(outcome.local.entries[0].isHidden)
        #expect(outcome.local.entries[2].assignedSymbolName == "headphones")
        #expect(outcome.cloudChanges == .init(writes: [local.entries[0]]))
    }

    @Test
    func whenBothMacsChangedOneDeviceICloudWins() {
        // Arrange
        var local = agreed
        local.assignSymbol("tv", to: agreed.entries[1].id)
        var cloud = agreed
        cloud.assignSymbol("display", to: agreed.entries[1].id)

        // Act
        let outcome = merge(local: local, cloud: SyncedOrder(cloud), base: SyncedOrder(agreed))

        // Assert
        #expect(outcome.local.entries[1].assignedSymbolName == "display")
        #expect(outcome.cloudChanges.isEmpty)
    }

    @Test
    func aDeviceForgottenElsewhereIsForgottenHere() {
        // Arrange
        var cloud = agreed
        cloud.forget([agreed.entries[1].id])

        // Act
        let outcome = merge(local: agreed, cloud: SyncedOrder(cloud), base: SyncedOrder(agreed))

        // Assert
        #expect(outcome.local.entries.map(\.uids) == [["speakers"], ["airpods"]])
        #expect(outcome.cloudChanges.isEmpty)
    }

    @Test
    func aDeviceChangedHereAndForgottenElsewhereIsKept() {
        // Arrange
        var local = agreed
        local.setHidden(true, for: [agreed.entries[1].id])
        var cloud = agreed
        cloud.forget([agreed.entries[1].id])

        // Act
        let outcome = merge(local: local, cloud: SyncedOrder(cloud), base: SyncedOrder(agreed))

        // Assert
        #expect(outcome.local.entries.map(\.uids) == [["speakers"], ["airpods"], ["dock"]])
        #expect(outcome.cloudChanges.writes == [local.entries[1]])
    }

    @Test
    func aReorderElsewhereIsTaken() {
        // Arrange
        var cloud = agreed
        cloud.movePlaced(fromOffsets: [2], toOffset: 0)

        // Act
        let outcome = merge(local: agreed, cloud: SyncedOrder(cloud), base: SyncedOrder(agreed))

        // Assert
        #expect(outcome.local == cloud)
        #expect(outcome.cloudChanges.isEmpty)
    }

    @Test
    func whenBothMacsChangedTheOrderICloudsWinsAndADeviceNewHereGoesAfterIt() {
        // Arrange
        var local = agreed
        local.record([device("headset")])
        var cloud = agreed
        cloud.movePlaced(fromOffsets: [2], toOffset: 0)

        // Act
        let outcome = merge(local: local, cloud: SyncedOrder(cloud), base: SyncedOrder(agreed))

        // Assert
        #expect(outcome.local.entries.map(\.uids) == [["airpods"], ["speakers"], ["dock"], ["headset"]])
        #expect(outcome.cloudChanges.writes == [local.entries[3]])
        #expect(outcome.cloudChanges.order == outcome.local.entries.map(\.id))
    }

    @Test
    func aNameThatDiffersBetweenMacsIsNeitherTakenNorSent() {
        // Arrange
        var cloud = agreed
        cloud.entries[0].name = "iMac Speakers"

        // Act
        let outcome = merge(local: agreed, cloud: SyncedOrder(cloud), base: SyncedOrder(agreed))

        // Assert
        #expect(outcome.local == agreed)
        #expect(outcome.cloudChanges.isEmpty)
    }

    @Test
    func aSeedIsReplacedByTheOrderInICloud() {
        // Arrange
        let seed = PriorityOrder.seeded(from: ["speakers", "display"].map { device($0) }, currentOutputUID: nil)

        // Act
        let outcome = merge(local: seed, isSeed: true, cloud: SyncedOrder(agreed), base: nil)

        // Assert
        #expect(outcome.replacedSeed)
        #expect(outcome.local == agreed)
        #expect(outcome.cloudChanges.isEmpty)
    }

    @Test
    func aSeedIsMergedOnceItHasSynced() {
        // Arrange
        var cloud = agreed
        cloud.forget([agreed.entries[2].id])

        // Act
        let outcome = merge(local: agreed, isSeed: true, cloud: SyncedOrder(cloud), base: SyncedOrder(agreed))

        // Assert
        #expect(!outcome.replacedSeed)
        #expect(outcome.local == cloud)
    }

    @Test
    func twoOrdersMeetingForTheFirstTimeKeepEveryDeviceWithICloudsOrderFirst() {
        // Arrange
        let local = PriorityOrder(entries: ["display", "speakers"].map { DeviceEntry(device: device($0), id: UUID()) })
        let cloud = PriorityOrder(entries: ["speakers", "dock"].map { DeviceEntry(device: device($0), id: UUID()) })

        // Act
        let outcome = merge(local: local, cloud: SyncedOrder(cloud), base: nil)

        // Assert
        #expect(outcome.local.entries.map(\.uids) == [["speakers"], ["dock"], ["display"]])
        #expect(outcome.local.entries.map(\.id) == [cloud.entries[0].id, cloud.entries[1].id, local.entries[0].id])
        #expect(outcome.cloudChanges.writes == [local.entries[0]])
        #expect(outcome.cloudChanges.order == outcome.local.entries.map(\.id))
    }

    @Test
    func twoEntriesHoldingOneUIDAreFoldedIntoTheHigherOne() {
        // Arrange
        var local = agreed
        local.entries.append(DeviceEntry(device: device("dock-port-2"), id: UUID()))
        var cloud = local
        cloud.entries[1].uids.insert("dock-port-2")

        // Act
        let outcome = merge(local: local, cloud: SyncedOrder(cloud), base: SyncedOrder(local))

        // Assert
        #expect(outcome.local.entries.map(\.uids) == [["speakers"], ["dock", "dock-port-2"], ["airpods"]])
        #expect(outcome.cloudChanges == .init(removals: [local.entries[3].id], order: outcome.local.entries.map(\.id)))
    }

    @Test
    func anEmptyOrderIsNotWrittenToAnEmptyICloud() {
        // Act
        let outcome = merge(local: PriorityOrder(entries: []), isSeed: true, cloud: .empty, base: nil)

        // Assert
        #expect(outcome.cloudChanges.isEmpty)
    }

    private func merge(
        local: PriorityOrder,
        isSeed: Bool = false,
        cloud: SyncedOrder,
        base: SyncedOrder?
    ) -> PriorityOrderSyncMerge.Outcome {
        PriorityOrderSyncMerge(local: local, localIsSeed: isSeed, cloud: cloud, base: base).run()
    }
}

private func device(_ uid: String) -> AudioOutputDevice {
    AudioOutputDevice(uid: uid, name: uid, modelUID: nil, transport: .usb, symbolName: "hifispeaker")
}
