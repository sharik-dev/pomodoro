import SwiftUI
import AppKit

struct PomodoroContentView: View {
    @StateObject var manager = PomodoroManager()
    @State private var isHovered = false
    
    var body: some View {
        ZStack {
            VisualEffectView(material: NSVisualEffectView.Material.hudWindow, blendingMode: NSVisualEffectView.BlendingMode.withinWindow)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "timer")
                    Text(timeString(from: manager.timeRemaining))
                        .monospacedDigit()
                        .font(.system(size: 24, weight: .bold))
                }
                .foregroundColor(PomodoroTheme.color(for: manager.currentState))
                
                if isHovered {
                    HStack(spacing: 12) {
                        Button(action: {
                            manager.toggle()
                        }) {
                            Image(systemName: manager.isRunning ? "pause.fill" : "play.fill")
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            manager.reset()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.opacity)
                }
                
                ProgressCircle(progress: manager.progress, color: PomodoroTheme.color(for: manager.currentState))
                    .frame(width: 40, height: 40)
            }
            .padding()
        }
        .frame(width: isHovered ? 180 : 120, height: 80)
        .onHover { hovering in
            withAnimation(.spring()) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button("Work (25m)") { manager.start(state: .work) }
            Button("Short Break (5m)") { manager.start(state: .shortBreak) }
            Button("Long Break (15m)") { manager.start(state: .longBreak) }
            Divider()
            Button("Reset") { manager.reset() }
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
    }
    
    func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct ProgressCircle: View {
    var progress: Double
    var color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 4)
                .opacity(0.3)
                .foregroundColor(color)
            
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
        }
    }
}

#Preview {
    PomodoroContentView()
}
