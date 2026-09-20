#!/usr/bin/env swift
//
// Prints every output device this Mac can see, with the identifiers the priority list is keyed on.
//
// Sync matches a device on one Mac to the same device on another (Plans/HighLevelPlan.md, slice 7),
// and whether that can lean on the UID alone is unverified. Run this on both Macs with the same
// dock, display and headphones attached, and diff the two dumps: every UID that matches is one the
// model-level fallback never has to handle.

import CoreAudio
import Foundation

func systemObjectIDs(_ selector: AudioObjectPropertySelector) -> [AudioObjectID] {
    var address = AudioObjectPropertyAddress(
        mSelector: selector,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(
        AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size
    ) == noErr else { return [] }

    var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
    guard AudioObjectGetPropertyData(
        AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &ids
    ) == noErr else { return [] }
    return ids
}

func defaultDevice(_ selector: AudioObjectPropertySelector) -> AudioObjectID {
    var address = AudioObjectPropertyAddress(
        mSelector: selector,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var size = UInt32(MemoryLayout<AudioObjectID>.size)
    var id = AudioObjectID(kAudioObjectUnknown)
    AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &id)
    return id
}

func stringProperty(_ id: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String {
    var address = AudioObjectPropertyAddress(
        mSelector: selector,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    // Unmanaged keeps this a plain value, so taking its address is not a pointer to a managed
    // reference. CoreAudio returns these strings at +1.
    var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    var value: Unmanaged<CFString>?
    guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &value) == noErr,
          let string = value?.takeRetainedValue() else { return "—" }
    return string as String
}

func transportName(_ id: AudioObjectID) -> String {
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyTransportType,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var size = UInt32(MemoryLayout<UInt32>.size)
    var transport: UInt32 = 0
    guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &transport) == noErr else {
        return "unknown"
    }

    let names: [UInt32: String] = [
        kAudioDeviceTransportTypeBuiltIn: "BuiltIn",
        kAudioDeviceTransportTypeUSB: "USB",
        kAudioDeviceTransportTypeBluetooth: "Bluetooth",
        kAudioDeviceTransportTypeBluetoothLE: "BluetoothLE",
        kAudioDeviceTransportTypeDisplayPort: "DisplayPort",
        kAudioDeviceTransportTypeHDMI: "HDMI",
        kAudioDeviceTransportTypeThunderbolt: "Thunderbolt",
        kAudioDeviceTransportTypeAirPlay: "AirPlay",
        kAudioDeviceTransportTypeVirtual: "Virtual",
        kAudioDeviceTransportTypeAggregate: "Aggregate",
        kAudioDeviceTransportTypeFireWire: "FireWire",
        kAudioDeviceTransportTypePCI: "PCI",
        kAudioDeviceTransportTypeContinuityCaptureWired: "ContinuityCaptureWired",
        kAudioDeviceTransportTypeContinuityCaptureWireless: "ContinuityCaptureWireless",
    ]

    if let name = names[transport] { return name }

    // Transport types are four-character codes, so an unmapped one is still worth reading.
    let characters = (0..<4).map { shift -> Character in
        Character(UnicodeScalar(UInt8((transport >> (8 * (3 - shift))) & 0xFF)))
    }
    return "other(\(String(characters)))"
}

func hasOutputChannels(_ id: AudioObjectID) -> Bool {
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

    let list = UnsafeMutableAudioBufferListPointer(buffer.assumingMemoryBound(to: AudioBufferList.self))
    return list.contains { $0.mNumberChannels > 0 }
}

let defaultOutput = defaultDevice(kAudioHardwarePropertyDefaultOutputDevice)
let alertOutput = defaultDevice(kAudioHardwarePropertyDefaultSystemOutputDevice)

let formatter = ISO8601DateFormatter()
formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]

print("host:  \(Host.current().localizedName ?? "unknown")")
print("date:  \(formatter.string(from: Date()))")
print("")

// Sorted by name so two dumps diff cleanly; CoreAudio's own order is not stable.
let outputs = systemObjectIDs(kAudioHardwarePropertyDevices)
    .filter(hasOutputChannels)
    .map { (id: $0, name: stringProperty($0, kAudioObjectPropertyName)) }
    .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

for device in outputs {
    var markers: [String] = []
    if device.id == defaultOutput { markers.append("default output") }
    if device.id == alertOutput { markers.append("alert output") }
    let suffix = markers.isEmpty ? "" : "  [\(markers.joined(separator: ", "))]"

    print("\(device.name)\(suffix)")
    print("    uid:        \(stringProperty(device.id, kAudioDevicePropertyDeviceUID))")
    print("    modelUID:   \(stringProperty(device.id, kAudioDevicePropertyModelUID))")
    print("    manufact.:  \(stringProperty(device.id, kAudioObjectPropertyManufacturer))")
    print("    transport:  \(transportName(device.id))")
}

print("")
print("\(outputs.count) output device(s).")
