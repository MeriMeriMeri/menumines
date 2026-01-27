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

        #expect(gameState.flagCount == 0)
        #expect(gameState.board.cells[0][0].state == .hidden)

        gameState.toggleFlag(row: 0, col: 0)

        #expect(gameState.flagCount == 1)
        #expect(gameState.board.cells[0][0].state == .flagged)
    }

    @Test("Toggle flag off a flagged cell")
    func testToggleFlagOffFlaggedCell() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        gameState.toggleFlag(row: 0, col: 0)
        #expect(gameState.flagCount == 1)

        gameState.toggleFlag(row: 0, col: 0)
        #expect(gameState.flagCount == 0)
        #expect(gameState.board.cells[0][0].state == .hidden)
    }

    @Test("Cannot reveal a flagged cell")
    func testCannotRevealFlaggedCell() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        gameState.toggleFlag(row: 0, col: 0)
        gameState.reveal(row: 0, col: 0)

        // Cell should still be flagged
        #expect(gameState.board.cells[0][0].state == .flagged)
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
