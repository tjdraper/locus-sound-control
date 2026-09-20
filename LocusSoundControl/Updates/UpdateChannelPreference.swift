import Foundation

/// Whether this Mac also receives beta releases.
nonisolated struct UpdateChannelPreference {
    static let betaChannel = "beta"

    private static let defaultsKey = "ReceiveBetaUpdates"

    let defaults: UserDefaults
    let isRunningBeta: Bool

    init(
        defaults: UserDefaults = .standard,
        version: String? = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    ) {
        self.defaults = defaults
        isRunningBeta = version.map(Self.isBeta) ?? false
    }

    /// `Scripts/release.sh` picks the channel from the same shape: YYYY.N is a full release and
    /// YYYY.N.B a beta leading up to one.
    static func isBeta(_ version: String) -> Bool {
        version.split(separator: ".").count == 3
    }

    /// A beta always gets the next beta. Turning them off there would leave the Mac on a beta
    /// until the full release, with none of the fixes the betas in between bring.
    var receivesBetaUpdates: Bool {
        get { isRunningBeta || defaults.bool(forKey: Self.defaultsKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.defaultsKey) }
    }

    /// Sparkle always includes the default channel, so this only ever names the extras.
    var allowedChannels: Set<String> {
        receivesBetaUpdates ? [Self.betaChannel] : []
    }
}
