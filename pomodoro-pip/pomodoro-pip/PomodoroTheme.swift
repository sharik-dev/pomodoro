import SwiftUI
import AppKit

struct PomodoroTheme {
    static let workGradient = Gradient(colors: [
        Color(nsColor: .systemOrange),
        Color(nsColor: .systemRed)
    ])

    static let shortBreakGradient = Gradient(colors: [
        Color(nsColor: .systemTeal),
        Color(nsColor: .systemGreen)
    ])

    static let longBreakGradient = Gradient(colors: [
        Color(nsColor: .systemPurple),
        Color(nsColor: .systemBlue)
    ])

    static let idleGradient = Gradient(colors: [
        Color(nsColor: .secondaryLabelColor),
        Color(nsColor: .labelColor)
    ])

    static func gradient(for state: PomodoroState) -> Gradient {
        switch state {
        case .work: return workGradient
        case .shortBreak: return shortBreakGradient
        case .longBreak: return longBreakGradient
        case .idle: return idleGradient
        }
    }

    static func primaryColor(for state: PomodoroState) -> Color {
        switch state {
        case .work: return Color(nsColor: .systemOrange)
        case .shortBreak: return Color(nsColor: .systemTeal)
        case .longBreak: return Color(nsColor: .systemPurple)
        case .idle: return Color(nsColor: .secondaryLabelColor)
        }
    }

    static func nsColor(for state: PomodoroState) -> NSColor {
        switch state {
        case .work: return .systemOrange
        case .shortBreak: return .systemTeal
        case .longBreak: return .systemPurple
        case .idle: return .secondaryLabelColor
        }
    }
}
