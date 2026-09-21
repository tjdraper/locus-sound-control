import CoreAudio
import Testing

struct OutputDeviceSymbolTests {
    @Test
    func builtInSpeakersTakeTheShapeOfTheMac() {
        // Arrange, Act
        let symbol = OutputDeviceSymbol.name(for: .builtIn, modelUID: "Speaker", builtInSpeakers: "laptopcomputer")

        // Assert
        #expect(symbol == "laptopcomputer")
    }

    @Test
    func transportsThatSayNothingAboutTheDeviceGetAPlainSpeaker() {
        // Arrange
        let uninformative: [AudioDeviceTransport] = [.usb, .thunderbolt, .aggregate, .unknown]

        // Act
        let symbols = uninformative.map { OutputDeviceSymbol.name(for: $0, modelUID: nil, builtInSpeakers: "laptopcomputer") }

        // Assert
        #expect(symbols.allSatisfy { $0 == OutputDeviceSymbol.generic })
    }

    @Test
    func aTransportWithAShapeGetsThatShape() {
        // Arrange, Act, Assert
        #expect(OutputDeviceSymbol.name(for: .bluetooth, modelUID: nil, builtInSpeakers: "") == "headphones")
        #expect(OutputDeviceSymbol.name(for: .hdmi, modelUID: nil, builtInSpeakers: "") == "display")
        #expect(OutputDeviceSymbol.name(for: .displayPort, modelUID: nil, builtInSpeakers: "") == "display")
        #expect(OutputDeviceSymbol.name(for: .airPlay, modelUID: nil, builtInSpeakers: "") == "airplayaudio")
        #expect(OutputDeviceSymbol.name(for: .virtual, modelUID: nil, builtInSpeakers: "") == "waveform")
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
        let symbol = OutputDeviceSymbol.name(for: .usb, modelUID: studioDisplay, builtInSpeakers: "")

        // Assert
        #expect(symbol == "display")
    }

    @Test
    func anUnknownModelFallsBackToTheTransport() {
        // Arrange
        let dock = "CalDigit Thunderbolt 3 Audio:2188:6533"

        // Act
        let symbol = OutputDeviceSymbol.name(for: .usb, modelUID: dock, builtInSpeakers: "")

        // Assert
        #expect(symbol == OutputDeviceSymbol.generic)
    }
}
