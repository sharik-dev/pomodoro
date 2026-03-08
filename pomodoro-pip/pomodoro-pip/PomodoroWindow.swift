import AppKit
import SwiftUI

class PomodoroWindow: NSPanel {

    static let standardSize = CGSize(width: 300, height: 330)
    static let islandSize   = CGSize(width: 370, height: 56)

    private var rightClickMonitor: Any?

    deinit {
        if let m = rightClickMonitor { NSEvent.removeMonitor(m) }
    }

    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
            styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        rightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            guard self != nil else { return event }
            NotificationCenter.default.post(name: .openTimerSetup, object: nil)
            return nil
        }

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
                // Anchor flush below the menu bar / notch
                targetFrame = NSRect(
                    x: screenRect.midX - w / 2,
                    y: screenRect.maxY - h,
                    width: w, height: h
                )
                self.hasShadow = true
            }

            // No window animation — intermediate sizes cause NSHostingView constraint loops.
            // SwiftUI's scale/opacity transitions handle the visual.
            self.setFrame(targetFrame, display: true, animate: false)
        }
    }
}
