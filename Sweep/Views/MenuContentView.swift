import SwiftUI
import AppKit

struct MenuContentView: View {
    var gameState: GameState

    @AppStorage(Constants.SettingsKeys.confirmBeforeReset) private var confirmBeforeReset = false
    @State private var showResetConfirmation = false
    @State private var showCelebration = false

    private var isGameComplete: Bool {
        gameState.status == .won || gameState.status == .lost
    }

    private func copyShareTextToClipboard() {
        guard let text = gameState.shareText(for: Date()) else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func handleResetRequest() {
        // Prevent multiple reset requests while confirmation dialog is already showing
        guard !showResetConfirmation else { return }

        if confirmBeforeReset {
            showResetConfirmation = true
        } else {
            performReset()
        }
    }

    private func performReset() {
        gameState.reset()
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
                    flagCount: gameState.flagCount,
                    canReset: gameState.canReset,
                    onReset: handleResetRequest
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

                FooterView(
                    isGameComplete: isGameComplete,
                    canReset: gameState.canReset,
                    onReset: handleResetRequest,
                    onShare: {
                        copyShareTextToClipboard()
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
            gameState.checkForDailyRollover()
            gameState.resumeTimer()
        }
        .onDisappear {
            gameState.pauseTimer()
            gameState.save()
        }
        .onChange(of: gameState.status) { oldStatus, newStatus in
            switch newStatus {
            case .won:
                showCelebration = true
                announceGameResult(won: true)
                gameState.save()
            case .lost:
                announceGameResult(won: false)
                gameState.save()
            case .playing:
                // Clear celebration when resetting from won state
                if oldStatus == .won {
                    showCelebration = false
                }
            case .notStarted:
                // Clear celebration when resetting from won state
                if oldStatus == .won {
                    showCelebration = false
                }
            }
        }
        .alert(
            String(localized: "reset_confirmation_title"),
            isPresented: $showResetConfirmation
        ) {
            Button(String(localized: "reset_confirmation_cancel"), role: .cancel) {}
            Button(String(localized: "reset_confirmation_confirm"), role: .destructive) {
                performReset()
            }
        } message: {
            Text(String(localized: "reset_confirmation_message"))
        }
    }
}

#Preview {
    MenuContentView(gameState: GameState(board: Board(seed: 12345)))
}
