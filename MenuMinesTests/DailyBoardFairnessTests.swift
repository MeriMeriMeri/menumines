import Foundation
import Testing
@testable import MenuMines

/// The daily puzzle's whole premise is that everyone plays the same board. These tests pin
/// that down, because it silently was not true: the board used to be reshaped around
/// whichever cell the player happened to open first.
@Suite("Daily Board Fairness Tests", .serialized)
struct DailyBoardFairnessTests {

    private func minePositions(in board: Board) -> Set<Int> {
        var positions = Set<Int>()
        for row in 0..<Board.rows {
            for col in 0..<Board.cols where board.cells[row][col].hasMine {
                positions.insert(row * Board.cols + col)
            }
        }
        return positions
    }

    @Test("A daily board is the same for every player, whatever they open first")
    func testDailyBoardIsIdenticalRegardlessOfFirstClick() {
        let seed: Int64 = 20260725
        let reference = minePositions(in: Board(dailySeed: seed))

        // Safe cells only, so no game finishes and this suite never writes completion state
        // that other suites read. Relocation used to fire on any first click, not just a
        // mine, so safe cells are enough to prove it no longer happens.
        var cellsTried = 0
        for row in 0..<Board.rows {
            for col in 0..<Board.cols where !reference.contains(row * Board.cols + col) {
                let state = GameState(board: Board(dailySeed: seed), dailySeed: seed, puzzleType: .daily)
                // Cells inside the opening cascade are already revealed, so clicking them
                // is a no-op and leaves the game unstarted.
                guard case .hidden = state.board.cells[row][col].state else { continue }

                state.reveal(row: row, col: col)
                state.pauseTimer()
                cellsTried += 1

                #expect(
                    minePositions(in: state.board) == reference,
                    "Opening at (\(row), \(col)) moved mines, so that player is on a different board"
                )
                #expect(state.status == .playing)
            }
        }
        #expect(cellsTried > 0, "No hidden safe cells were exercised, so this proved nothing")
    }

    /// Board level on purpose: playing this through GameState risks opening a mine, which
    /// completes the daily and writes completion state that other suites race against.
    @Test("Two players who play the same day produce the same share grid")
    func testShareGridsMatchAcrossPlayers() {
        let seed: Int64 = 20260725
        let date = dateFromSeed(seed) ?? Date()

        var first = Board(dailySeed: seed)
        var second = Board(dailySeed: seed)

        let openings = hiddenSafeCells(in: first)
        guard let a = openings.first, let b = openings.last, a != b else {
            Issue.record("Need two distinct safe openings to compare")
            return
        }
        _ = first.reveal(row: a.row, col: a.col)
        _ = second.reveal(row: b.row, col: b.col)

        let firstGrid = ShareTextGenerator.generate(
            status: .lost, board: first, elapsedTime: 60, markedMinesCount: 0, date: date
        )
        let secondGrid = ShareTextGenerator.generate(
            status: .lost, board: second, elapsedTime: 60, markedMinesCount: 0, date: date
        )

        #expect(firstGrid == secondGrid, "Share grids must match or there is nothing to compare")
    }

    private func hiddenSafeCells(in board: Board) -> [(row: Int, col: Int)] {
        var found: [(row: Int, col: Int)] = []
        for row in 0..<Board.rows {
            for col in 0..<Board.cols {
                guard case .hidden = board.cells[row][col].state, !board.cells[row][col].hasMine else { continue }
                found.append((row, col))
            }
        }
        return found
    }

    @Test("The opening is safe and opens a cascade")
    func testOpeningIsSafeAndOpen() {
        for seed in Int64(20260101)...Int64(20260131) {
            let board = Board(dailySeed: seed)
            let opening = Board.openingCell(forSeed: seed)

            #expect(!board.cells[opening.row][opening.col].hasMine,
                    "Seed \(seed) put a mine on its own opening cell")
            #expect(board.adjacentMineCount(row: opening.row, col: opening.col) == 0,
                    "Seed \(seed) opening is not a zero cell, so it would not cascade")
            #expect(countRevealedCells(in: board) > 1, "Seed \(seed) opening did not cascade")
        }
    }

    @Test("Daily boards still carry the full complement of mines")
    func testDailyBoardMineCount() {
        for seed in Int64(20260101)...Int64(20260131) {
            #expect(minePositions(in: Board(dailySeed: seed)).count == Board.mineCount)
        }
    }

    @Test("The same seed always produces the same board")
    func testDailyBoardIsDeterministic() {
        let seed: Int64 = 20260725
        #expect(Board(dailySeed: seed) == Board(dailySeed: seed))
    }

    @Test("Different days produce different boards")
    func testDifferentDaysDiffer() {
        #expect(minePositions(in: Board(dailySeed: 20260725)) != minePositions(in: Board(dailySeed: 20260726)))
    }

    /// Deliberately at board level: driving this through GameState would complete a daily,
    /// which writes completion and snapshot state that other suites race against.
    @Test("A daily board's mines are live, since nothing relocates them out of the way")
    func testDailyMinesAreLive() {
        let board = Board(dailySeed: 20260725)

        guard let mine = findMineCell(in: board) else {
            Issue.record("No mine found")
            return
        }

        var copy = board
        #expect(copy.reveal(row: mine.row, col: mine.col) == .mine)
    }

    @Test("Random puzzles keep first-click safety")
    func testRandomPuzzleStillProtectsFirstClick() {
        let seed: Int64 = -987654321
        let board = Board(seed: seed)

        guard let mine = findMineCell(in: board) else {
            Issue.record("No mine found")
            return
        }

        let state = GameState(board: board, dailySeed: seed, puzzleType: .random)
        state.reveal(row: mine.row, col: mine.col)

        #expect(state.status == .playing, "A random puzzle must not end on the opening click")
    }
}
