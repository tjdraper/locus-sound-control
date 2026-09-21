import CoreAudio
import IOBluetooth
import Testing

struct OutputDeviceSymbolTests {
    @Test
    func builtInSpeakersTakeTheShapeOfTheMac() {
        // Arrange, Act
        let symbol = OutputDeviceSymbol.name(for: .builtIn, modelUID: "Speaker", bluetoothKind: nil, builtInSpeakers: "laptopcomputer")

        // Assert
        #expect(symbol == "laptopcomputer")
    }

    @Test
    func transportsThatSayNothingAboutTheDeviceGetAPlainSpeaker() {
        // Arrange
        let uninformative: [AudioDeviceTransport] = [.usb, .thunderbolt, .aggregate, .unknown]

        // Act
        let symbols = uninformative.map {
            OutputDeviceSymbol.name(for: $0, modelUID: nil, bluetoothKind: nil, builtInSpeakers: "laptopcomputer")
        }

        // Assert
        #expect(symbols.allSatisfy { $0 == OutputDeviceSymbol.generic })
    }

    @Test
    func aTransportWithAShapeGetsThatShape() {
        // Arrange, Act, Assert
        #expect(OutputDeviceSymbol.name(for: .bluetooth, modelUID: nil, bluetoothKind: nil, builtInSpeakers: "") == "headphones")
        #expect(OutputDeviceSymbol.name(for: .hdmi, modelUID: nil, bluetoothKind: nil, builtInSpeakers: "") == "display")
        #expect(OutputDeviceSymbol.name(for: .displayPort, modelUID: nil, bluetoothKind: nil, builtInSpeakers: "") == "display")
        #expect(OutputDeviceSymbol.name(for: .airPlay, modelUID: nil, bluetoothKind: nil, builtInSpeakers: "") == "airplayaudio")
        #expect(OutputDeviceSymbol.name(for: .virtual, modelUID: nil, bluetoothKind: nil, builtInSpeakers: "") == "waveform")
    }

    @Test
    func bothBluetoothTransportsAreOneKind() {
        // Arrange, Act
        let classic = AudioDeviceTransport(rawTransport: kAudioDeviceTransportTypeBluetooth)
        let lowEnergy = AudioDeviceTransport(rawTransport: kAudioDeviceTransportTypeBluetoothLE)

        // Assert
        #expect(classic == .bluetooth)
        #expect(lowEnergy == .bluetooth)
    }

    @Test
    func anUnmappedTransportCodeIsUnknown() {
        // Arrange, Act
        let transport = AudioDeviceTransport(rawTransport: 0x7A7A_7A7A)

        // Assert
        #expect(transport == .unknown)
    }

    @Test
    func aKnownModelBeatsWhatTheTransportSays() {
        // Arrange
        let studioDisplay = "Studio Display Audio Control:05AC:1118"

        // Act
        let symbol = OutputDeviceSymbol.name(for: .usb, modelUID: studioDisplay, bluetoothKind: nil, builtInSpeakers: "")

        // Assert
        #expect(symbol == "display")
    }

    @Test
    func anUnknownModelFallsBackToTheTransport() {
        // Arrange
        let dock = "CalDigit Thunderbolt 3 Audio:2188:6533"

        // Act
        let symbol = OutputDeviceSymbol.name(for: .usb, modelUID: dock, bluetoothKind: nil, builtInSpeakers: "")

        // Assert
        #expect(symbol == OutputDeviceSymbol.generic)
    }

    @Test
    func theClassOfDeviceTellsABluetoothSpeakerFromHeadphones() {
        // Arrange, Act
        let speaker = OutputDeviceSymbol.name(
            for: .bluetooth, modelUID: nil, bluetoothKind: .speaker, builtInSpeakers: ""
        )
        let car = OutputDeviceSymbol.name(
            for: .bluetooth, modelUID: nil, bluetoothKind: .car, builtInSpeakers: ""
        )

        // Assert
        #expect(speaker == "hifispeaker")
        #expect(car == "car")
    }

    @Test
    func aKnownModelBeatsTheClassOfDevice() {
        // Arrange, Act
        let symbol = OutputDeviceSymbol.name(
            for: .bluetooth, modelUID: "2014 4c", bluetoothKind: .headphones, builtInSpeakers: ""
        )

        // Assert
        #expect(symbol == "airpods.pro")
    }

    /// The identifiers are macOS's own, so these also fail if a future macOS drops the type or
    /// stops tagging it, which is the assumption worth being told about.
    @Test(arguments: [
        ("2002 4c", "airpods"), // AirPods (1st generation)
        ("2013 4c", "airpods"), // AirPods (3rd generation)
        ("2019 4c", "airpods"), // AirPods 4
        ("200e 4c", "airpods.pro"), // AirPods Pro
        ("2014 4c", "airpods.pro"), // AirPods Pro (2nd generation)
        ("2024 4c", "airpods.pro"), // AirPods Pro (2nd generation, USB-C)
        ("200a 4c", "airpods.max"), // AirPods Max
        ("201f 4c", "airpods.max"), // AirPods Max (USB-C)
    ])
    func everyAirPodsLineIsToldApart(modelUID: String, expected: String) {
        // Arrange, Act
        let symbol = AppleAccessorySymbol.name(forModelUID: modelUID)

        // Assert
        #expect(symbol == expected)
    }

    @Test
    func beatsAreLeftToTheClassOfDeviceBecauseAppleFilesTheirSpeakersAsHeadphones() {
        // Arrange
        let beatsPill = "201a 4c" // a speaker Apple files under com.apple.beats-headphones

        // Act
        let symbol = AppleAccessorySymbol.name(forModelUID: beatsPill)

        // Assert
        #expect(symbol == nil)
    }

    @Test
    func aModelIdentifierOutsideTheCatalogIsNotGuessedAt() {
        // Arrange, Act
        let unknownProduct = AppleAccessorySymbol.name(forModelUID: "ffff 4c")
        let notBluetooth = AppleAccessorySymbol.name(forModelUID: "Studio Display Audio Control:05AC:1118")

        // Assert
        #expect(unknownProduct == nil)
        #expect(notBluetooth == nil)
    }

    @Test
    func aBluetoothDeviceWithNoUsableClassStillGetsHeadphones() {
        // Arrange, Act
        let symbol = OutputDeviceSymbol.name(
            for: .bluetooth, modelUID: nil, bluetoothKind: nil, builtInSpeakers: ""
        )

        // Assert
        #expect(symbol == "headphones")
    }

    @Test
    func handsFreeIsNotClassifiedBecauseItSaysNothingUseful() {
        // Arrange, Act
        let handsFree = BluetoothAudioKind(minorClass: BluetoothDeviceClassMinor(kBluetoothDeviceClassMinorAudioHandsFree))
        let headphones = BluetoothAudioKind(minorClass: BluetoothDeviceClassMinor(kBluetoothDeviceClassMinorAudioHeadphones))

        // Assert
        #expect(handsFree == nil)
        #expect(headphones == .headphones)
    }
}
