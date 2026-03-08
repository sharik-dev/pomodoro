import AppKit
import SwiftUI

// MARK: - Window

class FinishOverlayWindow: NSWindow {

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
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
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

        let view = FinishOverlayView(state: state)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = screen.frame
        contentView = hosting
        orderFrontRegardless()
    }
}

// MARK: - Confetti model

private struct Piece: Identifiable {
    let id: Int
    let startX, startY: CGFloat   // relative 0-1
    let endX,   endY:   CGFloat
    let startRot, endRot: Double
    let color:   Color
    let w, h:    CGFloat
    let delay, dur: Double
    let kind:    Int              // 0 rect  1 circle  2 diamond

    static func burst(count: Int) -> [Piece] {
        let palette: [Color] = [
            Color(red: 1.0, green: 0.85, blue: 0.1),
            Color(red: 1.0, green: 0.35, blue: 0.35),
            Color(red: 0.35, green: 0.92, blue: 0.55),
            Color(red: 0.3,  green: 0.78, blue: 1.0),
            Color(red: 0.75, green: 0.4,  blue: 1.0),
            Color(red: 1.0,  green: 0.45, blue: 0.8),
            Color(red: 0.4,  green: 1.0,  blue: 0.9),
            Color(red: 1.0,  green: 0.6,  blue: 0.2),
        ]
        return (0 ..< count).map { i in
            let angle  = Double.random(in: 0 ..< 2 * .pi)
            let speed  = Double.random(in: 0.22 ... 0.62)
            let ex = 0.5  + cos(angle) * speed
            let ey = 0.38 + sin(angle) * speed * 0.75 + Double.random(in: 0.04 ... 0.28)
            return Piece(
                id: i,
                startX: 0.5,  startY: 0.38,
                endX:   CGFloat(ex), endY: CGFloat(ey),
                startRot: Double.random(in: 0 ... 360),
                endRot:   Double.random(in: -800 ... 800),
                color:  palette.randomElement()!,
                w: CGFloat.random(in: 8 ... 18),
                h: CGFloat.random(in: 4 ... 9),
                delay: Double.random(in: 0 ... 0.22),
                dur:   Double.random(in: 1.0 ... 2.0),
                kind:  Int.random(in: 0 ... 2)
            )
        }
    }
}

// MARK: - Main overlay view

private struct FinishOverlayView: View {

    let state: PomodoroState

    // Generated once at init; preserved by SwiftUI state across re-renders
    @State private var pieces: [Piece] = Piece.burst(count: 70)

    @State private var burst      = false   // confetti trigger
    @State private var visible    = 1.0     // master opacity for exit
    @State private var backdrop   = 0.0
    @State private var glowA      = 0.0     // edge glow
    @State private var cardScale  = 0.25
    @State private var cardOpa    = 0.0
    @State private var emojiScale = 0.1
    @State private var ring1      = 0.0     // shockwave ring scale
    @State private var ring2      = 0.0
    @State private var ring3      = 0.0
    @State private var ringOpa1   = 0.8
    @State private var ringOpa2   = 0.8
    @State private var ringOpa3   = 0.8
    @State private var shimmer    = false

    private var accent: Color { PomodoroTheme.primaryColor(for: state) }

    private var emoji: String {
        switch state {
        case .work:       return "🎉"
        case .shortBreak: return "⚡️"
        case .longBreak:  return "✨"
        case .idle:       return "✅"
        }
    }
    private var title: String {
        switch state {
        case .work:       return "SESSION COMPLETE"
        case .shortBreak: return "BREAK OVER"
        case .longBreak:  return "RESTED & READY"
        case .idle:       return "DONE"
        }
    }
    private var subtitle: String {
        switch state {
        case .work:       return "Amazing work — take a well-earned break"
        case .shortBreak: return "Time to get back in the zone"
        case .longBreak:  return "Refreshed and ready to crush it"
        case .idle:       return ""
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {

                // ── 1. Dark blur backdrop ──────────────────────────────────
                Color.black
                    .opacity(backdrop * 0.6)
                    .ignoresSafeArea()

                // ── 2. Edge colour glow ────────────────────────────────────
                ZStack {
                    LinearGradient(colors: [accent.opacity(0.75 * glowA), .clear],
                                   startPoint: .top,    endPoint: UnitPoint(x: 0.5, y: 0.2))
                    LinearGradient(colors: [accent.opacity(0.75 * glowA), .clear],
                                   startPoint: .bottom, endPoint: UnitPoint(x: 0.5, y: 0.8))
                    LinearGradient(colors: [accent.opacity(0.55 * glowA), .clear],
                                   startPoint: .leading,  endPoint: UnitPoint(x: 0.12, y: 0.5))
                    LinearGradient(colors: [accent.opacity(0.55 * glowA), .clear],
                                   startPoint: .trailing, endPoint: UnitPoint(x: 0.88, y: 0.5))
                }
                .ignoresSafeArea()

                // ── 3. Shockwave rings ────────────────────────────────────
                let cx = geo.size.width  * 0.5
                let cy = geo.size.height * 0.38

                Circle()
                    .stroke(accent.opacity(ringOpa1), lineWidth: 2.5)
                    .frame(width: 160, height: 160)
                    .scaleEffect(ring1)
                    .position(x: cx, y: cy)

                Circle()
                    .stroke(accent.opacity(ringOpa2 * 0.7), lineWidth: 1.8)
                    .frame(width: 160, height: 160)
                    .scaleEffect(ring2)
                    .position(x: cx, y: cy)

                Circle()
                    .stroke(accent.opacity(ringOpa3 * 0.5), lineWidth: 1.2)
                    .frame(width: 160, height: 160)
                    .scaleEffect(ring3)
                    .position(x: cx, y: cy)

                // ── 4. Confetti ───────────────────────────────────────────
                ForEach(pieces) { p in
                    pieceView(p)
                        .position(
                            x: burst ? p.endX * geo.size.width  : p.startX * geo.size.width,
                            y: burst ? p.endY * geo.size.height : p.startY * geo.size.height
                        )
                        .rotationEffect(.degrees(burst ? p.endRot : p.startRot))
                        .opacity(burst ? 1 : 0)
                        .animation(
                            .spring(response: p.dur, dampingFraction: 0.62).delay(p.delay),
                            value: burst
                        )
                }

                // ── 5. Center celebration card ────────────────────────────
                VStack(spacing: 10) {
                    Text(emoji)
                        .font(.system(size: 68))
                        .scaleEffect(emojiScale)
                        .shadow(color: accent.opacity(0.8), radius: 24)
                        .animation(
                            .spring(response: 0.48, dampingFraction: 0.42).delay(0.06),
                            value: emojiScale
                        )

                    Text(title)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: accent.opacity(0.95), radius: 18)
                        .shadow(color: accent.opacity(0.45), radius: 40)
                        .padding(.top, 2)

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.62))
                            .multilineTextAlignment(.center)
                    }

                    // Animated shimmer bar
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.25), accent, accent.opacity(0.25)],
                                startPoint: shimmer ? .leading  : .trailing,
                                endPoint:   shimmer ? .trailing : .leading
                            )
                        )
                        .frame(width: 160, height: 3)
                        .padding(.top, 6)
                        .animation(
                            .easeInOut(duration: 1.1).repeatForever(autoreverses: false),
                            value: shimmer
                        )
                }
                .padding(.horizontal, 44)
                .padding(.vertical, 36)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.black.opacity(0.58))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [accent.opacity(0.65), accent.opacity(0.12)],
                                        startPoint: .topLeading,
                                        endPoint:   .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: accent.opacity(0.35), radius: 50)
                        .shadow(color: .black.opacity(0.6),  radius: 30)
                )
                .scaleEffect(cardScale)
                .opacity(cardOpa)
                .position(x: cx, y: cy + 60)
            }
            .opacity(visible)
        }
        .ignoresSafeArea()
        .onAppear { animate() }
    }

    // MARK: - Animation sequence

    private func animate() {
        // Glow burst
        withAnimation(.easeOut(duration: 0.1)) { glowA = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            withAnimation(.easeOut(duration: 1.6)) { glowA = 0 }
        }

        // Backdrop
        withAnimation(.easeOut(duration: 0.22)) { backdrop = 1 }

        // Shockwave ring 1
        withAnimation(.easeOut(duration: 1.1)) { ring1 = 8; ringOpa1 = 0 }

        // Shockwave ring 2 (slight delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeOut(duration: 1.1)) { ring2 = 7; ringOpa2 = 0 }
        }

        // Shockwave ring 3 (more delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            withAnimation(.easeOut(duration: 1.0)) { ring3 = 6; ringOpa3 = 0 }
        }

        // Confetti burst
        withAnimation { burst = true }

        // Card pop in
        withAnimation(.spring(response: 0.52, dampingFraction: 0.58).delay(0.04)) {
            cardScale = 1
            cardOpa   = 1
        }

        // Emoji bounce (tighter spring = more bounce)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            emojiScale = 1
        }

        // Shimmer
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            shimmer = true
        }

        // ── Exit sequence ─────────────────────────────────────────────────
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation(.easeIn(duration: 0.9)) {
                visible  = 0
                backdrop = 0
            }
        }
    }

    // MARK: - Confetti shape builder

    @ViewBuilder
    private func pieceView(_ p: Piece) -> some View {
        Group {
            if p.kind == 0 {
                Rectangle()
                    .fill(p.color)
                    .frame(width: p.w, height: p.h)
            } else if p.kind == 1 {
                Circle()
                    .fill(p.color)
                    .frame(width: p.h + 2, height: p.h + 2)
            } else {
                Rectangle()
                    .fill(p.color)
                    .frame(width: p.h, height: p.h)
                    .rotationEffect(.degrees(45))
            }
        }
        .shadow(color: p.color.opacity(0.65), radius: 5)
    }
}
