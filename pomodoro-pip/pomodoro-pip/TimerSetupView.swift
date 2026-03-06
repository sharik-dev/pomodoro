import SwiftUI

struct TimerSetupView: View {
    @EnvironmentObject var manager: PomodoroManager
    @Binding var isPresented: Bool

    @State private var workMinutes: Double = 25
    @State private var shortBreakMinutes: Double = 5
    @State private var longBreakMinutes: Double = 15
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                Text("Timer Setup")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { close() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 10) {
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

            HStack(spacing: 10) {
                Button("Cancel") { close() }
                    .buttonStyle(SetupButtonStyle(isPrimary: false))

                Button("Apply") {
                    manager.workDuration = workMinutes * 60
                    manager.shortBreakDuration = shortBreakMinutes * 60
                    manager.longBreakDuration = longBreakMinutes * 60
                    manager.reset()
                    close()
                }
                .buttonStyle(SetupButtonStyle(isPrimary: true))
            }
        }
        .padding(22)
        .background(
            ZStack {
                VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                Color.black.opacity(0.3)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
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
        .frame(width: 272)
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
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            appeared = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }
}

struct DurationRow: View {
    let label: String
    let icon: String
    let color: Color
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 18)

            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            Spacer()

            HStack(spacing: 6) {
                Button(action: {
                    if value > range.lowerBound {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            value -= 1
                        }
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.35))
                }
                .buttonStyle(.plain)

                Text("\(Int(value)) min")
                    .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(.white)
                    .frame(width: 54, alignment: .center)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: value)

                Button(action: {
                    if value < range.upperBound {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            value += 1
                        }
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }
}

struct SetupButtonStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(isPrimary ? .black : .white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isPrimary ? Color.white : Color.white.opacity(0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.75), value: configuration.isPressed)
    }
}
