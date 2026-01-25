import SwiftUI

struct HeaderView: View {
    let status: GameStatus
    let elapsedTime: TimeInterval
    let flagCount: Int

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

    var body: some View {
        HStack {
            // Flag count
            HStack(spacing: 4) {
                Text("🚩")
                Text("\(flagCount)/\(Board.mineCount)")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
            }
            .frame(minWidth: 60, alignment: .leading)

            Spacer()

            // Status emoji
            Text(statusEmoji)
                .font(.system(size: 24))

            Spacer()

            // Timer
            Text(timeDisplay)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .frame(minWidth: 60, alignment: .trailing)
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Previews

#Preview("Not Started") {
    HeaderView(status: .notStarted, elapsedTime: 0, flagCount: 0)
        .padding()
}

#Preview("Playing") {
    HeaderView(status: .playing, elapsedTime: 125, flagCount: 3)
        .padding()
}

#Preview("Won") {
    HeaderView(status: .won, elapsedTime: 89, flagCount: 10)
        .padding()
}

#Preview("Lost") {
    HeaderView(status: .lost, elapsedTime: 45, flagCount: 5)
        .padding()
}
