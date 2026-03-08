import SwiftUI

struct TimerSetupView: View {
    @EnvironmentObject var manager: PomodoroManager
    @Binding var isPresented: Bool

    @State private var workMinutes: Double = 25
    @State private var shortBreakMinutes: Double = 5
    @State private var longBreakMinutes: Double = 15
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                Text("Timer Setup")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { close() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 8) {
                DurationRow(
                    label: "Focus",
                    icon: "flame.fill",
                    color: Color(nsColor: .systemOrange),
                    value: $workMinutes,
                    range: 1...90
                )
                DurationRow(
                    label: "Short Break",
                    icon: "cup.and.saucer.fill",
                    color: Color(nsColor: .systemTeal),
                    value: $shortBreakMinutes,
                    range: 1...30
                )
                DurationRow(
                    label: "Long Break",
                    icon: "moon.zzz.fill",
                    color: Color(nsColor: .systemPurple),
                    value: $longBreakMinutes,
                    range: 1...60
                )
            }

            HStack(spacing: 8) {
                Button("Cancel") { close() }
                    .buttonStyle(SetupButtonStyle(isPrimary: false))

                Button("Apply") {
                    NSApp.keyWindow?.makeFirstResponder(nil)
                    DispatchQueue.main.async {
                        manager.workDuration = workMinutes * 60
                        manager.shortBreakDuration = shortBreakMinutes * 60
                        manager.longBreakDuration = longBreakMinutes * 60
                        manager.reset()
                        close()
                    }
                }
                .buttonStyle(SetupButtonStyle(isPrimary: true))
            }
        }
        .padding(14)
        .background(
            ZStack {
                VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                Color.black.opacity(0.3)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15)
        .frame(width: 220)
        .scaleEffect(appeared ? 1 : 0.88)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            workMinutes = manager.workDuration / 60
            shortBreakMinutes = manager.shortBreakDuration / 60
            longBreakMinutes = manager.longBreakDuration / 60
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }

    private func close() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { appeared = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { isPresented = false }
    }
}

// MARK: - DurationRow with direct text input

struct DurationRow: View {
    let label: String
    let icon: String
    let color: Color
    @Binding var value: Double
    let range: ClosedRange<Double>

    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 14)

            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            Spacer()

            // Input field
            HStack(spacing: 4) {
                TextField("", text: $text)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(.white)
                    .frame(width: 30)
                    .focused($focused)
                    .onSubmit { commit() }
                    .onChange(of: text) {
                        // Strip non-digits
                        let filtered = text.filter { $0.isNumber }
                        if filtered != text { text = filtered }
                    }
                    // Commit on focus loss
                    .onChange(of: focused) { if !focused { commit() } }

                Text("min")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(focused ? 0.12 : 0.07))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(focused ? color.opacity(0.7) : Color.clear, lineWidth: 1.5)
            )
            .animation(.easeInOut(duration: 0.15), value: focused)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.06))
        .cornerRadius(9)
        .onAppear { text = "\(Int(value))" }
        .onChange(of: value) { text = "\(Int(value))" }
    }

    private func commit() {
        guard let n = Double(text) else { text = "\(Int(value))"; return }
        let clamped = min(max(n, range.lowerBound), range.upperBound)
        value = clamped
        text = "\(Int(clamped))"
    }
}

// MARK: - SetupButtonStyle

struct SetupButtonStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(isPrimary ? .black : .white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isPrimary ? Color.white : Color.white.opacity(0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.75), value: configuration.isPressed)
    }
}
