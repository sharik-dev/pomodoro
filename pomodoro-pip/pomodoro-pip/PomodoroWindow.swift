import AppKit
import SwiftUI

class PomodoroWindow: NSPanel {

    static let standardSize = CGSize(width: 360, height: 400)
    static let islandSize   = CGSize(width: 460, height: 70)

    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
            styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isMovableByWindowBackground = true
        backgroundColor = .clear
        level = .mainMenu
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        hasShadow = false
        self.contentView = contentView

        updateWindowFrame()
    }

    override var canBecomeKey: Bool { true }

    func updateWindowFrame(isDynamicIsland: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            let screen = NSScreen.main ?? NSScreen.screens.first
            guard let screenRect = screen?.visibleFrame else { return }
            let fullRect = screen?.frame ?? .zero

            let targetFrame: NSRect
            if isDynamicIsland {
                let w = Self.islandSize.width
                let h = Self.islandSize.height
                targetFrame = NSRect(
                    x: fullRect.width / 2 - w / 2,
                    y: fullRect.height - h,
                    width: w, height: h
                )
                self.hasShadow = false
            } else {
                let w = Self.standardSize.width
                let h = Self.standardSize.height
                targetFrame = NSRect(
                    x: screenRect.width / 2 - w / 2,
                    y: screenRect.height - h - 100,
                    width: w, height: h
                )
                self.hasShadow = true
            }

            self.setFrame(targetFrame, display: true, animate: true)
        }
    }
}
