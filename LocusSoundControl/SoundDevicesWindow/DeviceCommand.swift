import Foundation

/// Something that can be done to the devices selected in the Sound Devices window. The File menu
/// and the list's context menu both offer these, so each is named once, here.
nonisolated enum DeviceCommand: Hashable, Sendable {
    /// Out of the new device queue and onto the bottom of the priority order. Dragging does the
    /// same with a chosen position; this is the way that does not need a pointer.
    case place(Set<DeviceEntry.ID>)
    case changeIcon(DeviceEntry.ID)
    case hide(Set<DeviceEntry.ID>)
    case unhide(Set<DeviceEntry.ID>)
    case forget(Set<DeviceEntry.ID>)

    var title: String {
        switch self {
        case let .place(ids): "Add \(Self.soundDevices(ids.count)) to Priority Order"
        case .changeIcon: Self.changeIconTitle
        case let .hide(ids): Self.hideTitle(count: ids.count)
        case let .unhide(ids): "Unhide \(Self.soundDevices(ids.count))"
        case let .forget(ids): Self.forgetTitle(count: ids.count)
        }
    }

    var symbolName: String {
        switch self {
        case .place: "arrow.down.to.line"
        case .changeIcon: "paintpalette"
        case .hide: "eye.slash"
        case .unhide: "eye"
        case .forget: "trash"
        }
    }

    /// Shown disabled in the File menu while nothing is selected, so the commands can be found
    /// before they can be used.
    static let nothingSelectedTitles = [[changeIconTitle], [hideTitle(count: 1)], [forgetTitle(count: 1)]]

    /// The commands for a selection, in groups a menu separates. Hiding and unhiding count only the
    /// devices they would change, so a mixed selection offers both, each with its own count.
    ///
    /// - Parameter connected: which of `entries` are connected right now. Forgetting a connected
    ///   device would record it again straight away, so forget is only offered when none are.
    static func groups(for entries: [DeviceEntry], connected: Set<DeviceEntry.ID>) -> [[DeviceCommand]] {
        var groups: [[DeviceCommand]] = []

        let queued = Set(entries.filter(\.isQueued).map(\.id))
        if !queued.isEmpty { groups.append([.place(queued)]) }

        if entries.count == 1, let entry = entries.first {
            groups.append([.changeIcon(entry.id)])
        }

        let visible = Set(entries.filter { !$0.isHidden }.map(\.id))
        let hidden = Set(entries.filter(\.isHidden).map(\.id))
        var visibility: [DeviceCommand] = []
        if !visible.isEmpty { visibility.append(.hide(visible)) }
        if !hidden.isEmpty { visibility.append(.unhide(hidden)) }
        if !visibility.isEmpty { groups.append(visibility) }

        if !entries.isEmpty, entries.allSatisfy({ !connected.contains($0.id) }) {
            groups.append([.forget(Set(entries.map(\.id)))])
        }
        return groups
    }

    private static let changeIconTitle = "Change Icon…"

    private static func hideTitle(count: Int) -> String {
        "Hide \(soundDevices(count))"
    }

    private static func forgetTitle(count: Int) -> String {
        "Forget \(soundDevices(count))…"
    }

    private static func soundDevices(_ count: Int) -> String {
        count == 1 ? "Sound Device" : "\(count) Sound Devices"
    }
}
