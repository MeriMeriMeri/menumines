import SwiftUI

struct HeaderView: View {
    let status: GameStatus
    let elapsedTime: TimeInterval
    let flagCount: Int
    let onReset: () -> Void

    private var timeDisplay: String {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var statusEmoji: String {
        switch status {
        case .notStarted, .playing:
            return "🙂"
        case .won:
            return "😎"
        case .lost:
            return "😵"
        }
    }

    private var statusDescription: String {
        switch status {
        case .notStarted:
            return String(localized: "status_ready")
        case .playing:
            return String(localized: "status_playing")
        case .won:
            return String(localized: "status_won")
        case .lost:
            return String(localized: "status_lost")
        }
    }

    private var timerAccessibilityLabel: String {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        if minutes == 0 {
            return seconds == 1 ? "Elapsed time: 1 second" : "Elapsed time: \(seconds) seconds"
        } else if minutes == 1 {
            return seconds == 0 ? "Elapsed time: 1 minute" : "Elapsed time: 1 minute, \(seconds) seconds"
        } else {
            return seconds == 0 ? "Elapsed time: \(minutes) minutes" : "Elapsed time: \(minutes) minutes, \(seconds) seconds"
        }
    }

    private var flagCountAccessibilityLabel: String {
        let remaining = Board.mineCount - flagCount
        if remaining == 1 {
            return "\(flagCount) flags placed, 1 mine remaining"
        } else {
            return "\(flagCount) flags placed, \(remaining) mines remaining"
        }
    }

    var body: some View {
        HStack {
            // Flag count
            HStack(spacing: 4) {
                Text("🚩")
                Text("\(flagCount)/\(Board.mineCount)")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
            }
            .frame(minWidth: 60, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(flagCountAccessibilityLabel)

            Spacer()

            // Status emoji - clickable to reset game
            Button(action: onReset) {
                Text(statusEmoji)
                    .font(.system(size: 24))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(format: String(localized: "reset_accessibility_combined"), statusDescription))
            .accessibilityHint(String(localized: "reset_accessibility_hint"))

            Spacer()

            // Timer
            Text(timeDisplay)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .frame(minWidth: 60, alignment: .trailing)
                .accessibilityLabel(timerAccessibilityLabel)
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Previews

#Preview("Not Started") {
    HeaderView(status: .notStarted, elapsedTime: 0, flagCount: 0, onReset: {})
        .padding()
}

#Preview("Playing") {
    HeaderView(status: .playing, elapsedTime: 125, flagCount: 3, onReset: {})
        .padding()
}

#Preview("Won") {
    HeaderView(status: .won, elapsedTime: 89, flagCount: 10, onReset: {})
        .padding()
}

#Preview("Lost") {
    HeaderView(status: .lost, elapsedTime: 45, flagCount: 5, onReset: {})
        .padding()
}
