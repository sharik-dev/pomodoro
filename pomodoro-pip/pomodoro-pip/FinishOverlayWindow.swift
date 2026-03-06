import AppKit
import SwiftUI

/// Full-screen Raycast-style edge glow that flashes when the timer finishes.
class FinishOverlayWindow: NSWindow {

    // Retained to prevent early dealloc
    private static var active: [FinishOverlayWindow] = []

    static func show(for state: PomodoroState) {
        guard let screen = NSScreen.main else { return }

        let win = FinishOverlayWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.configure(screen: screen, state: state)
        active.append(win)

        // Auto-cleanup after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            active.removeAll { $0 === win }
        }
    }

    private func configure(screen: NSScreen, state: PomodoroState) {
        backgroundColor = .clear
        isOpaque = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        ignoresMouseEvents = true
        hasShadow = false
        alphaValue = 1

        let accentColor = PomodoroTheme.primaryColor(for: state)
        let view = FinishOverlayView(accentColor: accentColor)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = screen.frame
        contentView = hosting

        makeKeyAndOrderFront(nil)
    }
}

private struct FinishOverlayView: View {
    let accentColor: Color
    @State private var intensity: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Top edge
                LinearGradient(
                    colors: [accentColor.opacity(0.65), .clear],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.2)
                )
                // Bottom edge
                LinearGradient(
                    colors: [accentColor.opacity(0.65), .clear],
                    startPoint: .bottom,
                    endPoint: UnitPoint(x: 0.5, y: 0.8)
                )
                // Left edge
                LinearGradient(
                    colors: [accentColor.opacity(0.5), .clear],
                    startPoint: .leading,
                    endPoint: UnitPoint(x: 0.16, y: 0.5)
                )
                // Right edge
                LinearGradient(
                    colors: [accentColor.opacity(0.5), .clear],
                    startPoint: .trailing,
                    endPoint: UnitPoint(x: 0.84, y: 0.5)
                )
                // Subtle center bloom
                RadialGradient(
                    colors: [.clear, accentColor.opacity(0.08)],
                    center: .center,
                    startRadius: geo.size.width * 0.25,
                    endRadius: geo.size.width * 0.75
                )
            }
            .opacity(intensity)
        }
        .ignoresSafeArea()
        .onAppear {
            // Burst in
            withAnimation(.easeOut(duration: 0.14)) {
                intensity = 1
            }
            // Fade out after hold
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeIn(duration: 1.1)) {
                    intensity = 0
                }
            }
        }
    }
}
