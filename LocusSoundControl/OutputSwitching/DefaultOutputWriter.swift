import CoreAudio
import Foundation

/// Points the Mac's sound output at a device.
///
/// macOS tracks the default output and the system alert output separately, and they drift apart
/// until alerts play somewhere other than everything else. Both are written, so they stay matched.
nonisolated enum DefaultOutputWriter {
    enum Outcome: Equatable {
        case alreadySelected
        case switched
        case deviceNotFound
        case failed(OSStatus)
    }

    static func select(uid: String) -> Outcome {
        guard let target = deviceID(forUID: uid) else { return .deviceNotFound }

        var outcome = Outcome.alreadySelected
        if currentDevice(kAudioHardwarePropertyDefaultOutputDevice) != target {
            let status = setDevice(kAudioHardwarePropertyDefaultOutputDevice, to: target)
            outcome = status == noErr ? .switched : .failed(status)
        }

        // Not every device can be the alert output, so a refusal is ignored rather than retried.
        if currentDevice(kAudioHardwarePropertyDefaultSystemOutputDevice) != target {
            _ = setDevice(kAudioHardwarePropertyDefaultSystemOutputDevice, to: target)
        }
        return outcome
    }

    private static let system = AudioObjectID(kAudioObjectSystemObject)

    private static func deviceID(forUID uid: String) -> AudioObjectID? {
        var address = OutputDeviceReader.globalAddress(kAudioHardwarePropertyTranslateUIDToDevice)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var id = AudioObjectID(kAudioObjectUnknown)
        // The qualifier is a pointer to a CFString reference, so the reference has to stay a plain
        // value in a variable for the length of the call.
        let cfUID = uid as CFString
        var qualifier = Unmanaged.passUnretained(cfUID)
        let status = withExtendedLifetime(cfUID) {
            AudioObjectGetPropertyData(
                system, &address, UInt32(MemoryLayout<Unmanaged<CFString>>.size), &qualifier, &size, &id
            )
        }
        guard status == noErr, id != AudioObjectID(kAudioObjectUnknown) else { return nil }
        return id
    }

    private static func currentDevice(_ selector: AudioObjectPropertySelector) -> AudioObjectID? {
        var address = OutputDeviceReader.globalAddress(selector)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var id = AudioObjectID(kAudioObjectUnknown)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &id) == noErr else { return nil }
        return id
    }

    private static func setDevice(_ selector: AudioObjectPropertySelector, to id: AudioObjectID) -> OSStatus {
        var address = OutputDeviceReader.globalAddress(selector)
        var id = id
        return AudioObjectSetPropertyData(system, &address, 0, nil, UInt32(MemoryLayout<AudioObjectID>.size), &id)
    }
}
