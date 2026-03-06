import Foundation
import SwiftUI
import Combine
import UserNotifications

enum PomodoroState {
    case work
    case shortBreak
    case longBreak
    case idle
    
    var duration: TimeInterval {
        switch self {
        case .work: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        case .idle: return 0
        }
    }
    
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
    
    private var timer: AnyCancellable?
    private var totalDuration: TimeInterval = 0
    
    init() {
        requestNotificationPermission()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    func start(state: PomodoroState) {
        currentState = state
        totalDuration = state.duration
        timeRemaining = totalDuration
        isRunning = true
        updateProgress()
        
        setupTimer()
    }
    
    func toggle() {
        if isRunning {
            pause()
        } else {
            resume()
        }
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
    
    private func setupTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
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
        if totalDuration > 0 {
            progress = timeRemaining / totalDuration
        } else {
            progress = 1.0
        }
    }
    
    private func timerFinished() {
        pause()
        // Logic for auto-transition or notification can go here
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
