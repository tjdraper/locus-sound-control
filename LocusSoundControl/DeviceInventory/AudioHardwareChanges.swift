import CoreAudio
import Foundation

/// CoreAudio reports changes through listener blocks. Wrapping one in an async sequence puts the
/// registration and its removal in the same place, and lets a consumer stop by cancelling its own
/// task rather than remembering to deregister.
nonisolated enum AudioHardwareChanges {
    /// Watches a property of the system object. Only the fact that it changed is reported; the
    /// value is read back on demand.
    ///
    /// Bursts are collapsed rather than queued: a connect fires several notifications and reading
    /// the list once afterwards answers all of them.
    static func stream(for selector: AudioObjectPropertySelector) -> AsyncStream<Void> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let system = AudioObjectID(kAudioObjectSystemObject)
            let queue = DispatchQueue.main

            // Swift imports an ObjC block as a non-Sendable function type. This one is built here,
            // never mutated and never called by this code; the termination handler only hands the
            // same block back to CoreAudio so the registration can be matched and removed.
            // swiftlint:disable:next nonisolated_unsafe
            nonisolated(unsafe) let listener: AudioObjectPropertyListenerBlock = { _, _ in
                continuation.yield()
            }

            var address = OutputDeviceReader.globalAddress(selector)
            guard AudioObjectAddPropertyListenerBlock(system, &address, queue, listener) == noErr else {
                continuation.finish()
                return
            }

            continuation.onTermination = { _ in
                var address = OutputDeviceReader.globalAddress(selector)
                AudioObjectRemovePropertyListenerBlock(system, &address, queue, listener)
            }
        }
    }
}
