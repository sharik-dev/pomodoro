import SwiftUI
import AppKit

struct PomodoroContentView: View {
    @EnvironmentObject var manager: PomodoroManager
    @State private var isHovered = false
    @State private var showSetup = false
    @State private var pulseGlow = false
    @State private var appeared = false

    private let spring = Animation.spring(response: 0.45, dampingFraction: 0.8, blendDuration: 0)

    var body: some View {
        ZStack {
            if manager.isDynamicIslandMode {
                dynamicIslandLayout
                    .frame(width: 370, height: 56)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal:   .scale(scale: 0.9).combined(with: .opacity)
                    ))
            } else {
                standardLayout
                    .frame(width: 300, height: 330)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.92).combined(with: .opacity),
                        removal:   .scale(scale: 0.92).combined(with: .opacity)
                    ))
            }

            // Setup overlay
            if showSetup {
                Color.black.opacity(0.4)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .transition(.opacity)
                    .onTapGesture { withAnimation(spring) { showSetup = false } }

                TimerSetupView(isPresented: $showSetup)
                    .transition(.scale(scale: 0.88).combined(with: .opacity))
            }

            // Celebration overlay (shown on top of everything)
            if manager.showCelebration && !manager.isDynamicIslandMode {
                CelebrationOverlay(state: manager.currentState)
                    .frame(width: 300, height: 330)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 1.06).combined(with: .opacity),
                        removal:   .scale(scale: 0.96).combined(with: .opacity)
                    ))
                    .zIndex(30)
            }
        }
        .scaleEffect(appeared ? 1 : 0.84)
        .opacity(appeared ? 1 : 0)
        .onHover { hovering in withAnimation(spring) { isHovered = hovering } }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) { appeared = true }
            if manager.isRunning { startPulse() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openTimerSetup)) { _ in
            openSetup()
        }
        .onChange(of: manager.isRunning) {
            if manager.isRunning { startPulse() } else { stopPulse() }
        }
    }

    // MARK: - Helpers

    private func openSetup() {
        if manager.isDynamicIslandMode {
            withAnimation(spring) { manager.isDynamicIslandMode = false; updateWindow(isIsland: false) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(spring) { showSetup = true }
            }
        } else {
            withAnimation(spring) { showSetup = true }
        }
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) { pulseGlow = true }
    }

    private func stopPulse() {
        withAnimation(.easeOut(duration: 0.4)) { pulseGlow = false }
    }

    private func updateWindow(isIsland: Bool) {
        if let w = NSApplication.shared.windows.first(where: { $0 is PomodoroWindow }) as? PomodoroWindow {
            w.updateWindowFrame(isDynamicIsland: isIsland)
        }
    }

    // MARK: - Standard Layout (360 × 400)

    private var standardLayout: some View {
        ZStack {
            // State-change colour flash
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(PomodoroTheme.primaryColor(for: manager.currentState)
                        .opacity(manager.justChanged ? 0.2 : 0))
                .animation(.easeOut(duration: 0.55), value: manager.justChanged)

            // Glass card
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.5), radius: 40, x: 0, y: 24)

            VStack(spacing: 0) {

                // ── Header ──────────────────────────────────────────────
                HStack(alignment: .center) {
                    // State badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(PomodoroTheme.primaryColor(for: manager.currentState))
                            .frame(width: 7, height: 7)
                            .shadow(color: PomodoroTheme.primaryColor(for: manager.currentState).opacity(0.9), radius: 4)
                            .animation(spring, value: manager.currentState)
                        Text(manager.currentState.title.uppercased())
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(PomodoroTheme.primaryColor(for: manager.currentState))
                            .animation(spring, value: manager.currentState)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(PomodoroTheme.primaryColor(for: manager.currentState).opacity(0.13))
                    )
                    .animation(spring, value: manager.currentState)

                    Spacer()

                    HStack(spacing: 14) {
                        // Setup
                        HeaderButton(icon: "slider.horizontal.3") {
                            withAnimation(spring) { showSetup = true }
                        }
                        // Compact mode
                        HeaderButton(icon: "arrow.up.and.line.horizontal.and.arrow.down") {
                            withAnimation(spring) {
                                manager.isDynamicIslandMode = true
                                updateWindow(isIsland: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)

                Spacer(minLength: 0)

                // ── Timer circle — right-click (two-finger) opens setup ──
                ZStack {
                    // Pulse glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    PomodoroTheme.primaryColor(for: manager.currentState)
                                        .opacity(manager.isRunning && pulseGlow ? 0.28 : 0),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 44,
                                endRadius: 90
                            )
                        )
                        .frame(width: 180, height: 180)
                        .animation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true), value: pulseGlow)

                    // Track + arc
                    ProgressCircle(
                        progress: manager.progress,
                        gradient: PomodoroTheme.gradient(for: manager.currentState),
                        primaryColor: PomodoroTheme.primaryColor(for: manager.currentState),
                        lineWidth: 14
                    )
                    .frame(width: 136, height: 136)

                    // Time text
                    VStack(spacing: 3) {
                        Text(timeString(from: manager.timeRemaining))
                            .monospacedDigit()
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: manager.timeRemaining)
                            .scaleEffect(!manager.isRunning && manager.currentState != .idle
                                         ? (pulseGlow ? 1.04 : 0.97) : 1.0)
                            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulseGlow)

                        Text("right-click to setup")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(isHovered ? 0.35 : 0))
                            .animation(.easeInOut(duration: 0.2), value: isHovered)
                    }
                }
                .contentShape(Circle().size(CGSize(width: 180, height: 180)))

                Spacer(minLength: 0)

                // ── Session dots (4-pomodoro cycle) ──────────────────────
                HStack(spacing: 9) {
                    ForEach(0..<4) { i in
                        let filled = i < (manager.completedSessions % 4)
                        Circle()
                            .fill(filled
                                  ? PomodoroTheme.primaryColor(for: .work)
                                  : Color.white.opacity(0.18))
                            .frame(width: 6, height: 6)
                            .shadow(color: filled
                                    ? PomodoroTheme.primaryColor(for: .work).opacity(0.7)
                                    : .clear, radius: 3)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(i) * 0.06),
                                       value: manager.completedSessions)
                    }
                }

                Spacer(minLength: 0)

                // ── Controls ─────────────────────────────────────────────
                HStack(spacing: 18) {
                    ControlButton(icon: "arrow.clockwise", color: .white.opacity(0.5)) {
                        withAnimation(spring) { manager.reset() }
                    }

                    // Primary play/pause (larger)
                    ControlButton(
                        icon: manager.isRunning ? "pause.fill" : "play.fill",
                        color: .white,
                        size: 48,
                        iconSize: 18
                    ) {
                        withAnimation(spring) { manager.toggle() }
                    }
                    .overlay(
                        // Glowing ring on the primary button when running
                        Circle()
                            .stroke(
                                PomodoroTheme.primaryColor(for: manager.currentState)
                                    .opacity(manager.isRunning && pulseGlow ? 0.6 : 0),
                                lineWidth: 2
                            )
                            .frame(width: 56, height: 56)
                            .animation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true), value: pulseGlow)
                    )

                    ControlButton(icon: "forward.end.fill", color: .white.opacity(0.5)) {
                        // Skip to next state
                        let next: PomodoroState = manager.currentState == .work ? .shortBreak : .work
                        withAnimation(spring) { manager.start(state: next) }
                    }
                }
                .scaleEffect(isHovered ? 1.0 : 0.93)
                .opacity(isHovered ? 1.0 : 0.65)
                .animation(spring, value: isHovered)

                Spacer(minLength: 0)
            }
            .frame(height: 330)
        }
    }

    // MARK: - Dynamic Island Layout

    private var dynamicIslandLayout: some View {
        ZStack {
            Color.black
                .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 35, style: .continuous)
                        .stroke(
                            PomodoroTheme.primaryColor(for: manager.currentState)
                                .opacity(manager.isRunning && pulseGlow ? 0.55 : 0),
                            lineWidth: 1.2
                        )
                        .animation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true), value: pulseGlow)
                )

            HStack(spacing: 0) {
                // Left: mini progress + time
                HStack(spacing: 11) {
                    ProgressCircle(
                        progress: manager.progress,
                        gradient: PomodoroTheme.gradient(for: manager.currentState),
                        primaryColor: PomodoroTheme.primaryColor(for: manager.currentState),
                        lineWidth: 2.5
                    )
                    .frame(width: 22, height: 22)

                    VStack(alignment: .leading, spacing: -1) {
                        Text(manager.currentState.title)
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(PomodoroTheme.primaryColor(for: manager.currentState).opacity(0.85))
                            .textCase(.uppercase)
                            .animation(spring, value: manager.currentState)

                        Text(timeString(from: manager.timeRemaining))
                            .monospacedDigit()
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: manager.timeRemaining)
                    }
                }
                .frame(width: 110, alignment: .leading)
                .padding(.leading, 14)
                .padding(.top, 10)

                Spacer()

                // Right: controls
                HStack(spacing: 18) {
                    if isHovered || manager.isRunning {
                        HStack(spacing: 20) {
                            Button(action: { manager.toggle() }) {
                                Image(systemName: manager.isRunning ? "pause.fill" : "play.fill")
                            }
                            Button(action: {
                                withAnimation(spring) {
                                    manager.isDynamicIslandMode = false
                                    updateWindow(isIsland: false)
                                }
                            }) {
                                Image(systemName: "arrow.down.forward.and.arrow.up.backward")
                            }
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    } else {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(PomodoroTheme.primaryColor(for: manager.currentState))
                            .transition(.opacity)
                    }
                }
                .frame(width: 100, alignment: .trailing)
                .padding(.trailing, 14)
                .padding(.top, 10)
            }
        }
        .buttonStyle(.plain)
    }

    private func timeString(from interval: TimeInterval) -> String {
        let m = Int(interval) / 60, s = Int(interval) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - HeaderButton

private struct HeaderButton: View {
    let icon: String
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(hovered ? .white : .white.opacity(0.45))
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(hovered ? 0.12 : 0))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hovered = h } }
    }
}

// MARK: - ControlButton

struct ControlButton: View {
    let icon: String
    let color: Color
    var size: CGFloat = 50
    var iconSize: CGFloat = 18
    let action: () -> Void
    @State private var isHovering = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .heavy))
                .foregroundStyle(color)
                .frame(width: size, height: size)
                .background(
                    Circle().fill(isHovering ? Color.white.opacity(0.16) : Color.white.opacity(0.08))
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(isHovering ? 0.3 : 0.1), lineWidth: 1)
                )
                .scaleEffect(isPressed ? 0.87 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { isHovering = h } }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) { isPressed = true } }
                .onEnded   { _ in withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { isPressed = false } }
        )
    }
}

// MARK: - ProgressCircle

struct ProgressCircle: View {
    var progress: Double
    var gradient: Gradient
    var primaryColor: Color
    var lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(primaryColor.opacity(0.1), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    AngularGradient(gradient: gradient, center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(270))
                .shadow(color: primaryColor.opacity(0.6), radius: lineWidth * 0.75)
                .animation(.linear(duration: 1.0), value: progress)
        }
    }
}


// MARK: - CelebrationOverlay

private struct WidgetPiece: Identifiable {
    let id: Int
    let startX, startY, endX, endY: CGFloat
    let startRot, endRot: Double
    let color: Color
    let w, h: CGFloat
    let delay, dur: Double
    let kind: Int   // 0 rect  1 circle  2 diamond

    static func generate() -> [WidgetPiece] {
        let palette: [Color] = [
            Color(red: 1.0, green: 0.85, blue: 0.1),
            Color(red: 1.0, green: 0.35, blue: 0.35),
            Color(red: 0.35, green: 0.92, blue: 0.55),
            Color(red: 0.3,  green: 0.78, blue: 1.0),
            Color(red: 0.75, green: 0.4,  blue: 1.0),
            Color(red: 1.0,  green: 0.45, blue: 0.8),
            Color(red: 0.4,  green: 1.0,  blue: 0.9),
        ]
        let cx: CGFloat = 150
        let cy: CGFloat = 145
        return (0 ..< 55).map { i in
            let angle = Double.random(in: 0 ..< 2 * .pi)
            let dist  = CGFloat.random(in: 55 ... 165)
            return WidgetPiece(
                id: i,
                startX: cx, startY: cy,
                endX: cx + CGFloat(cos(angle)) * dist,
                endY: cy + CGFloat(sin(angle)) * dist * 0.9,
                startRot: Double.random(in: 0 ... 360),
                endRot:   Double.random(in: -720 ... 720),
                color: palette.randomElement()!,
                w: CGFloat.random(in: 7 ... 16),
                h: CGFloat.random(in: 4 ... 8),
                delay: Double.random(in: 0 ... 0.2),
                dur:   Double.random(in: 0.9 ... 1.7),
                kind:  Int.random(in: 0 ... 2)
            )
        }
    }
}

private struct CelebrationOverlay: View {
    let state: PomodoroState

    @State private var pieces: [WidgetPiece] = WidgetPiece.generate()
    @State private var burst     = false
    @State private var cardScale = 0.2
    @State private var cardOpa   = 0.0
    @State private var emojiScale: CGFloat = 0.1
    @State private var ring1: CGFloat = 0.1
    @State private var ring2: CGFloat = 0.1
    @State private var ringOpa1  = 0.9
    @State private var ringOpa2  = 0.9
    @State private var shimmer   = false

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
        case .work:       return "SESSION\nCOMPLETE"
        case .shortBreak: return "BREAK\nOVER"
        case .longBreak:  return "RESTED &\nREADY"
        case .idle:       return "DONE"
        }
    }
    private var subtitle: String {
        switch state {
        case .work:       return "Amazing work!"
        case .shortBreak: return "Back to focus"
        case .longBreak:  return "Let's crush it"
        case .idle:       return ""
        }
    }

    var body: some View {
        ZStack {
            // Backdrop
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.88))

            // Shockwave rings
            Circle()
                .stroke(accent.opacity(ringOpa1), lineWidth: 2)
                .frame(width: 100, height: 100)
                .scaleEffect(ring1)
                .position(x: 150, y: 145)

            Circle()
                .stroke(accent.opacity(ringOpa2 * 0.6), lineWidth: 1.4)
                .frame(width: 100, height: 100)
                .scaleEffect(ring2)
                .position(x: 150, y: 145)

            // Confetti
            ForEach(pieces) { p in
                pieceView(p)
                    .position(
                        x: burst ? p.endX : p.startX,
                        y: burst ? p.endY : p.startY
                    )
                    .rotationEffect(.degrees(burst ? p.endRot : p.startRot))
                    .opacity(burst ? 1 : 0)
                    .animation(
                        .spring(response: p.dur, dampingFraction: 0.62).delay(p.delay),
                        value: burst
                    )
            }

            // Center card
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 52))
                    .scaleEffect(emojiScale)
                    .shadow(color: accent.opacity(0.9), radius: 16)
                    .animation(
                        .spring(response: 0.46, dampingFraction: 0.38).delay(0.05),
                        value: emojiScale
                    )

                Text(title)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: accent.opacity(0.95), radius: 12)
                    .shadow(color: accent.opacity(0.4), radius: 28)

                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))

                // Shimmer bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.2), accent, accent.opacity(0.2)],
                            startPoint: shimmer ? .leading  : .trailing,
                            endPoint:   shimmer ? .trailing : .leading
                        )
                    )
                    .frame(width: 120, height: 2.5)
                    .padding(.top, 4)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: false),
                        value: shimmer
                    )
            }
            .scaleEffect(cardScale)
            .opacity(cardOpa)
        }
        .clipped()
        .onAppear {
            // Rings
            withAnimation(.easeOut(duration: 0.9))  { ring1 = 5.5; ringOpa1 = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.85)) { ring2 = 4.5; ringOpa2 = 0 }
            }
            // Confetti
            withAnimation { burst = true }
            // Card
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.04)) {
                cardScale = 1
                cardOpa   = 1
            }
            // Emoji
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) { emojiScale = 1 }
            // Shimmer
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { shimmer = true }
        }
    }

    @ViewBuilder
    private func pieceView(_ p: WidgetPiece) -> some View {
        Group {
            if p.kind == 0 {
                Rectangle().fill(p.color).frame(width: p.w, height: p.h)
            } else if p.kind == 1 {
                Circle().fill(p.color).frame(width: p.h + 2, height: p.h + 2)
            } else {
                Rectangle().fill(p.color).frame(width: p.h, height: p.h).rotationEffect(.degrees(45))
            }
        }
        .shadow(color: p.color.opacity(0.7), radius: 4)
    }
}

#Preview {
    PomodoroContentView()
        .environmentObject(PomodoroManager())
}
