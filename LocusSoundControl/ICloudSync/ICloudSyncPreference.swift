import Foundation

/// Whether the priority order syncs through iCloud. On unless turned off, since two Macs that move
/// between the same docks and headphones should not have to be taught the same order twice.
nonisolated struct ICloudSyncPreference {
    private static let defaultsKey = "SyncWithICloud"

    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isEnabled: Bool {
        get { defaults.object(forKey: Self.defaultsKey) as? Bool ?? true }
        nonmutating set { defaults.set(newValue, forKey: Self.defaultsKey) }
    }
}
