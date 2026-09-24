import ServiceManagement

/// Mirrors the app's login item. The user can change it in System Settings at any time, and
/// `SMAppService` doesn't announce changes, so callers refresh when the app comes forward.
@Observable
final class LaunchAtLoginStore {
    private(set) var status = SMAppService.mainApp.status
    private(set) var changeFailed = false

    var isEnabled: Bool {
        status == .enabled || status == .requiresApproval
    }

    var needsApproval: Bool {
        status == .requiresApproval
    }

    func setEnabled(_ isEnabled: Bool) {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            changeFailed = false
        } catch {
            changeFailed = true
        }
        refresh()
    }

    func refresh() {
        status = SMAppService.mainApp.status
    }

    func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
