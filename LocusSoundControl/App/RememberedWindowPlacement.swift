import AppKit

/// Opens a window centered on the primary display the first time, then where the user last left it.
struct RememberedWindowPlacement {
    let autosaveName: NSWindow.FrameAutosaveName

    /// Call once, before the window is first shown.
    func apply(to window: NSWindow) {
        // A window built from a hosting controller measures 1x32 until something asks its content
        // for a size, which is why `NSWindow.center()` puts the corner where the middle should be.
        // Neither `NSWindow.layoutIfNeeded()` nor `layoutSubtreeIfNeeded()` settles it; reading
        // `fittingSize` does.
        window.setContentSize(window.contentView?.fittingSize ?? window.frame.size)
        let fittedSize = window.frame.size
        let restored = window.setFrameUsingName(autosaveName)
        window.setFrameAutosaveName(autosaveName)

        if !restored {
            centerOnPrimaryDisplay(window, size: fittedSize)
        } else if !window.styleMask.contains(.resizable) {
            // A fixed-size window takes its size from its content, which can change between
            // versions, so only the saved position carries over.
            let top = window.frame.maxY
            window.setFrame(
                NSRect(x: window.frame.minX, y: top - fittedSize.height, width: fittedSize.width, height: fittedSize.height),
                display: false
            )
        }
    }

    private func centerOnPrimaryDisplay(_ window: NSWindow, size: NSSize) {
        guard let screen = NSScreen.screens.first else { return }
        let visible = screen.visibleFrame
        window.setFrameOrigin(NSPoint(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2))
    }
}
