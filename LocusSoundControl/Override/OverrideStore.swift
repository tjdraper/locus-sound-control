import Foundation
import SwiftUI

/// The device the user chose to listen through, which wins over the priority order until it is
/// cancelled or the device goes away. Saved so that it survives a quit and relaunch.
///
/// Held as a UID rather than an entry. It is cleared the moment its device leaves, so it never has
/// to outlast the device being re-identified under a new one.
@Observable
final class OverrideStore {
    private(set) var uid: String?

    @ObservationIgnored private let defaults: UserDefaults

    private static let key = "OutputOverride"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        uid = defaults.string(forKey: Self.key)
    }

    func set(_ uid: String) {
        guard uid != self.uid else { return }
        self.uid = uid
        defaults.set(uid, forKey: Self.key)
    }

    func cancel() {
        guard uid != nil else { return }
        uid = nil
        defaults.removeObject(forKey: Self.key)
    }
}
