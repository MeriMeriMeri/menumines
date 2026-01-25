import Foundation

/// The visibility state of a cell on the board.
enum CellState: Equatable {
    case hidden
    case revealed(adjacentMines: Int)
    case flagged
}

/// A single cell on the Minesweeper board.
struct Cell: Equatable {
    var state: CellState
    let hasMine: Bool
    var isExploded: Bool = false
}
