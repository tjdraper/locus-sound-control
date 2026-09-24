import Foundation

/// The symbols a user can give a device. Few enough to take in at once, because almost none of SF
/// Symbols reads as an audio device when flattened to a menu bar silhouette. Each was picked by
/// rendering it at 18pt; `Scripts/render-sf-symbols.swift` does the rendering.
///
/// Outline only: mixing filled and outline glyphs in one grid reads as a mistake. The automatic
/// icon can pick symbols outside this set, the Beats glyphs among them, and "Automatic" in the
/// picker is how a user gets one of those back.
nonisolated enum AssignableSymbols {
    /// One row of the picker per group, so similar devices sit together.
    static let groups: [[String]] = [
        ["hifispeaker", "hifispeaker.2", "speaker.wave.2", "speaker.wave.3"],
        ["headphones", "airpods.max", "airpods.pro", "airpods", "hearingdevice.ear"],
        ["homepod", "tv", "appletv"],
        ["display", "laptopcomputer", "desktopcomputer"],
        [
            "car",
            "waveform",
            "airplayaudio",
            "dot.radiowaves.left.and.right",
            "cable.connector.horizontal",
            "music.note",
            "pianokeys",
        ],
    ]
}
