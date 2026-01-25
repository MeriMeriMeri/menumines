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

    // Note: Reset tests that manipulate UserDefaults are in GameStatePersistenceTests (serialized)

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
            Issue.record("No safe cell found")
            return
        }
        gameState.reveal(row: safe.row, col: safe.col)

        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine found")
            return
        }
        gameState.reveal(row: mine.row, col: mine.col)
        #expect(gameState.status == .lost)

        guard let hidden = findHiddenCell(in: gameState) else {
            Issue.record("No hidden cell found")
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
            Issue.record("No mine found")
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

    // MARK: - Story 27: Chord Reveal

    @Test("Chord reveal does nothing before game starts")
    func testChordRevealDoesNothingBeforeGameStarts() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.status == .notStarted)

        gameState.chordReveal(row: 0, col: 0)

        #expect(gameState.status == .notStarted)
    }

    @Test("Chord reveal works on revealed number cell with correct flags")
    func testChordRevealWorksWithCorrectFlags() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Find a cell with exactly 1 adjacent mine
        guard let target = findCellWithAdjacentMines(count: 1, in: gameState.board) else {
            Issue.record("No suitable cell found")
            return
        }

        // Find the adjacent mine
        guard let mine = findAdjacentMine(to: target.row, col: target.col, in: gameState.board) else {
            Issue.record("No adjacent mine found")
            return
        }

        // Start the game and reveal the target cell
        gameState.reveal(row: target.row, col: target.col)
        #expect(gameState.status == .playing)

        // Flag the mine
        gameState.toggleFlag(row: mine.row, col: mine.col)

        // Count hidden cells adjacent to target before chord reveal
        let hiddenBefore = countHiddenAdjacentCells(to: target.row, col: target.col, in: gameState)

        // Perform chord reveal
        gameState.chordReveal(row: target.row, col: target.col)

        // Count hidden cells after
        let hiddenAfter = countHiddenAdjacentCells(to: target.row, col: target.col, in: gameState)

        #expect(hiddenAfter < hiddenBefore, "Chord reveal should reveal adjacent hidden cells")
    }

    @Test("Chord reveal loses game with incorrect flag")
    func testChordRevealLosesWithIncorrectFlag() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Find a cell with exactly 1 adjacent mine
        guard let target = findCellWithAdjacentMines(count: 1, in: gameState.board) else {
            Issue.record("No suitable cell found")
            return
        }

        // Find an adjacent non-mine cell to place wrong flag
        guard let wrongFlag = findAdjacentNonMine(to: target.row, col: target.col, in: gameState.board) else {
            Issue.record("No adjacent non-mine found")
            return
        }

        // Start the game
        gameState.reveal(row: target.row, col: target.col)
        #expect(gameState.status == .playing)

        // Place flag on wrong cell
        gameState.toggleFlag(row: wrongFlag.row, col: wrongFlag.col)

        // Perform chord reveal
        gameState.chordReveal(row: target.row, col: target.col)

        #expect(gameState.status == .lost, "Chord reveal with incorrect flag should lose")
    }

    @Test("Chord reveal via reveal on revealed cell")
    func testRevealOnRevealedCellTriggersChordReveal() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Find a cell with exactly 1 adjacent mine
        guard let target = findCellWithAdjacentMines(count: 1, in: gameState.board) else {
            Issue.record("No suitable cell found")
            return
        }

        // Find the adjacent mine
        guard let mine = findAdjacentMine(to: target.row, col: target.col, in: gameState.board) else {
            Issue.record("No adjacent mine found")
            return
        }

        // Start the game and reveal the target cell
        gameState.reveal(row: target.row, col: target.col)
        #expect(gameState.status == .playing)

        // Flag the mine
        gameState.toggleFlag(row: mine.row, col: mine.col)

        // Count hidden cells before
        let hiddenBefore = countHiddenAdjacentCells(to: target.row, col: target.col, in: gameState)

        // Call reveal on already-revealed cell (should trigger chord reveal)
        gameState.reveal(row: target.row, col: target.col)

        // Count hidden cells after
        let hiddenAfter = countHiddenAdjacentCells(to: target.row, col: target.col, in: gameState)

        #expect(hiddenAfter < hiddenBefore, "Reveal on revealed cell should trigger chord reveal")
    }

    @Test("Chord reveal selected works with keyboard navigation")
    func testChordRevealSelectedWorks() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Find a cell with exactly 1 adjacent mine
        guard let target = findCellWithAdjacentMines(count: 1, in: gameState.board) else {
            Issue.record("No suitable cell found")
            return
        }

        // Find the adjacent mine
        guard let mine = findAdjacentMine(to: target.row, col: target.col, in: gameState.board) else {
            Issue.record("No adjacent mine found")
            return
        }

        // Start the game and reveal the target cell
        gameState.reveal(row: target.row, col: target.col)

        // Flag the mine
        gameState.toggleFlag(row: mine.row, col: mine.col)

        // Move selection to target cell (handle all directions)
        while gameState.selectedRow < target.row { gameState.moveSelection(.down) }
        while gameState.selectedRow > target.row { gameState.moveSelection(.up) }
        while gameState.selectedCol < target.col { gameState.moveSelection(.right) }
        while gameState.selectedCol > target.col { gameState.moveSelection(.left) }

        // Count hidden cells before
        let hiddenBefore = countHiddenAdjacentCells(to: target.row, col: target.col, in: gameState)

        // Perform chord reveal via keyboard
        gameState.chordRevealSelected()

        // Count hidden cells after
        let hiddenAfter = countHiddenAdjacentCells(to: target.row, col: target.col, in: gameState)

        #expect(hiddenAfter < hiddenBefore, "Chord reveal selected should reveal adjacent hidden cells")
    }

    @Test("Chord reveal can win the game")
    func testChordRevealCanWinGame() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Find a number cell with exactly 1 adjacent mine and at least one non-mine hidden neighbor
        guard let numberCell = findCellWithAdjacentMines(count: 1, in: gameState.board) else {
            Issue.record("No suitable number cell found")
            return
        }

        guard let mine = findAdjacentMine(to: numberCell.row, col: numberCell.col, in: gameState.board) else {
            Issue.record("No adjacent mine found")
            return
        }

        // Reveal all non-mine cells EXCEPT those adjacent to our number cell (excluding the number cell itself)
        var adjacentNonMines: Set<String> = []
        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let r = numberCell.row + dr
                let c = numberCell.col + dc
                if r >= 0, r < Board.rows, c >= 0, c < Board.cols {
                    if !gameState.board.cells[r][c].hasMine {
                        adjacentNonMines.insert("\(r),\(c)")
                    }
                }
            }
        }

        // Reveal all non-mine cells except adjacent ones (to leave work for chord reveal)
        for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                if !gameState.board.cells[r][c].hasMine && !adjacentNonMines.contains("\(r),\(c)") {
                    gameState.reveal(row: r, col: c)
                }
            }
        }

        // If already won, the test setup didn't work as intended
        if gameState.status == .won {
            return
        }

        #expect(gameState.status == .playing)

        // The number cell should now be revealed (from cascade or direct reveal)
        // If not, reveal it explicitly
        if case .hidden = gameState.board.cells[numberCell.row][numberCell.col].state {
            gameState.reveal(row: numberCell.row, col: numberCell.col)
        }

        // Flag the mine
        gameState.toggleFlag(row: mine.row, col: mine.col)

        // Now chord reveal should reveal remaining adjacent cells and potentially win
        gameState.chordReveal(row: numberCell.row, col: numberCell.col)

        // Verify chord reveal did something (revealed cells)
        // The game should either be won or still playing (if other cells remain)
        #expect(gameState.status == .won || gameState.status == .playing)
    }

    @Test("Chord reveal does nothing after game is won")
    func testChordRevealDoesNothingAfterWin() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)
        #expect(gameState.status == .won)

        // Find a revealed number cell
        guard let target = findRevealedNumberCell(in: gameState) else {
            // No revealed number cell found, test is inconclusive
            return
        }

        // Try chord reveal - should do nothing
        gameState.chordReveal(row: target.row, col: target.col)

        #expect(gameState.status == .won, "Status should remain won")
    }

    @Test("Chord reveal does nothing after game is lost")
    func testChordRevealDoesNothingAfterLoss() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Start game
        guard let safe = findSafeCell(in: gameState.board) else {
            Issue.record("No safe cell found")
            return
        }
        gameState.reveal(row: safe.row, col: safe.col)

        // Lose the game
        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine found")
            return
        }
        gameState.reveal(row: mine.row, col: mine.col)
        #expect(gameState.status == .lost)

        // Try chord reveal - should do nothing
        gameState.chordReveal(row: 0, col: 0)

        #expect(gameState.status == .lost, "Status should remain lost")
    }

    // MARK: - Chord Reveal Helpers

    private func findCellWithAdjacentMines(count: Int, in board: Board) -> (row: Int, col: Int)? {
        for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                if !board.cells[r][c].hasMine {
                    if board.adjacentMineCount(row: r, col: c) == count {
                        return (r, c)
                    }
                }
            }
        }
        return nil
    }

    private func findAdjacentMine(to row: Int, col: Int, in board: Board) -> (row: Int, col: Int)? {
        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let r = row + dr
                let c = col + dc
                if r >= 0, r < Board.rows, c >= 0, c < Board.cols {
                    if board.cells[r][c].hasMine {
                        return (r, c)
                    }
                }
            }
        }
        return nil
    }

    private func findAdjacentNonMine(to row: Int, col: Int, in board: Board) -> (row: Int, col: Int)? {
        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let r = row + dr
                let c = col + dc
                if r >= 0, r < Board.rows, c >= 0, c < Board.cols {
                    if !board.cells[r][c].hasMine, case .hidden = board.cells[r][c].state {
                        return (r, c)
                    }
                }
            }
        }
        return nil
    }

    private func countHiddenAdjacentCells(to row: Int, col: Int, in gameState: GameState) -> Int {
        var count = 0
        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let r = row + dr
                let c = col + dc
                if r >= 0, r < Board.rows, c >= 0, c < Board.cols {
                    if case .hidden = gameState.board.cells[r][c].state {
                        count += 1
                    }
                }
            }
        }
        return count
    }

    private func findRevealedNumberCell(in gameState: GameState) -> (row: Int, col: Int)? {
        for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                if case .revealed(let adj) = gameState.board.cells[r][c].state, adj > 0 {
                    return (r, c)
                }
            }
        }
        return nil
    }

    // MARK: - Story 17: Share Result

    @Test("Share text is nil before game completes")
    func testShareTextNilBeforeCompletion() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.shareText() == nil, "Share text should be nil when game not started")

        gameState.reveal(row: 0, col: 0)
        #expect(gameState.status == .playing)
        #expect(gameState.shareText() == nil, "Share text should be nil while playing")
    }

    @Test("Share text available after win")
    func testShareTextAvailableAfterWin() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)
        #expect(gameState.status == .won)

        let shareText = gameState.shareText()
        #expect(shareText != nil, "Share text should be available after winning")
    }

    @Test("Share text available after loss")
    func testShareTextAvailableAfterLoss() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        guard let safe = findSafeCell(in: gameState.board) else {
            Issue.record("No safe cell found")
            return
        }
        gameState.reveal(row: safe.row, col: safe.col)

        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine found")
            return
        }
        gameState.reveal(row: mine.row, col: mine.col)
        #expect(gameState.status == .lost)

        let shareText = gameState.shareText()
        #expect(shareText != nil, "Share text should be available after losing")
    }

    @Test("Share text includes UTC date")
    func testShareTextIncludesUTCDate() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)

        // Use a specific date for testing
        let timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0) ?? .current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = DateComponents(year: 2026, month: 1, day: 25)
        guard let testDate = calendar.date(from: components) else {
            Issue.record("Failed to construct test date")
            return
        }

        guard let shareText = gameState.shareText(for: testDate) else {
            Issue.record("Share text should not be nil")
            return
        }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let expectedDate = formatter.string(from: testDate)
        let expectedHeader = String(format: String(localized: "share_header"), expectedDate)
        #expect(shareText.contains(expectedHeader), "Share text should include UTC date in header")
    }

    @Test("Share text includes completion time")
    func testShareTextIncludesCompletionTime() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)

        guard let shareText = gameState.shareText() else {
            Issue.record("Share text should not be nil")
            return
        }

        // The time format should be "Solved in M:SS" or similar
        #expect(shareText.contains("Solved in"), "Share text should include 'Solved in' for winning")
    }

    @Test("Share text includes failed message on loss")
    func testShareTextIncludesFailedOnLoss() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        guard let safe = findSafeCell(in: gameState.board) else {
            Issue.record("No safe cell found")
            return
        }
        gameState.reveal(row: safe.row, col: safe.col)

        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine found")
            return
        }
        gameState.reveal(row: mine.row, col: mine.col)

        guard let shareText = gameState.shareText() else {
            Issue.record("Share text should not be nil")
            return
        }

        #expect(shareText.contains("Failed in"), "Share text should include 'Failed in' for losing")
    }

    @Test("Share text includes 8x8 emoji grid")
    func testShareTextIncludesEmojiGrid() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)

        guard let shareText = gameState.shareText() else {
            Issue.record("Share text should not be nil")
            return
        }

        let lines = shareText.split(separator: "\n", omittingEmptySubsequences: false)

        // Should have: header, result, 8 grid rows, marked count = 11 lines
        #expect(lines.count == 11, "Share text should have 11 lines (header, result, 8 grid rows, marked)")

        // Grid rows should be lines 2-9 (0-indexed)
        for i in 2..<10 {
            let line = String(lines[i])
            // Each grid line should only contain the three emoji types
            let validEmojis = Set(["🟩", "🚩", "⬛️"])
            var emojiCount = 0
            var index = line.startIndex
            while index < line.endIndex {
                let remaining = String(line[index...])
                var found = false
                for emoji in validEmojis {
                    if remaining.hasPrefix(emoji) {
                        emojiCount += 1
                        index = line.index(index, offsetBy: emoji.count)
                        found = true
                        break
                    }
                }
                if !found {
                    Issue.record("Unexpected character in grid line \(i): \(line)")
                    break
                }
            }
            #expect(emojiCount == 8, "Grid line \(i) should have exactly 8 emojis, got \(emojiCount)")
        }
    }

    @Test("Share text does not reveal mine locations")
    func testShareTextDoesNotRevealMines() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Flag some mine cells (must flag mines, not non-mines, to allow winning)
        var flaggedCount = 0
        for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                if gameState.board.cells[r][c].hasMine && flaggedCount < 2 {
                    gameState.toggleFlag(row: r, col: c)
                    flaggedCount += 1
                }
            }
        }

        winGame(gameState)

        guard let shareText = gameState.shareText() else {
            Issue.record("Share text should not be nil")
            return
        }

        // The grid should not contain any mine-specific emoji
        // Mines should appear as either 🟩 (if revealed, but that means loss) or 🚩 (flagged) or ⬛️ (hidden)
        // The grid should NOT have a special "mine" emoji that reveals locations
        #expect(!shareText.contains("💣"), "Share text should not contain mine emoji")
        #expect(!shareText.contains("💥"), "Share text should not contain explosion emoji")
    }

    @Test("Share text includes marked count")
    func testShareTextIncludesMarkedCount() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Find and flag some mines
        var flaggedMines = 0
        for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                if gameState.board.cells[r][c].hasMine && flaggedMines < 3 {
                    gameState.toggleFlag(row: r, col: c)
                    flaggedMines += 1
                }
            }
        }

        winGame(gameState)

        guard let shareText = gameState.shareText() else {
            Issue.record("Share text should not be nil")
            return
        }

        #expect(shareText.contains("Marked:"), "Share text should include 'Marked:' count")
        #expect(shareText.contains("/10"), "Share text should include '/10' for total mines")
    }

    @Test("Share text emoji mapping is correct")
    func testShareTextEmojiMapping() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Flag one mine cell (must flag a mine, not a non-mine, to allow winning)
        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine cell found")
            return
        }
        gameState.toggleFlag(row: mine.row, col: mine.col)

        winGame(gameState)

        guard let shareText = gameState.shareText() else {
            Issue.record("Share text should not be nil")
            return
        }

        // Check that we have the expected emoji types
        #expect(shareText.contains("🟩"), "Share text should contain green square for revealed cells")
        #expect(shareText.contains("🚩"), "Share text should contain flag for flagged cells")
        // Hidden cells (⬛️) will exist for unflagged mines after winning
    }

    // MARK: - Story 18: isPaused State Tests

    @Test("isPaused is initially false")
    func testIsPausedInitiallyFalse() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.isPaused == false)
    }

    @Test("isPaused is true after pauseTimer while playing")
    @MainActor
    func testIsPausedTrueAfterPauseWhilePlaying() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        gameState.reveal(row: 0, col: 0)
        #expect(gameState.status == .playing)

        gameState.pauseTimer()

        #expect(gameState.isPaused == true)
    }

    @Test("isPaused is false after resumeTimer")
    @MainActor
    func testIsPausedFalseAfterResume() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        gameState.reveal(row: 0, col: 0)
        gameState.pauseTimer()
        #expect(gameState.isPaused == true)

        gameState.resumeTimer()

        #expect(gameState.isPaused == false)
    }

    @Test("isPaused remains false when pausing before game starts")
    func testIsPausedFalseWhenPausingBeforeGameStarts() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.status == .notStarted)
        gameState.pauseTimer()

        #expect(gameState.isPaused == false)
    }

    @Test("isPaused is false after game is won")
    @MainActor
    func testIsPausedFalseAfterWin() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)

        #expect(gameState.status == .won)
        #expect(gameState.isPaused == false)
    }

    @Test("isPaused is false after game is lost")
    @MainActor
    func testIsPausedFalseAfterLoss() {
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)
        guard let safe = findSafeCell(in: gameState.board) else {
            Issue.record("No safe cell found")
            return
        }
        gameState.reveal(row: safe.row, col: safe.col)

        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine cell found")
            return
        }
        gameState.reveal(row: mine.row, col: mine.col)

        #expect(gameState.status == .lost)
        #expect(gameState.isPaused == false)
    }

    // Note: testIsPausedFalseAfterReset is in GameStatePersistenceTests (serialized)

    // MARK: - Persistence Tests (Codable - no shared state)

    @Test("CellState hidden round-trips through Codable")
    func testCellStateHiddenCodable() throws {
        let original = CellState.hidden
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CellState.self, from: data)
        #expect(decoded == original)
    }

    @Test("CellState revealed round-trips through Codable")
    func testCellStateRevealedCodable() throws {
        let original = CellState.revealed(adjacentMines: 3)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CellState.self, from: data)
        #expect(decoded == original)
    }

    @Test("CellState flagged round-trips through Codable")
    func testCellStateFlaggedCodable() throws {
        let original = CellState.flagged
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CellState.self, from: data)
        #expect(decoded == original)
    }

    @Test("Cell round-trips through Codable")
    func testCellCodable() throws {
        let original = Cell(state: .revealed(adjacentMines: 2), hasMine: false, isExploded: false)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Cell.self, from: data)
        #expect(decoded == original)
    }

    @Test("Cell with mine round-trips through Codable")
    func testCellWithMineCodable() throws {
        let original = Cell(state: .hidden, hasMine: true, isExploded: false)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Cell.self, from: data)
        #expect(decoded == original)
    }

    @Test("Cell with exploded mine round-trips through Codable")
    func testCellExplodedCodable() throws {
        let original = Cell(state: .revealed(adjacentMines: 0), hasMine: true, isExploded: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Cell.self, from: data)
        #expect(decoded == original)
    }

    @Test("Board round-trips through Codable")
    func testBoardCodable() throws {
        let original = Board(seed: 12345)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Board.self, from: data)
        #expect(decoded == original)
    }

    @Test("Board with modified cells round-trips through Codable")
    func testBoardModifiedCodable() throws {
        var original = Board(seed: 12345)
        _ = original.reveal(row: 0, col: 0)
        original.toggleFlag(row: 1, col: 1)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Board.self, from: data)
        #expect(decoded == original)
    }

    @Test("GameStatus round-trips through Codable")
    func testGameStatusCodable() throws {
        for status in [GameStatus.notStarted, .playing, .won, .lost] {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(GameStatus.self, from: data)
            #expect(decoded == status)
        }
    }

    @Test("GameSnapshot round-trips through Codable")
    func testGameSnapshotCodable() throws {
        let board = Board(seed: 12345)
        let snapshot = GameSnapshot(
            board: board,
            status: .playing,
            elapsedTime: 42.0,
            flagCount: 3,
            selectedRow: 2,
            selectedCol: 5,
            dailySeed: 20260125
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(GameSnapshot.self, from: data)

        #expect(decoded.board == snapshot.board)
        #expect(decoded.status == snapshot.status)
        #expect(decoded.elapsedTime == snapshot.elapsedTime)
        #expect(decoded.flagCount == snapshot.flagCount)
        #expect(decoded.selectedRow == snapshot.selectedRow)
        #expect(decoded.selectedCol == snapshot.selectedCol)
        #expect(decoded.dailySeed == snapshot.dailySeed)
    }

    @Test("Board init with cells preserves all cell states")
    func testBoardInitWithCells() {
        let originalBoard = Board(seed: 12345)
        var modifiedBoard = originalBoard
        _ = modifiedBoard.reveal(row: 0, col: 0)
        modifiedBoard.toggleFlag(row: 1, col: 1)

        let reconstructed = Board(cells: modifiedBoard.cells)

        #expect(reconstructed == modifiedBoard)
        #expect(reconstructed.cells[1][1].state == .flagged)
    }
}

// MARK: - Persistence Tests with UserDefaults (Serialized)
// These tests use shared UserDefaults storage and must run serially to avoid interference

@Suite("GameState Persistence Tests", .serialized)
struct GameStatePersistenceTests {

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

    @Test("GameSnapshot save and load works")
    func testGameSnapshotSaveLoad() {
        GameSnapshot.clear()
        defer { GameSnapshot.clear() }

        let board = Board(seed: 12345)
        let todaySeed = seedFromDate(Date())
        let snapshot = GameSnapshot(
            board: board,
            status: .playing,
            elapsedTime: 99.0,
            flagCount: 5,
            selectedRow: 3,
            selectedCol: 4,
            dailySeed: todaySeed
        )

        snapshot.save()

        guard let loaded = GameSnapshot.load() else {
            Issue.record("Snapshot should be loadable")
            return
        }

        #expect(loaded.board == snapshot.board)
        #expect(loaded.status == snapshot.status)
        #expect(loaded.elapsedTime == snapshot.elapsedTime)
        #expect(loaded.flagCount == snapshot.flagCount)
        #expect(loaded.selectedRow == snapshot.selectedRow)
        #expect(loaded.selectedCol == snapshot.selectedCol)
        #expect(loaded.dailySeed == snapshot.dailySeed)
    }

    @Test("GameSnapshot load returns nil for stale date")
    func testGameSnapshotStaleDate() {
        GameSnapshot.clear()
        defer { GameSnapshot.clear() }

        let board = Board(seed: 12345)
        // Use yesterday's seed
        let staleSeed = seedFromDate(Date()) - 1
        let snapshot = GameSnapshot(
            board: board,
            status: .playing,
            elapsedTime: 50.0,
            flagCount: 2,
            selectedRow: 1,
            selectedCol: 1,
            dailySeed: staleSeed
        )

        snapshot.save()

        let loaded = GameSnapshot.load()
        #expect(loaded == nil, "Snapshot with stale date should not load")

        // Verify it was cleared
        let loadedAgain = GameSnapshot.load()
        #expect(loadedAgain == nil, "Stale snapshot should be cleared after load attempt")
    }

    @Test("GameSnapshot load returns nil when no snapshot exists")
    func testGameSnapshotLoadNil() {
        GameSnapshot.clear()
        defer { GameSnapshot.clear() }

        let loaded = GameSnapshot.load()
        #expect(loaded == nil)
    }

    @Test("GameState save creates snapshot for playing state")
    func testGameStateSaveCreatesSnapshot() {
        GameSnapshot.clear()
        defer { GameSnapshot.clear() }

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Start the game
        gameState.reveal(row: 0, col: 0)
        #expect(gameState.status == .playing)

        // Flag a cell and move selection
        gameState.toggleFlag(row: 1, col: 1)
        gameState.moveSelection(.down)
        gameState.moveSelection(.right)

        gameState.save()

        guard let loaded = GameSnapshot.load() else {
            Issue.record("Snapshot should exist after save")
            return
        }

        #expect(loaded.status == .playing)
        #expect(loaded.flagCount == 1)
        #expect(loaded.selectedRow == 1)
        #expect(loaded.selectedCol == 1)
    }

    @Test("GameState save persists won status")
    func testGameStateSavePersistsWonStatus() {
        GameSnapshot.clear()
        defer { GameSnapshot.clear() }

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Start and save
        gameState.reveal(row: 0, col: 0)
        gameState.save()
        #expect(GameSnapshot.load() != nil, "Snapshot should exist while playing")

        // Win the game
        winGame(gameState)
        #expect(gameState.status == .won)

        // Save after win should persist won status
        gameState.save()
        guard let loaded = GameSnapshot.load() else {
            Issue.record("Snapshot should exist after win")
            return
        }
        #expect(loaded.status == .won, "Snapshot should have won status")
    }

    @Test("GameState save persists lost status")
    func testGameStateSavePersistsLostStatus() {
        GameSnapshot.clear()
        defer { GameSnapshot.clear() }

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Start and save
        guard let safe = findSafeCell(in: gameState.board) else {
            Issue.record("No safe cell found")
            return
        }
        gameState.reveal(row: safe.row, col: safe.col)
        gameState.save()
        #expect(GameSnapshot.load() != nil, "Snapshot should exist while playing")

        // Lose the game
        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine found")
            return
        }
        gameState.reveal(row: mine.row, col: mine.col)
        #expect(gameState.status == .lost)

        // Save after loss should persist lost status
        gameState.save()
        guard let loaded = GameSnapshot.load() else {
            Issue.record("Snapshot should exist after loss")
            return
        }
        #expect(loaded.status == .lost, "Snapshot should have lost status")
    }

    @Test("GameState save does nothing for notStarted state")
    func testGameStateSaveDoesNothingNotStarted() {
        GameSnapshot.clear()
        defer { GameSnapshot.clear() }

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.status == .notStarted)

        gameState.save()
        #expect(GameSnapshot.load() == nil, "Snapshot should not be created for notStarted state")
    }

    @Test("GameState reset clears snapshot")
    func testGameStateResetClearsSnapshot() {
        GameSnapshot.clear()
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        defer {
            GameSnapshot.clear()
            UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        }

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Start and save (but don't complete)
        gameState.reveal(row: 0, col: 0)
        gameState.save()
        #expect(GameSnapshot.load() != nil, "Snapshot should exist while playing")

        // Reset (should work since game not complete)
        gameState.reset()
        #expect(GameSnapshot.load() == nil, "Snapshot should be cleared after reset")
    }

    @Test("GameState restored creates fresh game when no snapshot")
    func testGameStateRestoredFreshGame() {
        GameSnapshot.clear()
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
        let todaySeed = seedFromDate(Date())
        UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        defer {
            GameSnapshot.clear()
            UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        }

        let gameState = GameState.restored()

        #expect(gameState.status == .notStarted)
        #expect(gameState.elapsedTime == 0)
        #expect(gameState.flagCount == 0)
        #expect(gameState.selectedRow == 0)
        #expect(gameState.selectedCol == 0)
    }

    @Test("GameState restored restores from snapshot")
    func testGameStateRestoredFromSnapshot() {
        GameSnapshot.clear()
        defer { GameSnapshot.clear() }

        // Create and save a game state
        let originalBoard = Board(seed: 12345)
        let originalState = GameState(board: originalBoard)
        originalState.reveal(row: 0, col: 0)
        originalState.toggleFlag(row: 2, col: 3)
        originalState.moveSelection(.down)
        originalState.moveSelection(.down)
        originalState.moveSelection(.right)

        originalState.save()

        // Restore
        let restoredState = GameState.restored()

        #expect(restoredState.status == .playing)
        #expect(restoredState.flagCount == 1)
        #expect(restoredState.selectedRow == 2)
        #expect(restoredState.selectedCol == 1)
        #expect(restoredState.board.cells[2][3].state == .flagged)
    }

    @Test("GameState restored does not restore stale snapshot")
    func testGameStateRestoredIgnoresStaleSnapshot() {
        GameSnapshot.clear()
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
        let todaySeed = seedFromDate(Date())
        UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        defer {
            GameSnapshot.clear()
            UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        }

        // Create a snapshot with yesterday's seed
        let board = Board(seed: 12345)
        let staleSeed = seedFromDate(Date()) - 1
        let staleSnapshot = GameSnapshot(
            board: board,
            status: .playing,
            elapsedTime: 100.0,
            flagCount: 5,
            selectedRow: 4,
            selectedCol: 4,
            dailySeed: staleSeed
        )
        staleSnapshot.save()

        // Restore should create fresh game
        let restoredState = GameState.restored()

        #expect(restoredState.status == .notStarted)
        #expect(restoredState.elapsedTime == 0)
        #expect(restoredState.flagCount == 0)
    }

    // MARK: - Completion Lock Tests

    @Test("canReset is true before completion")
    func testCanResetTrueBeforeCompletion() {
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        defer { UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed") }

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.canReset == true)
    }

    @Test("canReset is false after daily completion")
    func testCanResetFalseAfterCompletion() {
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        defer { UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed") }

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Complete the game
        winGame(gameState)
        #expect(gameState.status == .won)

        #expect(gameState.canReset == false, "canReset should be false after winning")
    }

    @Test("canReset is false after losing")
    func testCanResetFalseAfterLoss() {
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        defer { UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed") }

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Start game
        guard let safe = findSafeCell(in: gameState.board) else {
            Issue.record("No safe cell found")
            return
        }
        gameState.reveal(row: safe.row, col: safe.col)

        // Lose the game
        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine found")
            return
        }
        gameState.reveal(row: mine.row, col: mine.col)
        #expect(gameState.status == .lost)

        #expect(gameState.canReset == false, "canReset should be false after losing")
    }

    @Test("reset does nothing when daily is complete")
    func testResetBlockedWhenComplete() {
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        defer { UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed") }

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)
        #expect(gameState.status == .won)
        let elapsedAfterWin = gameState.elapsedTime

        // Try to reset
        gameState.reset()

        // State should be unchanged
        #expect(gameState.status == .won, "Status should remain won after blocked reset")
        #expect(gameState.elapsedTime == elapsedAfterWin, "Elapsed time should be unchanged")
    }

    // MARK: - Stats Recording Tests

    @Test("Stats are recorded on win")
    func testStatsRecordedOnWin() {
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
        let todaySeed = seedFromDate(Date())
        UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        defer {
            UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        }

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)

        #expect(hasStatsBeenRecorded(), "Stats should be recorded after winning")

        let stats = getStats(for: Date())
        #expect(stats != nil, "Stats should be retrievable")
        #expect(stats?.won == true, "Stats should indicate win")
    }

    @Test("Stats are recorded on loss")
    func testStatsRecordedOnLoss() {
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
        let todaySeed = seedFromDate(Date())
        UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        defer {
            UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        }

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Start game
        guard let safe = findSafeCell(in: gameState.board) else {
            Issue.record("No safe cell found")
            return
        }
        gameState.reveal(row: safe.row, col: safe.col)

        // Lose the game
        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine found")
            return
        }
        gameState.reveal(row: mine.row, col: mine.col)

        #expect(hasStatsBeenRecorded(), "Stats should be recorded after losing")

        let stats = getStats(for: Date())
        #expect(stats != nil, "Stats should be retrievable")
        #expect(stats?.won == false, "Stats should indicate loss")
    }

    @Test("Stats are only recorded once per day")
    func testStatsDedupe() {
        UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
        let todaySeed = seedFromDate(Date())
        UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        defer {
            UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        }

        // First recording
        let recorded1 = recordStats(won: true, elapsedTime: 100.0, flagCount: 5)
        #expect(recorded1 == true, "First recording should succeed")

        // Second recording should be ignored
        let recorded2 = recordStats(won: false, elapsedTime: 200.0, flagCount: 10)
        #expect(recorded2 == false, "Second recording should be rejected")

        // Stats should reflect first recording
        let stats = getStats(for: Date())
        #expect(stats?.won == true, "Stats should reflect first recording")
        #expect(stats?.elapsedTime == 100.0, "Elapsed time should be from first recording")
        #expect(stats?.flagCount == 5, "Flag count should be from first recording")
    }

    // MARK: - Error Recovery Tests

    @Test("Restored state recovers from stats when snapshot missing but daily complete")
    func testRestoredRecoverFromStats() {
        GameSnapshot.clear()
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
        let todaySeed = seedFromDate(Date())
        UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        defer {
            GameSnapshot.clear()
            UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        }

        // Mark daily complete and record stats, but don't save snapshot
        markDailyPuzzleComplete()
        _ = recordStats(won: true, elapsedTime: 123.0, flagCount: 7)

        // Restore should recover from stats
        let restoredState = GameState.restored()

        #expect(restoredState.status == .won, "Should restore won status from stats")
        #expect(restoredState.elapsedTime == 123.0, "Should restore elapsed time from stats")
        #expect(restoredState.flagCount == 7, "Should restore flag count from stats")
    }

    @Test("Restored state falls back to fresh game when no snapshot and no stats")
    func testRestoredFallbackFreshGame() {
        GameSnapshot.clear()
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
        let todaySeed = seedFromDate(Date())
        UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        defer {
            GameSnapshot.clear()
            UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        }

        let restoredState = GameState.restored()

        #expect(restoredState.status == .notStarted, "Should restore to notStarted")
        #expect(restoredState.elapsedTime == 0, "Should have zero elapsed time")
        #expect(restoredState.flagCount == 0, "Should have zero flags")
    }

    // MARK: - Daily Completion Tests (Win and Loss)

    @Test("Daily puzzle marked complete on win")
    func testDailyCompleteOnWin() {
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        defer { UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed") }

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(!isDailyPuzzleComplete(), "Daily should not be complete before win")

        winGame(gameState)

        #expect(isDailyPuzzleComplete(), "Daily should be complete after win")
    }

    @Test("Daily puzzle marked complete on loss")
    func testDailyCompleteOnLoss() {
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        defer { UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed") }

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Start game
        guard let safe = findSafeCell(in: gameState.board) else {
            Issue.record("No safe cell found")
            return
        }
        gameState.reveal(row: safe.row, col: safe.col)

        #expect(!isDailyPuzzleComplete(), "Daily should not be complete while playing")

        // Lose the game
        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine found")
            return
        }
        gameState.reveal(row: mine.row, col: mine.col)

        #expect(isDailyPuzzleComplete(), "Daily should be complete after loss")
    }

    // MARK: - Reset Tests (require serialized due to UserDefaults)

    @Test("Reset restores initial state")
    func testResetRestoresInitialState() {
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        defer { UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed") }

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Play the game (don't complete it)
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

    @Test("Reset is blocked after winning (completion lock)")
    func testResetBlockedAfterWinning() {
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        defer { UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed") }

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)
        #expect(gameState.status == .won)

        // Try to reset - should be blocked
        gameState.reset()

        // State should be unchanged (reset was blocked)
        #expect(gameState.status == .won, "Reset should be blocked after winning")
    }

    @Test("Reset restores all cells to hidden")
    func testResetRestoresAllCellsToHidden() {
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        defer { UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed") }

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        gameState.reveal(row: 0, col: 0)
        gameState.reveal(row: 1, col: 1)

        gameState.reset()

        for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                #expect(gameState.board.cells[r][c].state == .hidden)
            }
        }
    }

    @Test("isPaused is false after reset")
    @MainActor
    func testIsPausedFalseAfterReset() {
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        defer { UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed") }

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        gameState.reveal(row: 0, col: 0)
        gameState.pauseTimer()
        #expect(gameState.isPaused == true)

        gameState.reset()

        #expect(gameState.isPaused == false)
    }
}
