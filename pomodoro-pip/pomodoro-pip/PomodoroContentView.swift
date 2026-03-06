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
                    .frame(width: 460, height: 70)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal:   .scale(scale: 0.9).combined(with: .opacity)
                    ))
            } else {
                standardLayout
                    .frame(width: 360, height: 400)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.92).combined(with: .opacity),
                        removal:   .scale(scale: 0.92).combined(with: .opacity)
                    ))
            }

            // Setup overlay
            if showSetup {
                Color.black.opacity(0.4)
                    .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                    .transition(.opacity)
                    .onTapGesture { withAnimation(spring) { showSetup = false } }

                TimerSetupView(isPresented: $showSetup)
                    .transition(.scale(scale: 0.88).combined(with: .opacity))
            }
        }
        .scaleEffect(appeared ? 1 : 0.84)
        .opacity(appeared ? 1 : 0)
        .onHover { hovering in withAnimation(spring) { isHovered = hovering } }
        .onTapGesture(count: 2) { openSetup() }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) { appeared = true }
            if manager.isRunning { startPulse() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openTimerSetup)) { _ in
            withAnimation(spring) { showSetup = true }
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
            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .fill(PomodoroTheme.primaryColor(for: manager.currentState)
                        .opacity(manager.justChanged ? 0.2 : 0))
                .animation(.easeOut(duration: 0.55), value: manager.justChanged)

            // Glass card
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 44, style: .continuous)
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
                .padding(.horizontal, 28)
                .padding(.top, 26)

                Spacer(minLength: 0)

                // ── Timer circle ─────────────────────────────────────────
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
                                startRadius: 55,
                                endRadius: 115
                            )
                        )
                        .frame(width: 230, height: 230)
                        .animation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true), value: pulseGlow)

                    // Track + arc
                    ProgressCircle(
                        progress: manager.progress,
                        gradient: PomodoroTheme.gradient(for: manager.currentState),
                        primaryColor: PomodoroTheme.primaryColor(for: manager.currentState),
                        lineWidth: 14
                    )
                    .frame(width: 168, height: 168)

                    // Time text
                    VStack(spacing: 3) {
                        Text(timeString(from: manager.timeRemaining))
                            .monospacedDigit()
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: manager.timeRemaining)
                            // Breathing scale when paused
                            .scaleEffect(!manager.isRunning && manager.currentState != .idle
                                         ? (pulseGlow ? 1.04 : 0.97) : 1.0)
                            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulseGlow)
                    }
                }

                Spacer(minLength: 0)

                // ── Session dots (4-pomodoro cycle) ──────────────────────
                HStack(spacing: 9) {
                    ForEach(0..<4) { i in
                        let filled = i < (manager.completedSessions % 4)
                        Circle()
                            .fill(filled
                                  ? PomodoroTheme.primaryColor(for: .work)
                                  : Color.white.opacity(0.18))
                            .frame(width: 8, height: 8)
                            .shadow(color: filled
                                    ? PomodoroTheme.primaryColor(for: .work).opacity(0.7)
                                    : .clear, radius: 4)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(i) * 0.06),
                                       value: manager.completedSessions)
                    }
                }

                Spacer(minLength: 0)

                // ── Controls ─────────────────────────────────────────────
                HStack(spacing: 24) {
                    ControlButton(icon: "arrow.clockwise", color: .white.opacity(0.5)) {
                        withAnimation(spring) { manager.reset() }
                    }

                    // Primary play/pause (larger)
                    ControlButton(
                        icon: manager.isRunning ? "pause.fill" : "play.fill",
                        color: .white,
                        size: 58,
                        iconSize: 22
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
                            .frame(width: 66, height: 66)
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
            .frame(height: 400)
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
                        lineWidth: 3
                    )
                    .frame(width: 26, height: 26)

                    VStack(alignment: .leading, spacing: -1) {
                        Text(manager.currentState.title)
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(PomodoroTheme.primaryColor(for: manager.currentState).opacity(0.85))
                            .textCase(.uppercase)
                            .animation(spring, value: manager.currentState)

                        Text(timeString(from: manager.timeRemaining))
                            .monospacedDigit()
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: manager.timeRemaining)
                    }
                }
                .frame(width: 130, alignment: .leading)
                .padding(.leading, 20)
                .padding(.top, 14)

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
                .frame(width: 120, alignment: .trailing)
                .padding(.trailing, 20)
                .padding(.top, 14)
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

#Preview {
    PomodoroContentView()
        .environmentObject(PomodoroManager())
}
