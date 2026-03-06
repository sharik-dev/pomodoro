import SwiftUI
import AppKit

@main
struct pomodoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: PomodoroWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = NSHostingView(rootView: PomodoroContentView())
        window = PomodoroWindow(contentView: contentView)
        window?.makeKeyAndOrderFront(nil)
    }
}
