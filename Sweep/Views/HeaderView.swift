import SwiftUI

struct HeaderView: View {
    let status: GameStatus
    let elapsedTime: TimeInterval
    let flagCount: Int

    var body: some View {
        HStack {
            flagDisplay
            Spacer()
            statusEmoji
            Spacer()
            timerDisplay
        }
        .font(.system(size: 16, weight: .medium, design: .monospaced))
        .padding(.horizontal, 8)
    }

    private var flagDisplay: some View {
        HStack(spacing: 4) {
            Text("🚩")
            Text("\(flagCount)/\(Board.mineCount)")
                .foregroundStyle(.secondary)
        }
    }

    private var statusEmoji: some View {
        Text(statusIcon)
            .font(.system(size: 24))
    }

    private var statusIcon: String {
        switch status {
        case .notStarted, .playing:
            return "🙂"
        case .won:
            return "😎"
        case .lost:
            return "😵"
        }
    }

    private var timerDisplay: some View {
        Text(formattedTime)
            .foregroundStyle(.secondary)
    }

    private var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview("Not Started") {
    HeaderView(status: .notStarted, elapsedTime: 0, flagCount: 0)
        .padding()
}

#Preview("Playing") {
    HeaderView(status: .playing, elapsedTime: 125, flagCount: 3)
        .padding()
}

#Preview("Won") {
    HeaderView(status: .won, elapsedTime: 42, flagCount: 10)
        .padding()
}

#Preview("Lost") {
    HeaderView(status: .lost, elapsedTime: 15, flagCount: 2)
        .padding()
}
