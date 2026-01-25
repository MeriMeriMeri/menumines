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
        .padding(4)
        .background(Color.gray.opacity(0.3))
        .cornerRadius(6)
    }
}

#Preview {
    GameBoardView(
        board: Board(seed: 12345),
        gameStatus: .notStarted,
        selectedRow: 0,
        selectedCol: 0,
        onReveal: { _, _ in },
        onFlag: { _, _ in }
    )
    .padding()
}
