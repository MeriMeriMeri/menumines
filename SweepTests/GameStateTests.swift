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

    // MARK: - Story 5A: Win/Lose Detection and First-Click Safety

    @Test("Lose when clicking a mine")
    func testLoseWhenClickingMine() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // First, make a safe first click to start the game
        // Find a non-mine cell
        var safeRow = -1, safeCol = -1
        outer: for r in 0..<8 {
            for c in 0..<8 {
                if !gameState.board.cells[r][c].hasMine {
                    safeRow = r
                    safeCol = c
                    break outer
                }
            }
        }

        guard safeRow >= 0 else {
            Issue.record("No safe cell found")
            return
        }

        gameState.reveal(row: safeRow, col: safeCol)
        #expect(gameState.status == .playing)

        // Now find a mine cell and click it
        var mineRow = -1, mineCol = -1
        outer2: for r in 0..<8 {
            for c in 0..<8 {
                if gameState.board.cells[r][c].hasMine {
                    mineRow = r
                    mineCol = c
                    break outer2
                }
            }
        }

        guard mineRow >= 0 else {
            Issue.record("No mine found")
            return
        }

        gameState.reveal(row: mineRow, col: mineCol)

        #expect(gameState.status == .lost)
        #expect(gameState.board.cells[mineRow][mineCol].isExploded)
    }

    @Test("Win when all non-mine cells are revealed")
    func testWinWhenAllNonMinesRevealed() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Reveal all non-mine cells
        for r in 0..<8 {
            for c in 0..<8 {
                if !gameState.board.cells[r][c].hasMine {
                    gameState.reveal(row: r, col: c)
                }
            }
        }

        #expect(gameState.status == .won)
    }

    @Test("First click never hits a mine")
    func testFirstClickNeverHitsMine() {
        // Use a seed where we know position (0,0) has a mine
        // Try multiple seeds to find one where (0,0) has a mine
        var testSeed: Int64 = 1
        var foundSeed = false

        for seed in 1...1000 {
            let testBoard = Board(seed: Int64(seed))
            if testBoard.cells[0][0].hasMine {
                testSeed = Int64(seed)
                foundSeed = true
                break
            }
        }

        guard foundSeed else {
            Issue.record("Could not find a seed where (0,0) has a mine")
            return
        }

        // Now test that first click on (0,0) doesn't lose
        let board = Board(seed: testSeed)
        let gameState = GameState(board: board)

        // Verify the board originally has a mine at (0,0)
        #expect(board.cells[0][0].hasMine)

        // First click should not result in loss
        gameState.reveal(row: 0, col: 0)

        #expect(gameState.status == .playing, "First click should never lose, mine should be relocated")
        #expect(!gameState.board.cells[0][0].hasMine, "Mine should have been relocated from first click position")
    }

    @Test("First click relocates mine and preserves mine count")
    func testFirstClickRelocatesMinePreservesMineCount() {
        // Find a seed where (0,0) has a mine
        var testSeed: Int64 = 1
        for seed in 1...1000 {
            let testBoard = Board(seed: Int64(seed))
            if testBoard.cells[0][0].hasMine {
                testSeed = Int64(seed)
                break
            }
        }

        let board = Board(seed: testSeed)
        let gameState = GameState(board: board)

        // First click on (0,0) which has a mine
        gameState.reveal(row: 0, col: 0)

        // Count mines after first click
        var mineCount = 0
        for r in 0..<8 {
            for c in 0..<8 {
                if gameState.board.cells[r][c].hasMine {
                    mineCount += 1
                }
            }
        }

        #expect(mineCount == 10, "Mine count should remain 10 after first-click relocation")
    }

    @Test("Cannot reveal after game is lost")
    func testCannotRevealAfterGameLost() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Make a safe first click
        var safeRow = -1, safeCol = -1
        outer: for r in 0..<8 {
            for c in 0..<8 {
                if !gameState.board.cells[r][c].hasMine {
                    safeRow = r
                    safeCol = c
                    break outer
                }
            }
        }
        gameState.reveal(row: safeRow, col: safeCol)

        // Click a mine to lose
        var mineRow = -1, mineCol = -1
        outer2: for r in 0..<8 {
            for c in 0..<8 {
                if gameState.board.cells[r][c].hasMine {
                    mineRow = r
                    mineCol = c
                    break outer2
                }
            }
        }
        gameState.reveal(row: mineRow, col: mineCol)
        #expect(gameState.status == .lost)

        // Find another hidden cell
        var hiddenRow = -1, hiddenCol = -1
        outer3: for r in 0..<8 {
            for c in 0..<8 {
                if case .hidden = gameState.board.cells[r][c].state {
                    hiddenRow = r
                    hiddenCol = c
                    break outer3
                }
            }
        }

        guard hiddenRow >= 0 else {
            return // No hidden cells to test
        }

        // Try to reveal - should have no effect
        gameState.reveal(row: hiddenRow, col: hiddenCol)
        #expect(gameState.board.cells[hiddenRow][hiddenCol].state == .hidden, "Should not be able to reveal after losing")
    }

    @Test("Cannot reveal after game is won")
    func testCannotRevealAfterGameWon() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Win the game by revealing all non-mine cells
        for r in 0..<8 {
            for c in 0..<8 {
                if !gameState.board.cells[r][c].hasMine {
                    gameState.reveal(row: r, col: c)
                }
            }
        }
        #expect(gameState.status == .won)

        // Find a mine cell (still hidden)
        var mineRow = -1, mineCol = -1
        outer: for r in 0..<8 {
            for c in 0..<8 {
                if gameState.board.cells[r][c].hasMine {
                    mineRow = r
                    mineCol = c
                    break outer
                }
            }
        }

        guard mineRow >= 0 else {
            return
        }

        // Try to reveal - should have no effect
        gameState.reveal(row: mineRow, col: mineCol)
        #expect(gameState.status == .won, "Status should still be won")
    }

    // MARK: - Bounds Safety

    @Test("Reveal ignores out-of-bounds coordinates")
    func testRevealOutOfBoundsIsNoOp() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.status == .notStarted)
        #expect(gameState.elapsedTime == 0)
        #expect(gameState.board.cells[0][0].state == .hidden)

        gameState.reveal(row: -1, col: 0)
        gameState.reveal(row: 0, col: -1)
        gameState.reveal(row: 8, col: 0)
        gameState.reveal(row: 0, col: 8)

        #expect(gameState.status == .notStarted)
        #expect(gameState.elapsedTime == 0)
        #expect(gameState.board.cells[0][0].state == .hidden)
    }

    @Test("Toggle flag ignores out-of-bounds coordinates")
    func testToggleFlagOutOfBoundsIsNoOp() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.flagCount == 0)
        #expect(gameState.board.cells[0][0].state == .hidden)

        gameState.toggleFlag(row: -1, col: 0)
        gameState.toggleFlag(row: 0, col: -1)
        gameState.toggleFlag(row: 8, col: 0)
        gameState.toggleFlag(row: 0, col: 8)

        #expect(gameState.flagCount == 0)
        #expect(gameState.board.cells[0][0].state == .hidden)
    }
}
