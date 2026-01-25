import SwiftUI
import AppKit

struct MenuContentView: View {
    var gameState: GameState

    @State private var showCelebration = false

    private var isGameComplete: Bool {
        gameState.status == .won || gameState.status == .lost
    }

    private func copyShareTextToClipboard() {
        guard let text = gameState.shareText() else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func announceGameResult(won: Bool) {
        let message: String
        if won {
            let seconds = Int(gameState.elapsedTime)
            if seconds == 1 {
                message = "Congratulations! You won in 1 second"
            } else {
                message = "Congratulations! You won in \(seconds) seconds"
            }
        } else {
            message = "Game over. You hit a mine"
        }
        AccessibilityNotification.Announcement(message).post()
    }

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                HeaderView(
                    status: gameState.status,
                    elapsedTime: gameState.elapsedTime,
                    flagCount: gameState.flagCount
                )

                GameBoardView(
                    board: gameState.board,
                    gameStatus: gameState.status,
                    selectedRow: gameState.selectedRow,
                    selectedCol: gameState.selectedCol,
                    onReveal: { row, col in
                        gameState.reveal(row: row, col: col)
                    },
                    onFlag: { row, col in
                        gameState.toggleFlag(row: row, col: col)
                    }
                )

                if isGameComplete {
                    Button(String(localized: "share_button")) {
                        copyShareTextToClipboard()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(String(localized: "share_button"))
                }

                FooterView(
                    onReset: {
                        showCelebration = false
                        gameState.reset()
                    },
                    onAbout: {
                        AboutWindow.show()
                    }
                )
            }
            .padding()

            ConfettiView(isActive: showCelebration)
        }
        .frame(width: 300)
        .onAppear {
            gameState.resumeTimer()
        }
        .onDisappear {
            gameState.pauseTimer()
        }
        .onChange(of: gameState.status) { _, newStatus in
            switch newStatus {
            case .won:
                showCelebration = true
                announceGameResult(won: true)
            case .lost:
                announceGameResult(won: false)
            default:
                break
            }
        }
    }
}

#Preview {
    MenuContentView(gameState: GameState(board: Board(seed: 12345)))
}
