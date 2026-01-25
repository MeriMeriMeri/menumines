import Foundation
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

    @Test("Reset after winning allows playing again")
    func testResetAfterWinningAllowsPlayingAgain() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)
        #expect(gameState.status == .won)

        gameState.reset()

        #expect(gameState.status == .notStarted)
        #expect(gameState.elapsedTime == 0)
        #expect(gameState.flagCount == 0)
        expectAllCellsHidden(in: gameState)

        gameState.reveal(row: 0, col: 0)
        #expect(gameState.status == .playing)
    }

    @Test("Reset creates fresh board from daily seed")
    func testResetCreatesFreshBoardFromDailySeed() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        gameState.reveal(row: 0, col: 0)
        gameState.reveal(row: 1, col: 1)

        gameState.reset()

        expectAllCellsHidden(in: gameState)
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

        guard let safe = findSafeCell(in: gameState.board) else {
            Issue.record("No safe cell found")
            return
        }
        gameState.reveal(row: safe.row, col: safe.col)
        #expect(gameState.status == .playing)

        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine found")
            return
        }
        gameState.reveal(row: mine.row, col: mine.col)

        #expect(gameState.status == .lost)
        #expect(gameState.board.cells[mine.row][mine.col].isExploded)
    }

    @Test("Win when all non-mine cells are revealed")
    func testWinWhenAllNonMinesRevealed() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)

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

        guard let safe = findSafeCell(in: gameState.board) else {
            return
        }
        gameState.reveal(row: safe.row, col: safe.col)

        guard let mine = findMineCell(in: gameState.board) else {
            return
        }
        gameState.reveal(row: mine.row, col: mine.col)
        #expect(gameState.status == .lost)

        guard let hidden = findHiddenCell(in: gameState) else {
            return
        }

        gameState.reveal(row: hidden.row, col: hidden.col)
        #expect(gameState.board.cells[hidden.row][hidden.col].state == .hidden, "Should not be able to reveal after losing")
    }

    @Test("Cannot reveal after game is won")
    func testCannotRevealAfterGameWon() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)
        #expect(gameState.status == .won)

        guard let mine = findMineCell(in: gameState.board) else {
            return
        }

        gameState.reveal(row: mine.row, col: mine.col)
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

    // MARK: - Story 8: Timer Logic

    /// Helper to run the main RunLoop for a duration, allowing Timer to fire
    private func runLoopFor(seconds: TimeInterval) {
        let deadline = Date(timeIntervalSinceNow: seconds)
        while Date() < deadline {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        }
    }

    /// Helper to find the first safe (non-mine) cell in a board
    private func findSafeCell(in board: Board) -> (row: Int, col: Int)? {
        for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                if !board.cells[r][c].hasMine {
                    return (r, c)
                }
            }
        }
        return nil
    }

    /// Helper to find the first mine cell in a board
    private func findMineCell(in board: Board) -> (row: Int, col: Int)? {
        for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                if board.cells[r][c].hasMine {
                    return (r, c)
                }
            }
        }
        return nil
    }

    /// Helper to win the game by revealing all non-mine cells
    private func winGame(_ gameState: GameState) {
        for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                if !gameState.board.cells[r][c].hasMine {
                    gameState.reveal(row: r, col: c)
                }
            }
        }
    }

    /// Helper to verify all cells are hidden
    private func expectAllCellsHidden(in gameState: GameState) {
        for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                #expect(gameState.board.cells[r][c].state == .hidden)
            }
        }
    }

    /// Helper to find the first hidden cell in a game state
    private func findHiddenCell(in gameState: GameState) -> (row: Int, col: Int)? {
        for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                if case .hidden = gameState.board.cells[r][c].state {
                    return (r, c)
                }
            }
        }
        return nil
    }

    @Test("Timer starts on first reveal")
    @MainActor
    func testTimerStartsOnFirstReveal() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.status == .notStarted)
        #expect(gameState.elapsedTime == 0)

        gameState.reveal(row: 0, col: 0)

        #expect(gameState.status == .playing)

        // Run RunLoop to let timer fire
        runLoopFor(seconds: 1.2)

        #expect(gameState.elapsedTime >= 1)
    }

    @Test("Timer does not start before first click")
    @MainActor
    func testTimerDoesNotStartBeforeFirstClick() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.status == .notStarted)
        #expect(gameState.elapsedTime == 0)

        // Wait without clicking
        runLoopFor(seconds: 1.2)

        #expect(gameState.elapsedTime == 0, "Timer should not run before first click")
        #expect(gameState.status == .notStarted)
    }

    @Test("Timer stops on win")
    @MainActor
    func testTimerStopsOnWin() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)

        #expect(gameState.status == .won)
        let timeAtWin = gameState.elapsedTime

        runLoopFor(seconds: 1.2)

        #expect(gameState.elapsedTime == timeAtWin, "Timer should stop after winning")
    }

    @Test("Timer stops on lose")
    @MainActor
    func testTimerStopsOnLose() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Make a safe first click to start the game
        guard let safe = findSafeCell(in: gameState.board) else {
            Issue.record("No safe cell found")
            return
        }
        gameState.reveal(row: safe.row, col: safe.col)
        #expect(gameState.status == .playing)

        // Find a mine and click it to lose
        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine cell found")
            return
        }
        gameState.reveal(row: mine.row, col: mine.col)

        #expect(gameState.status == .lost)
        let timeAtLoss = gameState.elapsedTime

        // Wait and verify timer has stopped
        runLoopFor(seconds: 1.2)

        #expect(gameState.elapsedTime == timeAtLoss, "Timer should stop after losing")
    }

    @Test("Elapsed time is initially zero")
    func testElapsedTimeInitiallyZero() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.elapsedTime == 0)
    }

    @Test("Pause timer stops time increment")
    @MainActor
    func testPauseTimerStopsTimeIncrement() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Start game
        gameState.reveal(row: 0, col: 0)
        #expect(gameState.status == .playing)

        // Wait for timer to tick
        runLoopFor(seconds: 1.2)
        let timeBeforePause = gameState.elapsedTime
        #expect(timeBeforePause >= 1)

        // Pause timer
        gameState.pauseTimer()

        // Wait and verify time doesn't increase
        runLoopFor(seconds: 1.2)

        #expect(gameState.elapsedTime == timeBeforePause, "Timer should not increment while paused")
    }

    @Test("Resume timer continues from paused time")
    @MainActor
    func testResumeTimerContinuesFromPausedTime() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Start game
        gameState.reveal(row: 0, col: 0)
        #expect(gameState.status == .playing)

        // Wait for timer to tick
        runLoopFor(seconds: 1.2)
        let timeBeforePause = gameState.elapsedTime
        #expect(timeBeforePause >= 1)

        // Pause and resume
        gameState.pauseTimer()
        let pausedTime = gameState.elapsedTime
        gameState.resumeTimer()

        // Wait for timer to tick after resume
        runLoopFor(seconds: 1.2)

        #expect(gameState.elapsedTime > pausedTime, "Timer should continue incrementing after resume")
    }

    @Test("Resume timer does nothing if game not playing")
    @MainActor
    func testResumeTimerDoesNothingIfNotPlaying() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.status == .notStarted)
        #expect(gameState.elapsedTime == 0)

        // Try to resume when not playing
        gameState.resumeTimer()

        // Wait and verify timer didn't start
        runLoopFor(seconds: 1.2)

        #expect(gameState.elapsedTime == 0, "Resume should not start timer when game not in .playing status")
    }

    @Test("Resume timer does nothing after win")
    @MainActor
    func testResumeTimerDoesNothingAfterWin() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)

        #expect(gameState.status == .won)
        let timeAtWin = gameState.elapsedTime

        gameState.resumeTimer()

        runLoopFor(seconds: 1.2)

        #expect(gameState.elapsedTime == timeAtWin, "Resume should not restart timer after winning")
    }

    @Test("Resume timer does nothing after loss")
    @MainActor
    func testResumeTimerDoesNothingAfterLoss() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Make a safe first click to start the game
        guard let safe = findSafeCell(in: gameState.board) else {
            Issue.record("No safe cell found")
            return
        }
        gameState.reveal(row: safe.row, col: safe.col)
        #expect(gameState.status == .playing)

        // Find a mine and click it to lose
        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine cell found")
            return
        }
        gameState.reveal(row: mine.row, col: mine.col)

        #expect(gameState.status == .lost)
        let timeAtLoss = gameState.elapsedTime

        // Try to resume after losing
        gameState.resumeTimer()

        // Wait and verify timer didn't restart
        runLoopFor(seconds: 1.2)

        #expect(gameState.elapsedTime == timeAtLoss, "Resume should not restart timer after losing")
    }

    @Test("Flag does not start timer")
    @MainActor
    func testFlagDoesNotStartTimer() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.status == .notStarted)
        #expect(gameState.elapsedTime == 0)

        // Toggle flag on a cell (should not start timer)
        gameState.toggleFlag(row: 0, col: 0)

        #expect(gameState.status == .notStarted, "Flagging should not start the game")

        // Wait and verify timer didn't start
        runLoopFor(seconds: 1.2)

        #expect(gameState.elapsedTime == 0, "Timer should not run after flagging without revealing")
    }
}
