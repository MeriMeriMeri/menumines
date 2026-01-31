import Foundation
import Testing
@testable import MenuMines

@Suite("GameState Basic Tests")
struct GameStateBasicTests {

    @Test("Reveal changes status from notStarted to playing")
    func testRevealStartsGame() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.status == .notStarted)

        gameState.reveal(row: 0, col: 0)

        #expect(gameState.status == .playing)
    }

    @Test("Reveal a hidden cell changes its state")
    func testRevealChangesHiddenCell() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.board.cells[0][0].state == .hidden)

        gameState.reveal(row: 0, col: 0)

        if case .revealed = gameState.board.cells[0][0].state {
            // Cell is now revealed
        } else {
            Issue.record("Expected cell to be revealed")
        }
    }

    @Test("Toggle flag on hidden cell")
    func testToggleFlagOnHiddenCell() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Start the game first (flags only allowed after first reveal)
        gameState.reveal(row: 0, col: 0)

        // Find a hidden cell to flag
        var flagRow = -1, flagCol = -1
        outer: for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                if case .hidden = gameState.board.cells[r][c].state {
                    flagRow = r
                    flagCol = c
                    break outer
                }
            }
        }

        guard flagRow >= 0 else {
            Issue.record("No hidden cell found")
            return
        }

        #expect(gameState.flagCount == 0)

        gameState.toggleFlag(row: flagRow, col: flagCol)

        #expect(gameState.flagCount == 1)
        #expect(gameState.board.cells[flagRow][flagCol].state == .flagged)
    }

    @Test("Toggle flag off a flagged cell")
    func testToggleFlagOffFlaggedCell() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Start the game first (flags only allowed after first reveal)
        gameState.reveal(row: 0, col: 0)

        // Find a hidden cell to flag
        var flagRow = -1, flagCol = -1
        outer: for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                if case .hidden = gameState.board.cells[r][c].state {
                    flagRow = r
                    flagCol = c
                    break outer
                }
            }
        }

        guard flagRow >= 0 else {
            Issue.record("No hidden cell found")
            return
        }

        gameState.toggleFlag(row: flagRow, col: flagCol)
        #expect(gameState.flagCount == 1)

        gameState.toggleFlag(row: flagRow, col: flagCol)
        #expect(gameState.flagCount == 0)
        #expect(gameState.board.cells[flagRow][flagCol].state == .hidden)
    }

    @Test("Cannot reveal a flagged cell")
    func testCannotRevealFlaggedCell() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Start the game first (flags only allowed after first reveal)
        gameState.reveal(row: 0, col: 0)

        // Find a hidden cell to flag
        var flagRow = -1, flagCol = -1
        outer: for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                if case .hidden = gameState.board.cells[r][c].state {
                    flagRow = r
                    flagCol = c
                    break outer
                }
            }
        }

        guard flagRow >= 0 else {
            Issue.record("No hidden cell found")
            return
        }

        gameState.toggleFlag(row: flagRow, col: flagCol)
        gameState.reveal(row: flagRow, col: flagCol)

        // Cell should still be flagged
        #expect(gameState.board.cells[flagRow][flagCol].state == .flagged)
    }

    @Test("Cannot flag a revealed cell")
    func testCannotFlagRevealedCell() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Reveal a cell first
        gameState.reveal(row: 0, col: 0)
        let initialFlagCount = gameState.flagCount

        // Try to flag the revealed cell
        gameState.toggleFlag(row: 0, col: 0)

        // Cell should still be revealed, flag count unchanged
        if case .revealed = gameState.board.cells[0][0].state {
            // Cell is still revealed
        } else {
            Issue.record("Expected cell to remain revealed")
        }
        #expect(gameState.flagCount == initialFlagCount)
    }
}
