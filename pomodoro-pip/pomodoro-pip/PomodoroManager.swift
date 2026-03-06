import Foundation
import SwiftUI
import Combine
import UserNotifications

enum PomodoroState: Equatable {
    case work
    case shortBreak
    case longBreak
    case idle

    var title: String {
        switch self {
        case .work: return "Working"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        case .idle: return "Ready"
        }
    }
}

class PomodoroManager: ObservableObject {
    @Published var currentState: PomodoroState = .idle
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var progress: Double = 1.0
    @Published var isDynamicIslandMode: Bool = false
    @Published var justChanged: Bool = false
    @Published var timerJustFinished: Bool = false
    @Published var completedSessions: Int = 0

    @Published var workDuration: TimeInterval = 25 * 60
    @Published var shortBreakDuration: TimeInterval = 5 * 60
    @Published var longBreakDuration: TimeInterval = 15 * 60

    private var timer: AnyCancellable?
    private var totalDuration: TimeInterval = 0

    init() {
        requestNotificationPermission()
    }

    func durationFor(state: PomodoroState) -> TimeInterval {
        switch state {
        case .work: return workDuration
        case .shortBreak: return shortBreakDuration
        case .longBreak: return longBreakDuration
        case .idle: return 0
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func start(state: PomodoroState) {
        currentState = state
        totalDuration = durationFor(state: state)
        timeRemaining = totalDuration
        isRunning = true
        updateProgress()
        triggerStateChange()
        setupTimer()
    }

    func toggle() {
        if isRunning { pause() } else { resume() }
    }

    func pause() {
        isRunning = false
        timer?.cancel()
    }

    func resume() {
        if currentState == .idle {
            start(state: .work)
        } else {
            isRunning = true
            setupTimer()
        }
    }

    func reset() {
        pause()
        currentState = .idle
        timeRemaining = 0
        progress = 1.0
    }

    func triggerStateChange() {
        justChanged = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.justChanged = false
        }
    }

    private func setupTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
            updateProgress()
        } else {
            timerFinished()
        }
    }

    private func updateProgress() {
        progress = totalDuration > 0 ? timeRemaining / totalDuration : 1.0
    }

    private func timerFinished() {
        pause()
        if currentState == .work {
            completedSessions += 1
        }
        triggerStateChange()
        timerJustFinished = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.timerJustFinished = false
        }
        sendNotification()
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro Finished"
        content.body = "Time for a \(currentState == .work ? "break" : "session")!"
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
