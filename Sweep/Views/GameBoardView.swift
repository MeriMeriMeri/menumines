import SwiftUI

struct GameBoardView: View {
    let board: Board
    let gameStatus: GameStatus
    let selectedRow: Int
    let selectedCol: Int
    let onReveal: (Int, Int) -> Void
    let onFlag: (Int, Int) -> Void

    var body: some View {
        VStack(spacing: 1) {
            ForEach(0..<Board.rows, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<Board.cols, id: \.self) { col in
                        CellView(
                            cell: board.cells[row][col],
                            gameStatus: gameStatus,
                            isSelected: row == selectedRow && col == selectedCol,
                            onReveal: { onReveal(row, col) },
                            onFlag: { onFlag(row, col) }
                        )
                    }
                }
            }
        }
        .background(Color(nsColor: .separatorColor))
    }
}

// MARK: - Preview Helpers

extension Board {
    static func mockForPreview() -> Board {
        var board = Board(seed: 12345)
        // Reveal a few cells to show different states
        _ = board.reveal(row: 0, col: 0)
        _ = board.reveal(row: 1, col: 1)
        _ = board.reveal(row: 2, col: 2)
        board.toggleFlag(row: 3, col: 3)
        return board
    }

    static func mockWithMines() -> Board {
        let board = Board(seed: 12345)
        // Manually set some mines for preview
        // Note: This is a test helper, real mine placement comes from Story 3A
        return board
    }
}

// MARK: - Previews

#Preview("Game Board") {
    GameBoardView(
        board: Board.mockForPreview(),
        gameStatus: .playing,
        selectedRow: 4,
        selectedCol: 4,
        onReveal: { _, _ in },
        onFlag: { _, _ in }
    )
    .padding()
}

#Preview("Game Board - Not Started") {
    GameBoardView(
        board: Board(seed: 20240315),
        gameStatus: .notStarted,
        selectedRow: 0,
        selectedCol: 0,
        onReveal: { _, _ in },
        onFlag: { _, _ in }
    )
    .padding()
}
