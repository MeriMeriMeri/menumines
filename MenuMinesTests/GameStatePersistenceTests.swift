import Foundation
import Testing
@testable import MenuMines

// MARK: - Persistence Tests with UserDefaults (Serialized)
// These tests use shared UserDefaults storage and must run serially to avoid interference

@Suite("GameState Persistence Tests", .serialized)
struct GameStatePersistenceTests {

    private func withIsolatedSnapshot<T>(_ testName: String = #function, _ body: () throws -> T) rethrows -> T {
        try GameSnapshot.withStorageKey("GameStatePersistenceTests.\(testName)", body)
    }

    @Test("GameSnapshot save and load works")
    func testGameSnapshotSaveLoad() {
        withIsolatedSnapshot {
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

    @Test("GameState restored does not restore stale snapshot when game was completed")
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

        // Create a snapshot with yesterday's seed and a completed game (won)
        // Completed games should roll over to today's puzzle
        let board = Board(seed: 12345)
        let staleSeed = seedFromDate(Date()) - 1
        let staleSnapshot = GameSnapshot(
            board: board,
            status: .won, // Completed game should trigger rollover
            elapsedTime: 100.0,
            flagCount: 5,
            selectedRow: 4,
            selectedCol: 4,
            dailySeed: staleSeed
        )
        staleSnapshot.save()

        // Restore should create fresh game for today
        let restoredState = GameState.restored()

        #expect(restoredState.status == .notStarted)
        #expect(restoredState.elapsedTime == 0)
        #expect(restoredState.flagCount == 0)
    }

    // MARK: - Continuous Play Tests

    @Test("Reset after daily completion with continuous play enabled starts random puzzle")
    func testResetAfterDailyStartsRandomWithContinuousPlay() {
        let settingKey = Constants.SettingsKeys.continuousPlay
        let initialSettingValue = UserDefaults.standard.object(forKey: settingKey)
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
        let todaySeed = seedFromDate(Date())
        UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        defer {
            if let initial = initialSettingValue {
                UserDefaults.standard.set(initial, forKey: settingKey)
            } else {
                UserDefaults.standard.removeObject(forKey: settingKey)
            }
            UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        }

        // Enable continuous play
        UserDefaults.standard.set(true, forKey: settingKey)

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Complete the daily puzzle
        winGame(gameState)
        #expect(gameState.status == .won)
        #expect(gameState.puzzleType == .daily)

        // Reset should start a random puzzle
        gameState.reset()

        #expect(gameState.status == .notStarted)
        #expect(gameState.puzzleType == .random, "Reset after daily completion should start random puzzle")
    }

    @Test("Reset is blocked after daily completion when continuous play disabled")
    func testResetBlockedAfterDailyWhenContinuousPlayDisabled() {
        let settingKey = Constants.SettingsKeys.continuousPlay
        let initialSettingValue = UserDefaults.standard.object(forKey: settingKey)
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
        let todaySeed = seedFromDate(Date())
        UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        defer {
            if let initial = initialSettingValue {
                UserDefaults.standard.set(initial, forKey: settingKey)
            } else {
                UserDefaults.standard.removeObject(forKey: settingKey)
            }
            UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        }

        // Disable continuous play
        UserDefaults.standard.set(false, forKey: settingKey)

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        winGame(gameState)
        #expect(gameState.status == .won)
        #expect(gameState.canReset == false)
        let elapsedAfterWin = gameState.elapsedTime

        // Reset should be blocked
        gameState.reset()

        #expect(gameState.status == .won)
        #expect(gameState.elapsedTime == elapsedAfterWin)
    }

    @Test("Reset before daily completion starts daily puzzle")
    func testResetBeforeDailyStartsDaily() {
        let settingKey = Constants.SettingsKeys.continuousPlay
        let initialSettingValue = UserDefaults.standard.object(forKey: settingKey)
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        defer {
            if let initial = initialSettingValue {
                UserDefaults.standard.set(initial, forKey: settingKey)
            } else {
                UserDefaults.standard.removeObject(forKey: settingKey)
            }
            UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        }

        // Enable continuous play
        UserDefaults.standard.set(true, forKey: settingKey)

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Start but don't complete
        guard let safe = findSafeCell(in: gameState.board) else {
            Issue.record("No safe cell found")
            return
        }
        gameState.reveal(row: safe.row, col: safe.col)
        #expect(gameState.status == .playing)

        // Reset should give a fresh daily puzzle
        gameState.reset()

        #expect(gameState.status == .notStarted)
        #expect(gameState.puzzleType == .daily, "Reset before completion should give daily puzzle")
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

    // MARK: - Board State Persistence Tests

    @Test("Winning a game saves board state with revealed cells")
    func testWinSavesBoardStateWithRevealedCells() {
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

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Win the game
        winGame(gameState)
        #expect(gameState.status == .won)

        // Verify snapshot was saved
        guard let snapshot = GameSnapshot.load() else {
            Issue.record("Snapshot should exist after winning")
            return
        }

        // Verify the board in snapshot has revealed cells (not all hidden)
        var revealedCount = 0
        for row in snapshot.board.cells {
            for cell in row {
                if case .revealed = cell.state {
                    revealedCount += 1
                }
            }
        }

        #expect(revealedCount > 0, "Snapshot should contain revealed cells")
        #expect(snapshot.status == .won, "Snapshot should have won status")
    }

    @Test("Losing a game saves board state with exploded mine")
    func testLoseSavesBoardStateWithExplodedMine() {
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

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Start game with a safe cell
        guard let safe = findSafeCell(in: gameState.board) else {
            Issue.record("No safe cell found")
            return
        }
        gameState.reveal(row: safe.row, col: safe.col)

        // Lose by clicking a mine
        guard let mine = findMineCell(in: gameState.board) else {
            Issue.record("No mine found")
            return
        }
        gameState.reveal(row: mine.row, col: mine.col)
        #expect(gameState.status == .lost)

        // Verify snapshot was saved
        guard let snapshot = GameSnapshot.load() else {
            Issue.record("Snapshot should exist after losing")
            return
        }

        // Verify the board in snapshot has the exploded mine
        #expect(snapshot.board.cells[mine.row][mine.col].isExploded, "Exploded mine should be saved")
        #expect(snapshot.status == .lost, "Snapshot should have lost status")
    }

    @Test("Restored game after win preserves board state with revealed cells")
    func testRestoredAfterWinPreservesBoardState() {
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

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Win the game
        winGame(gameState)
        #expect(gameState.status == .won)

        // Count revealed cells in original game
        var originalRevealedCount = 0
        for row in gameState.board.cells {
            for cell in row {
                if case .revealed = cell.state {
                    originalRevealedCount += 1
                }
            }
        }

        // Restore from snapshot
        let restoredState = GameState.restored()

        // Count revealed cells in restored game
        var restoredRevealedCount = 0
        for row in restoredState.board.cells {
            for cell in row {
                if case .revealed = cell.state {
                    restoredRevealedCount += 1
                }
            }
        }

        #expect(restoredState.status == .won, "Restored state should be won")
        #expect(restoredRevealedCount == originalRevealedCount, "Restored board should have same revealed cells")
        #expect(restoredState.board == gameState.board, "Restored board should match original")
    }

    @Test("Restored game after loss preserves board state with exploded mine")
    func testRestoredAfterLossPreservesBoardState() {
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

        // Restore from snapshot
        let restoredState = GameState.restored()

        #expect(restoredState.status == .lost, "Restored state should be lost")
        #expect(restoredState.board.cells[mine.row][mine.col].isExploded, "Restored board should have exploded mine")
        #expect(restoredState.board == gameState.board, "Restored board should match original")
    }

    @Test("Completed game with flags preserves flag positions after restore")
    func testRestoredPreservesFlagPositions() {
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

        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        // Find and flag some mines
        var flaggedPositions: [(row: Int, col: Int)] = []
        for r in 0..<Board.rows {
            for c in 0..<Board.cols {
                if gameState.board.cells[r][c].hasMine && flaggedPositions.count < 3 {
                    gameState.toggleFlag(row: r, col: c)
                    flaggedPositions.append((r, c))
                }
            }
        }

        // Win the game
        winGame(gameState)
        #expect(gameState.status == .won)
        #expect(gameState.flagCount == flaggedPositions.count)

        // Restore from snapshot
        let restoredState = GameState.restored()

        // Verify flag positions are preserved
        for pos in flaggedPositions {
            #expect(restoredState.board.cells[pos.row][pos.col].state == .flagged,
                   "Flag at (\(pos.row), \(pos.col)) should be preserved")
        }
        #expect(restoredState.flagCount == flaggedPositions.count, "Flag count should be preserved")
    }
}
