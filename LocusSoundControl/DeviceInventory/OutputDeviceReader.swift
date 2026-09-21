import CoreAudio
import Foundation

/// Reads the connected output devices and the current one out of CoreAudio.
nonisolated enum OutputDeviceReader {
    /// Sorted by name, because CoreAudio's own order is not stable and an unstable order would
    /// look like a device list change to `OutputDeviceInventory`.
    static func connectedOutputs() -> [AudioOutputDevice] {
        let builtInSpeakers = BuiltInSpeakerSymbol.name
        let outputs = allDeviceIDs().filter { hasOutputBuffers($0) && !isHidden($0) }

        // Reading the paired devices is what raises the Bluetooth permission prompt. Slice 9's
        // setup checklist asks for it up front, but only a fresh install sees that, so this is
        // the fallback: ask when there is a Bluetooth device to ask about, and never on a Mac
        // that has none.
        let anyBluetooth = outputs.contains { AudioDeviceTransport(rawTransport: transport($0)) == .bluetooth }
        let bluetooth = anyBluetooth ? PairedBluetoothAudio() : nil

        return outputs
            .compactMap { id -> AudioOutputDevice? in
                // The UID is how a connected device is identified, so one without it is no use.
                guard let uid = string(id, kAudioDevicePropertyDeviceUID) else { return nil }

                let transport = AudioDeviceTransport(rawTransport: transport(id))
                let modelUID = string(id, kAudioDevicePropertyModelUID)
                return AudioOutputDevice(
                    uid: uid,
                    name: string(id, kAudioObjectPropertyName) ?? "Unknown Device",
                    modelUID: modelUID,
                    transport: transport,
                    symbolName: OutputDeviceSymbol.name(
                        for: transport,
                        modelUID: modelUID,
                        bluetoothKind: bluetooth?.kind(forDeviceUID: uid),
                        builtInSpeakers: builtInSpeakers
                    )
                )
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func currentOutputUID() -> String? {
        var address = globalAddress(kAudioHardwarePropertyDefaultOutputDevice)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var id = AudioObjectID(kAudioObjectUnknown)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &id
        ) == noErr, id != AudioObjectID(kAudioObjectUnknown) else { return nil }
        return string(id, kAudioDevicePropertyDeviceUID)
    }

    static func globalAddress(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
    }

    private static func allDeviceIDs() -> [AudioObjectID] {
        var address = globalAddress(kAudioHardwarePropertyDevices)
        var size: UInt32 = 0
        let system = AudioObjectID(kAudioObjectSystemObject)
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return [] }

        var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &ids) == noErr else { return [] }
        return ids
    }

    /// A device counts as an output when it has at least one buffer on the output scope. Devices
    /// that only record have none.
    private static func hasOutputBuffers(_ id: AudioObjectID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size) == noErr, size > 0 else {
            return false
        }

        let buffer = UnsafeMutableRawPointer.allocate(
            byteCount: Int(size),
            alignment: MemoryLayout<AudioBufferList>.alignment
        )
        defer { buffer.deallocate() }
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, buffer) == noErr else {
            return false
        }

        let list = UnsafeMutableAudioBufferListPointer(
            buffer.assumingMemoryBound(to: AudioBufferList.self)
        )
        return list.contains { $0.mNumberChannels > 0 }
    }

    /// CoreAudio creates transient objects of its own, named after whatever process caused them —
    /// `CADefaultDeviceAggregate-90478-3`, `AudioTap-441263EC-…`. They come and go and are no use
    /// in a priority list. This is the supported way to leave them out; matching on their names
    /// would need updating whenever Apple renames one.
    private static func isHidden(_ id: AudioObjectID) -> Bool {
        var address = globalAddress(kAudioDevicePropertyIsHidden)
        var size = UInt32(MemoryLayout<UInt32>.size)
        var hidden: UInt32 = 0
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &hidden) == noErr else {
            return false
        }
        return hidden != 0
    }

    private static func transport(_ id: AudioObjectID) -> UInt32 {
        var address = globalAddress(kAudioDevicePropertyTransportType)
        var size = UInt32(MemoryLayout<UInt32>.size)
        var transport: UInt32 = 0
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &transport) == noErr else {
            return 0
        }
        return transport
    }

    private static func string(_ id: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String? {
        var address = globalAddress(selector)
        // Unmanaged keeps this a plain value, so taking its address is not a pointer to a managed
        // reference. CoreAudio returns these strings at +1.
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        var value: Unmanaged<CFString>?
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &value) == noErr,
              let string = value?.takeRetainedValue() else { return nil }
        return string as String
    }
}
