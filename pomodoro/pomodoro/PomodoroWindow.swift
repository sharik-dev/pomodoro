import AppKit
import SwiftUI

class PomodoroWindow: NSWindow {
    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.isMovableByWindowBackground = true
        self.backgroundColor = .clear
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.hasShadow = true
        self.contentView = contentView
        
        // Center the window initially or set to a preferred position
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.width / 2 - self.frame.width / 2
            let y = screenRect.height - self.frame.height - 40
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
}
