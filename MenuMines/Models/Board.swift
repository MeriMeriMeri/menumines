import Foundation
import GameplayKit

/// Result of revealing a cell.
enum RevealResult: Equatable {
    case safe(cellsRevealed: Int)
    case mine
}

/// The 9x9 Minesweeper game board.
struct Board: Equatable, Codable {
    static let rows = 9
    static let cols = 9
    static let mineCount = 12

    private(set) var cells: [[Cell]]

    private enum CodingKeys: String, CodingKey {
        case cells
    }

    /// Creates a board with pre-existing cells (used for persistence restoration).
    /// - Parameter cells: The cell grid to use.
    init(cells: [[Cell]]) {
        precondition(cells.count == Board.rows, "Board must have \(Board.rows) rows")
        precondition(cells.allSatisfy { $0.count == Board.cols }, "Each row must have \(Board.cols) columns")
        self.cells = cells
    }

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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedCells = try container.decode([[Cell]].self, forKey: .cells)

        guard decodedCells.count == Board.rows else {
            throw DecodingError.dataCorruptedError(
                forKey: .cells,
                in: container,
                debugDescription: "Expected \(Board.rows) rows, got \(decodedCells.count)"
            )
        }
        guard decodedCells.allSatisfy({ $0.count == Board.cols }) else {
            throw DecodingError.dataCorruptedError(
                forKey: .cells,
                in: container,
                debugDescription: "Expected \(Board.cols) columns in each row"
            )
        }

        self.cells = decodedCells
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cells, forKey: .cells)
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
            cells[row][col].isExploded = true
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

    /// Reveals all mines on the board (used when game is lost).
    /// Preserves flagged mines so correct flags remain visible.
    /// Does not mark them as exploded - only the clicked mine gets that flag.
    mutating func revealAllMines() {
        for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                if cells[r][c].hasMine && !cells[r][c].isExploded {
                    if case .flagged = cells[r][c].state { continue }
                    cells[r][c].state = .revealed(adjacentMines: 0)
                }
            }
        }
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
        countAdjacentCells(row: row, col: col) { $0.hasMine }
    }

    /// Returns the count of flagged cells adjacent to the given position.
    func adjacentFlagCount(row: Int, col: Int) -> Int {
        countAdjacentCells(row: row, col: col) { cell in
            if case .flagged = cell.state { return true }
            return false
        }
    }

    private func countAdjacentCells(row: Int, col: Int, matching predicate: (Cell) -> Bool) -> Int {
        var count = 0
        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let r = row + dr
                let c = col + dc
                if r >= 0, r < Board.rows, c >= 0, c < Board.cols {
                    if predicate(cells[r][c]) {
                        count += 1
                    }
                }
            }
        }
        return count
    }

    /// Performs a chord reveal on a revealed number cell.
    /// If the adjacent flag count matches the cell's number, reveals all unflagged adjacent cells.
    /// - Returns: `.mine` if any revealed cell contains a mine, `.safe(cellsRevealed:)` otherwise.
    mutating func chordReveal(row: Int, col: Int) -> RevealResult {
        guard row >= 0, row < Board.rows, col >= 0, col < Board.cols else {
            return .safe(cellsRevealed: 0)
        }

        guard case .revealed(let adjacentMines) = cells[row][col].state, adjacentMines > 0 else {
            return .safe(cellsRevealed: 0)
        }

        let flagCount = adjacentFlagCount(row: row, col: col)
        guard flagCount == adjacentMines else {
            return .safe(cellsRevealed: 0)
        }

        var totalRevealed = 0
        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let r = row + dr
                let c = col + dc
                guard r >= 0, r < Board.rows, c >= 0, c < Board.cols else { continue }
                guard case .hidden = cells[r][c].state else { continue }

                switch reveal(row: r, col: c) {
                case .mine:
                    return .mine
                case .safe(let count):
                    totalRevealed += count
                }
            }
        }

        return .safe(cellsRevealed: totalRevealed)
    }
}
