import Foundation
import Sentry

// MARK: - GameSnapshot

/// Snapshot of game state for persistence.
/// Includes all data needed to restore an in-progress or completed game.
struct GameSnapshot: Codable {
    let board: Board
    let status: GameStatus
    let elapsedTime: TimeInterval
    let flagCount: Int
    let selectedRow: Int
    let selectedCol: Int
    let dailySeed: Int64
    let puzzleType: PuzzleType

    /// Coding keys for backward-compatible decoding.
    private enum CodingKeys: String, CodingKey {
        case board, status, elapsedTime, flagCount, selectedRow, selectedCol, dailySeed, puzzleType
    }

    /// Custom decoder to provide backward compatibility for existing snapshots without puzzleType.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        board = try container.decode(Board.self, forKey: .board)
        status = try container.decode(GameStatus.self, forKey: .status)
        elapsedTime = try container.decode(TimeInterval.self, forKey: .elapsedTime)
        flagCount = try container.decode(Int.self, forKey: .flagCount)
        selectedRow = try container.decode(Int.self, forKey: .selectedRow)
        selectedCol = try container.decode(Int.self, forKey: .selectedCol)
        dailySeed = try container.decode(Int64.self, forKey: .dailySeed)
        puzzleType = try container.decodeIfPresent(PuzzleType.self, forKey: .puzzleType) ?? .daily
    }

    init(board: Board, status: GameStatus, elapsedTime: TimeInterval, flagCount: Int,
         selectedRow: Int, selectedCol: Int, dailySeed: Int64, puzzleType: PuzzleType = .daily) {
        self.board = board
        self.status = status
        self.elapsedTime = elapsedTime
        self.flagCount = flagCount
        self.selectedRow = selectedRow
        self.selectedCol = selectedCol
        self.dailySeed = dailySeed
        self.puzzleType = puzzleType
    }

    private static let baseStorageKey = "gameSnapshot"
    @TaskLocal private static var storageKeySuffix: String?

    private static var storageKey: String {
        guard let suffix = storageKeySuffix, !suffix.isEmpty else {
            return baseStorageKey
        }
        return "\(baseStorageKey).\(suffix)"
    }

    /// Executes a closure using a namespaced snapshot storage key.
    static func withStorageKey<T>(_ suffix: String, _ body: () throws -> T) rethrows -> T {
        try $storageKeySuffix.withValue(suffix, operation: body)
    }

    /// Saves the snapshot to UserDefaults.
    func save() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            SentrySDK.capture(error: error) { scope in
                scope.setTag(value: "snapshot_save", key: "operation")
                scope.setContext(value: [
                    "daily_seed": dailySeed,
                    "status": status.rawValue,
                    "elapsed_time": elapsedTime,
                    "flag_count": flagCount
                ], key: "game_state")
            }
        }
    }

    /// Loads a snapshot from UserDefaults if one exists and is for today's puzzle.
    /// - Returns: The snapshot if valid for today, nil otherwise.
    static func load() -> GameSnapshot? {
        guard let snapshot = loadAnyDay() else { return nil }

        let todaySeed = seedFromDate(Date())
        guard snapshot.dailySeed == todaySeed else {
            clear()
            return nil
        }

        return snapshot
    }

    /// Loads a snapshot from UserDefaults regardless of which day it was saved.
    /// Used for rollover logic where we need to check the previous day's game status.
    /// - Returns: The snapshot if one exists and can be decoded, nil otherwise.
    static func loadAnyDay() -> GameSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }

        do {
            let snapshot = try JSONDecoder().decode(GameSnapshot.self, from: data)
            return snapshot
        } catch {
            // Snapshot corruption detected - log to Sentry and clear
            SentrySDK.capture(error: error) { scope in
                scope.setTag(value: "snapshot_load", key: "operation")
                scope.setContext(value: [
                    "data_size_bytes": data.count,
                    "today_seed": seedFromDate(Date())
                ], key: "persistence")
            }
            clear()
            return nil
        }
    }

    /// Clears any stored snapshot.
    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

// MARK: - GamePersistenceCoordinator

/// Coordinates game state persistence with clear decision logic.
/// Single entry point for restore eliminates scattered logic.
///
/// Decision tree for restore:
/// 1. continuousPlay ON → fresh game (daily or random based on completion)
/// 2. continuousPlay OFF → restore exact saved state
enum GamePersistenceCoordinator {

    /// Restores game state based on saved data and user settings.
    static func restore() -> GameState {
        let todaySeed = seedFromDate(Date())
        let continuousPlay = UserDefaults.standard.bool(
            forKey: Constants.SettingsKeys.continuousPlay
        )

        if continuousPlay {
            return restoreFreshGame(todaySeed: todaySeed)
        } else {
            return restoreSavedState(todaySeed: todaySeed)
        }
    }

    // MARK: - Private Decision Logic

    /// continuousPlay ON: Always start fresh.
    /// - If daily complete: fresh random puzzle
    /// - If daily not complete: fresh daily puzzle
    private static func restoreFreshGame(todaySeed: Int64) -> GameState {
        GameSnapshot.clear()

        if isDailyPuzzleComplete() {
            return createRandomPuzzle()
        } else {
            return createDailyPuzzle(seed: todaySeed)
        }
    }

    /// continuousPlay OFF: Restore exact saved state.
    /// - If snapshot exists for today: restore it
    /// - If snapshot is from previous day and game is playing: restore it (delay rollover)
    /// - If daily complete: restore from stats
    /// - Otherwise: fresh daily puzzle
    private static func restoreSavedState(todaySeed: Int64) -> GameState {
        // Try to restore from snapshot (only daily puzzles are persisted)
        if let snapshot = GameSnapshot.loadAnyDay() {
            if snapshot.dailySeed == todaySeed {
                return restoreFromSnapshot(snapshot)
            }

            // Delay rollover if game is still in progress
            if snapshot.status == .playing {
                return restoreFromSnapshot(snapshot)
            }

            // Snapshot from previous day, game not in progress - allow rollover
            GameSnapshot.clear()
        }

        // Check if daily is complete and restore completed state from stats if available
        if isDailyPuzzleComplete() {
            let board = Board(seed: todaySeed)
            if let restoredState = restoreFromStats(seed: todaySeed, board: board) {
                return restoredState
            }
        }

        // Create fresh board for today
        return createDailyPuzzle(seed: todaySeed)
    }

    // MARK: - Restore Helpers

    /// Restores a GameState from a snapshot.
    private static func restoreFromSnapshot(_ snapshot: GameSnapshot) -> GameState {
        let state = GameState(board: snapshot.board, dailySeed: snapshot.dailySeed, puzzleType: snapshot.puzzleType)
        state.status = snapshot.status
        state.elapsedTime = snapshot.elapsedTime

        // Use board's flag count as source of truth
        let actualFlagCount = snapshot.board.flagCount
        if snapshot.flagCount != actualFlagCount {
            SentrySDK.capture(message: "Flag count mismatch in snapshot") { scope in
                scope.setLevel(.warning)
                scope.setContext(value: [
                    "stored_count": snapshot.flagCount,
                    "actual_count": actualFlagCount,
                    "daily_seed": snapshot.dailySeed
                ], key: "flag_mismatch")
            }
        }
        state.flagCount = actualFlagCount

        state.selectedRow = snapshot.selectedRow
        state.selectedCol = snapshot.selectedCol
        return state
    }

    /// Attempts to restore game state from stats if today's puzzle was already completed.
    /// - Returns: GameState restored from stats, or nil if stats don't exist or are invalid
    private static func restoreFromStats(seed: Int64, board: Board) -> GameState? {
        guard let stats = getStats(for: Date()) else { return nil }

        guard stats.seed == seed else {
            // Data corruption - stats seed doesn't match expected seed
            SentrySDK.capture(message: "Stats seed mismatch: expected \(seed), got \(stats.seed)") { scope in
                scope.setLevel(.warning)
                scope.setContext(value: ["expectedSeed": seed, "actualSeed": stats.seed], key: "seedMismatch")
            }
            return nil
        }

        let state = GameState(board: board, dailySeed: seed)
        state.status = stats.won ? .won : .lost
        state.elapsedTime = stats.elapsedTime
        // Stats restoration uses a fresh board without flags, so trust the stored count
        state.flagCount = stats.flagCount

        // For lost games, reveal all mines so display is correct
        if !stats.won {
            state.board.revealAllMines()
        }

        return state
    }

    // MARK: - Create Helpers

    /// Creates a fresh daily puzzle for the given seed.
    private static func createDailyPuzzle(seed: Int64) -> GameState {
        let board = Board(seed: seed)
        return GameState(board: board, dailySeed: seed, puzzleType: .daily)
    }

    /// Creates a fresh random puzzle.
    private static func createRandomPuzzle() -> GameState {
        let seed = -Int64.random(in: 1...Int64.max)
        let board = Board(seed: seed)
        return GameState(board: board, dailySeed: seed, puzzleType: .random)
    }
}
