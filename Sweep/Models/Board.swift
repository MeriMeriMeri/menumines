import Foundation
import GameplayKit

/// Result of revealing a cell.
enum RevealResult: Equatable {
    case safe(cellsRevealed: Int)
    case mine
}

/// The 8x8 Minesweeper game board.
struct Board: Equatable {
    static let rows = 8
    static let cols = 8
    static let mineCount = 10

    private(set) var cells: [[Cell]]

    /// Creates a new board with mines placed deterministically based on the seed.
    /// - Parameter seed: The seed for deterministic mine placement.
    init(seed: Int64) {
        // Stub: Create empty board with no mines
        // Track A (Story 3A) will implement actual mine placement
        cells = (0..<Board.rows).map { _ in
            (0..<Board.cols).map { _ in
                Cell(state: .hidden, hasMine: false)
            }
        }
    }

    /// Reveals the cell at the given position.
    /// - Returns: `.mine` if the cell contains a mine, `.safe(cellsRevealed:)` otherwise.
    mutating func reveal(row: Int, col: Int) -> RevealResult {
        // Stub: Track A (Story 4A) will implement
        guard row >= 0, row < Board.rows, col >= 0, col < Board.cols else {
            return .safe(cellsRevealed: 0)
        }
        guard case .hidden = cells[row][col].state else {
            return .safe(cellsRevealed: 0)
        }

        if cells[row][col].hasMine {
            cells[row][col].state = .revealed(adjacentMines: 0)
            return .mine
        }

        let adjacent = adjacentMineCount(row: row, col: col)
        cells[row][col].state = .revealed(adjacentMines: adjacent)
        return .safe(cellsRevealed: 1)
    }

    /// Toggles the flag state of a hidden cell.
    mutating func toggleFlag(row: Int, col: Int) {
        // Stub: Track A will implement
        guard row >= 0, row < Board.rows, col >= 0, col < Board.cols else { return }

        switch cells[row][col].state {
        case .hidden:
            cells[row][col].state = .flagged
        case .flagged:
            cells[row][col].state = .hidden
        case .revealed:
            break
        }
    }

    /// Marks the cell as the one that exploded (the clicked mine).
    mutating func markExploded(row: Int, col: Int) {
        guard row >= 0, row < Board.rows, col >= 0, col < Board.cols else { return }
        cells[row][col].isExploded = true
    }

    /// Relocates a mine from the given position to a random empty cell.
    /// Used for first-click safety.
    mutating func relocateMine(from row: Int, col: Int) {
        // Stub: Track A (Story 5A) will implement
        guard row >= 0, row < Board.rows, col >= 0, col < Board.cols else { return }
        guard cells[row][col].hasMine else { return }

        // Find empty cells
        var emptyCells: [(Int, Int)] = []
        for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                if !cells[r][c].hasMine && (r != row || c != col) {
                    emptyCells.append((r, c))
                }
            }
        }

        guard let target = emptyCells.randomElement() else { return }

        // Move the mine
        cells[row][col] = Cell(state: .hidden, hasMine: false)
        cells[target.0][target.1] = Cell(state: .hidden, hasMine: true)
    }

    /// Returns the count of mines in adjacent cells (including diagonals).
    func adjacentMineCount(row: Int, col: Int) -> Int {
        var count = 0
        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let r = row + dr
                let c = col + dc
                if r >= 0, r < Board.rows, c >= 0, c < Board.cols {
                    if cells[r][c].hasMine {
                        count += 1
                    }
                }
            }
        }
        return count
    }
}
