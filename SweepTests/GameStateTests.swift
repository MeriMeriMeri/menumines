import Testing
@testable import Sweep

@Suite("GameState Tests")
struct GameStateTests {

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

    @Test("Reset restores initial state")
    func testResetRestoresInitialState() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Play the game
        gameState.reveal(row: 0, col: 0)
        gameState.toggleFlag(row: 1, col: 1)

        #expect(gameState.status == .playing)
        #expect(gameState.flagCount == 1)

        gameState.reset()

        #expect(gameState.status == .notStarted)
        #expect(gameState.elapsedTime == 0)
        #expect(gameState.flagCount == 0)
        #expect(gameState.selectedRow == 0)
        #expect(gameState.selectedCol == 0)
    }

    // MARK: - Selection Movement Tests

    @Test("Move selection up")
    func testMoveSelectionUp() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Start at (0, 0)
        #expect(gameState.selectedRow == 0)

        // Move down first to have room to move up
        gameState.moveSelection(.down)
        #expect(gameState.selectedRow == 1)

        // Now move up
        gameState.moveSelection(.up)
        #expect(gameState.selectedRow == 0)
    }

    @Test("Move selection down")
    func testMoveSelectionDown() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        gameState.moveSelection(.down)
        #expect(gameState.selectedRow == 1)
    }

    @Test("Move selection left")
    func testMoveSelectionLeft() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Start at (0, 0)
        #expect(gameState.selectedCol == 0)

        // Move right first
        gameState.moveSelection(.right)
        #expect(gameState.selectedCol == 1)

        // Now move left
        gameState.moveSelection(.left)
        #expect(gameState.selectedCol == 0)
    }

    @Test("Move selection right")
    func testMoveSelectionRight() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        gameState.moveSelection(.right)
        #expect(gameState.selectedCol == 1)
    }

    @Test("Selection stays at top boundary")
    func testSelectionStaysAtTopBoundary() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Already at row 0
        gameState.moveSelection(.up)
        #expect(gameState.selectedRow == 0)
    }

    @Test("Selection stays at bottom boundary")
    func testSelectionStaysAtBottomBoundary() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Move to bottom
        for _ in 0..<10 {
            gameState.moveSelection(.down)
        }
        #expect(gameState.selectedRow == 7)

        // Try to move past bottom
        gameState.moveSelection(.down)
        #expect(gameState.selectedRow == 7)
    }

    @Test("Selection stays at left boundary")
    func testSelectionStaysAtLeftBoundary() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Already at col 0
        gameState.moveSelection(.left)
        #expect(gameState.selectedCol == 0)
    }

    @Test("Selection stays at right boundary")
    func testSelectionStaysAtRightBoundary() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Move to right edge
        for _ in 0..<10 {
            gameState.moveSelection(.right)
        }
        #expect(gameState.selectedCol == 7)

        // Try to move past right
        gameState.moveSelection(.right)
        #expect(gameState.selectedCol == 7)
    }

    @Test("Reveal selected cell")
    func testRevealSelectedCell() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Move to (2, 3)
        gameState.moveSelection(.down)
        gameState.moveSelection(.down)
        gameState.moveSelection(.right)
        gameState.moveSelection(.right)
        gameState.moveSelection(.right)

        #expect(gameState.selectedRow == 2)
        #expect(gameState.selectedCol == 3)

        gameState.revealSelected()

        if case .revealed = gameState.board.cells[2][3].state {
            // Cell is revealed
        } else {
            Issue.record("Expected selected cell to be revealed")
        }
    }

    @Test("Toggle flag on selected cell")
    func testToggleFlagSelectedCell() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Move to (1, 1)
        gameState.moveSelection(.down)
        gameState.moveSelection(.right)

        gameState.toggleFlagSelected()

        #expect(gameState.board.cells[1][1].state == .flagged)
        #expect(gameState.flagCount == 1)
    }
}
