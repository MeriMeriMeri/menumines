import SwiftUI

struct MenuContentView: View {
    var gameState: GameState

    var body: some View {
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

            FooterView(onReset: {
                gameState.reset()
            })
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            gameState.resumeTimer()
        }
        .onDisappear {
            gameState.pauseTimer()
        }
    }
}

#Preview {
    MenuContentView(gameState: GameState(board: Board(seed: 12345)))
}
