import SwiftUI
import AppKit
import Combine

@main
struct pomodoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: PomodoroWindow?
    var statusItem: NSStatusItem?
    let manager = PomodoroManager()

    private var cancellables = Set<AnyCancellable>()
    private var toggleMenuItem: NSMenuItem?
    private var workMenuItem: NSMenuItem?
    private var shortBreakMenuItem: NSMenuItem?
    private var longBreakMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()

        let rootView = PomodoroContentView().environmentObject(manager)
        let hosting = NSHostingView(rootView: rootView)
        hosting.sizingOptions = []                      // prevent SwiftUI fighting NSWindow frame
        window = PomodoroWindow(contentView: hosting)
        window?.makeKeyAndOrderFront(nil)

        observeManager()
    }

    private func observeManager() {
        // Live menu-bar timer
        Publishers.CombineLatest3(manager.$timeRemaining, manager.$isRunning, manager.$currentState)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time, running, state in
                self?.updateStatusButton(time: time, running: running, state: state)
            }
            .store(in: &cancellables)

        // Menu item duration labels
        Publishers.CombineLatest3(manager.$workDuration, manager.$shortBreakDuration, manager.$longBreakDuration)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] w, s, l in
                self?.workMenuItem?.title       = "Focus  (\(Int(w / 60)) min)"
                self?.shortBreakMenuItem?.title = "Short Break  (\(Int(s / 60)) min)"
                self?.longBreakMenuItem?.title  = "Long Break  (\(Int(l / 60)) min)"
            }
            .store(in: &cancellables)

        // Full-screen celebration overlay on finish
        manager.$timerJustFinished
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                FinishOverlayWindow.show(for: self.manager.currentState)
            }
            .store(in: &cancellables)
    }

    private func updateStatusButton(time: TimeInterval, running: Bool, state: PomodoroState) {
        guard let button = statusItem?.button else { return }
        if running || (state != .idle && time > 0) {
            let m = Int(time) / 60, s = Int(time) % 60
            button.title = " \(String(format: "%02d:%02d", m, s))"
            button.image = NSImage(systemSymbolName: stateIcon(for: state), accessibilityDescription: state.title)
        } else {
            button.title = ""
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Pomodoro")
        }
        toggleMenuItem?.title = running ? "Pause" : (state == .idle ? "Start Focus" : "Resume")
    }

    private func stateIcon(for state: PomodoroState) -> String {
        switch state {
        case .work: return "flame.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "moon.zzz.fill"
        case .idle: return "timer"
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Pomodoro")
            button.imagePosition = .imageLeft
        }
        buildMenu()
    }

    private func buildMenu() {
        let menu = NSMenu()

        let w = NSMenuItem(title: "Focus  (25 min)",       action: #selector(startWork),       keyEquivalent: "1")
        let s = NSMenuItem(title: "Short Break  (5 min)",  action: #selector(startShortBreak), keyEquivalent: "2")
        let l = NSMenuItem(title: "Long Break  (15 min)",  action: #selector(startLongBreak),  keyEquivalent: "3")
        workMenuItem = w; shortBreakMenuItem = s; longBreakMenuItem = l
        menu.addItem(w); menu.addItem(s); menu.addItem(l)
        menu.addItem(.separator())

        let toggle = NSMenuItem(title: "Start Focus", action: #selector(toggleTimer), keyEquivalent: " ")
        toggleMenuItem = toggle
        menu.addItem(toggle)
        menu.addItem(NSMenuItem(title: "Reset", action: #selector(resetTimer), keyEquivalent: "r"))
        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: "Show Window",   action: #selector(showApp),   keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Setup Timer…",  action: #selector(openSetup), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc func startWork()       { manager.start(state: .work);       showApp() }
    @objc func startShortBreak() { manager.start(state: .shortBreak); showApp() }
    @objc func startLongBreak()  { manager.start(state: .longBreak);  showApp() }
    @objc func toggleTimer()     { manager.toggle() }
    @objc func resetTimer()      { manager.reset() }
    @objc func openSetup()       { showApp(); NotificationCenter.default.post(name: .openTimerSetup, object: nil) }
    @objc func showApp()         { window?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
}

extension Notification.Name {
    static let openTimerSetup = Notification.Name("openTimerSetup")
}
