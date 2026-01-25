import SwiftUI

struct MenuContentView: View {
    var gameState: GameState

    @State private var showCelebration = false

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
            if newStatus == .won {
                showCelebration = true
            }
        }
    }
}

#Preview {
    MenuContentView(gameState: GameState(board: Board(seed: 12345)))
}
