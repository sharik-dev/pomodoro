import SwiftUI

struct PomodoroTheme {
    static let workColor = Color.orange
    static let shortBreakColor = Color.green
    static let longBreakColor = Color.blue
    static let idleColor = Color.gray
    
    static func color(for state: PomodoroState) -> Color {
        switch state {
        case .work: return workColor
        case .shortBreak: return shortBreakColor
        case .longBreak: return longBreakColor
        case .idle: return idleColor
        }
    }
}
