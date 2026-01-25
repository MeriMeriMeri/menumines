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
        cells = (0..<Board.rows).map { _ in
            (0..<Board.cols).map { _ in
                Cell(state: .hidden, hasMine: false)
            }
        }

        let rng = GKLinearCongruentialRandomSource(seed: UInt64(bitPattern: seed))

        var minePositions = Set<Int>()
        let totalCells = Board.rows * Board.cols
        precondition(Board.mineCount <= totalCells, "Cannot place \(Board.mineCount) mines in \(totalCells) cells")

        while minePositions.count < Board.mineCount {
            let position = rng.nextInt(upperBound: totalCells)
            minePositions.insert(position)
        }

        for position in minePositions {
            let row = position / Board.cols
            let col = position % Board.cols
            cells[row][col] = Cell(state: .hidden, hasMine: true)
        }
    }

    /// Reveals the cell at the given position with flood-fill cascade for zero-adjacent cells.
    /// - Returns: `.mine` if the cell contains a mine, `.safe(cellsRevealed:)` otherwise.
    mutating func reveal(row: Int, col: Int) -> RevealResult {
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

        // Flood-fill reveal using a stack
        var stack = [(row, col)]
        var cellsRevealed = 0

        while let (r, c) = stack.popLast() {
            // Skip if out of bounds
            guard r >= 0, r < Board.rows, c >= 0, c < Board.cols else { continue }
            // Skip if not hidden (already revealed or flagged)
            guard case .hidden = cells[r][c].state else { continue }
            // Skip mines
            guard !cells[r][c].hasMine else { continue }

            let adjacent = adjacentMineCount(row: r, col: c)
            cells[r][c].state = .revealed(adjacentMines: adjacent)
            cellsRevealed += 1

            // If zero adjacent mines, add all 8 neighbors to the stack
            if adjacent == 0 {
                for dr in -1...1 {
                    for dc in -1...1 {
                        if dr == 0 && dc == 0 { continue }
                        stack.append((r + dr, c + dc))
                    }
                }
            }
        }

        return .safe(cellsRevealed: cellsRevealed)
    }

    /// Toggles the flag state of a hidden cell.
    mutating func toggleFlag(row: Int, col: Int) {
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
