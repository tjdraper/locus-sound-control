import AppKit

enum AppActivation {
    /// `NSApp.activate()` is only a request, and macOS turns it down while another app is in
    /// front, which is always the case when a menu bar app opens a window. Asking on behalf of
    /// the frontmost app is honored.
    static func bringToFront() {
        guard let frontmost = NSWorkspace.shared.frontmostApplication else {
            NSApp.activate()
            return
        }
        NSRunningApplication.current.activate(from: frontmost, options: [])
    }
}
