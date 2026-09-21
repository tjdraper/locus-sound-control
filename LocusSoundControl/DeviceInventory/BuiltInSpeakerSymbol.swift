import Foundation
import IOKit.ps

/// The built-in speakers are the Mac itself, so they show the Mac's own shape.
///
/// CoreAudio has no property for the chassis, and `hw.model` is a bare board identifier on Apple
/// Silicon rather than a readable name, so an internal battery is what separates a laptop from a
/// desktop.
nonisolated enum BuiltInSpeakerSymbol {
    static let name = hasInternalBattery() ? "laptopcomputer" : "desktopcomputer"

    private static func hasInternalBattery() -> Bool {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef]
        else { return false }

        // A desktop with a UPS attached also has a power source, so the type has to be checked.
        return sources.contains { source in
            let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue()
            let type = (description as? [String: Any])?[kIOPSTypeKey] as? String
            return type == kIOPSInternalBatteryType
        }
    }
}
