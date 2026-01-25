import Foundation
import Sentry

/// Snapshot of game state for persistence.
/// Includes all data needed to restore an in-progress game.
struct GameSnapshot: Codable {
    let board: Board
    let status: GameStatus
    let elapsedTime: TimeInterval
    let flagCount: Int
    let selectedRow: Int
    let selectedCol: Int
    let dailySeed: Int64

    private static let storageKey = "gameSnapshot"

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

/// The current status of the game.
enum GameStatus: String, Equatable, Codable {
    case notStarted
    case playing
    case won
    case lost
}

/// Direction for keyboard navigation.
enum Direction {
    case up, down, left, right
}

/// Observable game state that owns the board and manages game logic.
@Observable
final class GameState {
    private(set) var board: Board
    private(set) var status: GameStatus = .notStarted
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var flagCount: Int = 0
    private(set) var selectedRow: Int = 0
    private(set) var selectedCol: Int = 0
    private var dailySeed: Int64
    private(set) var isPaused: Bool = false

    private var timer: Timer?
    /// Cache the last date we checked for rollover to avoid redundant calculations
    private var lastRolloverCheckDate: Date?

    /// Whether reset is allowed. Reset is locked once today's puzzle is completed.
    var canReset: Bool {
        !isDailyPuzzleComplete()
    }

    init(board: Board, dailySeed: Int64 = seedFromDate(Date())) {
        self.board = board
        self.dailySeed = dailySeed
    }

    /// Generates a Wordle-style share text for the completed game.
    /// The grid encodes only the revealed/marked/hidden outcome without exposing mine locations.
    /// - Parameter date: The date to use for the header (defaults to current date formatted in UTC).
    /// - Returns: The formatted share text, or nil if the game is not complete.
    func shareText(for date: Date = Date()) -> String? {
        guard status == .won || status == .lost else { return nil }

        var lines: [String] = []

        // Header with UTC date
        let timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0) ?? .current
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let dateString = formatter.string(from: date)
        lines.append(String(format: String(localized: "share_header"), dateString))

        // Result line with formatted time
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let timeString = String(format: "%d:%02d", minutes, seconds)
        if status == .won {
            lines.append(String(format: String(localized: "share_solved"), timeString))
        } else {
            lines.append(String(format: String(localized: "share_failed"), timeString))
        }

        // Emoji grid - encode only visual outcome, not mine locations
        // 🟩 = revealed safe cell
        // 🚩 = flagged cell
        // ⬛️ = unrevealed/hidden cell
        for row in 0..<Board.rows {
            var rowEmojis = ""
            for col in 0..<Board.cols {
                let cell = board.cells[row][col]
                switch cell.state {
                case .revealed:
                    rowEmojis += "🟩"
                case .flagged:
                    rowEmojis += "🚩"
                case .hidden:
                    rowEmojis += "⬛️"
                }
            }
            lines.append(rowEmojis)
        }

        // Marked count
        let markedCorrect = countCorrectlyMarkedMines()
        lines.append(String(format: String(localized: "share_marked"), markedCorrect, Board.mineCount))

        return lines.joined(separator: "\n")
    }

    /// Counts the number of flags placed on actual mines.
    private func countCorrectlyMarkedMines() -> Int {
        var count = 0
        for row in board.cells {
            for cell in row {
                if case .flagged = cell.state, cell.hasMine {
                    count += 1
                }
            }
        }
        return count
    }

    /// Reveals the cell at the given position.
    /// If the cell is already revealed with a number, performs a chord reveal instead.
    func reveal(row: Int, col: Int) {
        guard status == .notStarted || status == .playing else { return }
        guard row >= 0, row < Board.rows, col >= 0, col < Board.cols else { return }

        if case .revealed(let adjacentMines) = board.cells[row][col].state, adjacentMines > 0 {
            chordReveal(row: row, col: col)
            return
        }

        guard case .hidden = board.cells[row][col].state else { return }

        let isFirstClick = (status == .notStarted)
        if isFirstClick {
            if board.cells[row][col].hasMine {
                board.relocateMine(from: row, col: col)
            }
            startTimer()
            status = .playing
        }

        let result = board.reveal(row: row, col: col)

        switch result {
        case .mine:
            status = .lost
            handleGameComplete(won: false)
        case .safe:
            if checkWinCondition() {
                status = .won
                handleGameComplete(won: true)
            }
        }
    }

    /// Toggles the flag on the cell at the given position.
    func toggleFlag(row: Int, col: Int) {
        guard status == .notStarted || status == .playing else { return }
        guard row >= 0, row < Board.rows, col >= 0, col < Board.cols else { return }

        let previousState = board.cells[row][col].state
        board.toggleFlag(row: row, col: col)
        let newState = board.cells[row][col].state

        // Update flag count
        if case .flagged = newState {
            flagCount += 1
        } else if case .flagged = previousState {
            flagCount -= 1
        }
    }

    /// Resets the game to a fresh state with today's daily board.
    /// Does nothing if reset is locked (daily puzzle already completed).
    func reset() {
        guard canReset else { return }
        stopTimer()
        let seed = seedFromDate(Date())
        board = Board(seed: seed)
        dailySeed = seed
        status = .notStarted
        elapsedTime = 0
        flagCount = 0
        selectedRow = 0
        selectedCol = 0
        isPaused = false
        GameSnapshot.clear()
    }

    // MARK: - Persistence

    /// Saves the current game state to persistent storage.
    /// Saves in-progress and completed games so state persists across app restarts.
    /// Does not save if game hasn't started yet.
    func save() {
        guard status != .notStarted else { return }

        let snapshot = GameSnapshot(
            board: board,
            status: status,
            elapsedTime: elapsedTime,
            flagCount: flagCount,
            selectedRow: selectedRow,
            selectedCol: selectedCol,
            dailySeed: dailySeed
        )
        snapshot.save()
    }

    /// Creates a GameState by restoring from a saved snapshot if available,
    /// otherwise creates a fresh game with today's daily board.
    ///
    /// Rollover behavior:
    /// - If snapshot is from today: restore full state
    /// - If snapshot is from a previous day AND game is in progress (.playing):
    ///   restore the old game (delay rollover until game ends)
    /// - If snapshot is from a previous day AND game is not in progress:
    ///   create fresh game for today (allow rollover)
    ///
    /// Error recovery behavior:
    /// - If snapshot is corrupted but daily is complete: restore completed state from stats
    /// - If snapshot is corrupted and daily is not complete: create fresh game
    static func restored() -> GameState {
        let todaySeed = seedFromDate(Date())

        // Try to restore from snapshot
        if let snapshot = GameSnapshot.loadAnyDay() {
            if snapshot.dailySeed == todaySeed {
                return restoreFromSnapshot(snapshot)
            }

            if shouldDelayRollover(snapshot: snapshot) {
                return restoreFromSnapshot(snapshot)
            }

            // Snapshot from previous day, game not in progress - allow rollover
            GameSnapshot.clear()
        }

        // Create fresh board for today
        let board = Board(seed: todaySeed)

        // Try to restore completion state from stats if available
        if let restoredState = tryRestoreFromStats(seed: todaySeed, board: board) {
            return restoredState
        }

        return GameState(board: board, dailySeed: todaySeed)
    }

    /// Determines if rollover should be delayed for a previous day's snapshot.
    /// Rollover is delayed when the game is still in progress.
    private static func shouldDelayRollover(snapshot: GameSnapshot) -> Bool {
        snapshot.status == .playing
    }

    /// Attempts to restore game state from stats if today's puzzle was already completed.
    /// - Returns: GameState restored from stats, or nil if stats don't exist or are invalid
    private static func tryRestoreFromStats(seed: Int64, board: Board) -> GameState? {
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
        state.flagCount = stats.flagCount

        if !isDailyPuzzleComplete() {
            markDailyPuzzleComplete()
        }

        return state
    }

    /// Helper to restore a GameState from a snapshot.
    private static func restoreFromSnapshot(_ snapshot: GameSnapshot) -> GameState {
        let state = GameState(board: snapshot.board, dailySeed: snapshot.dailySeed)
        state.status = snapshot.status
        state.elapsedTime = snapshot.elapsedTime
        state.flagCount = snapshot.flagCount
        state.selectedRow = snapshot.selectedRow
        state.selectedCol = snapshot.selectedCol
        return state
    }

    /// Pauses the timer (e.g., when popover closes).
    func pauseTimer() {
        timer?.invalidate()
        timer = nil
        if status == .playing {
            isPaused = true
        }
    }

    /// Resumes the timer (e.g., when popover reopens).
    func resumeTimer() {
        guard status == .playing else { return }
        isPaused = false
        startTimer()
    }

    /// Checks if we should roll over to today's puzzle and performs the rollover if needed.
    /// Called when the popover appears to handle day changes.
    ///
    /// Rollover happens when:
    /// - The current game's seed is from a previous day
    /// - AND the game is not in progress (status != .playing)
    ///
    /// If game is in progress, it continues until completion.
    func checkForDailyRollover() {
        let now = Date()

        // Check if we've already checked today (cache optimization)
        if let lastCheck = lastRolloverCheckDate,
           Calendar.current.isDate(lastCheck, inSameDayAs: now) {
            return
        }

        lastRolloverCheckDate = now
        let todaySeed = seedFromDate(now)

        // Already on today's puzzle
        guard dailySeed != todaySeed else { return }

        // Game is in progress - delay rollover
        guard status != .playing else { return }

        // Roll over to today's puzzle
        rolloverToNewDay(seed: todaySeed)
    }

    /// Performs a rollover to a new day's puzzle.
    private func rolloverToNewDay(seed: Int64) {
        // Stop timer and reset isPaused flag (stopTimer handles both)
        stopTimer()
        board = Board(seed: seed)
        dailySeed = seed
        status = .notStarted
        elapsedTime = 0
        flagCount = 0
        // Reset to top-left cell selection
        selectedRow = 0
        selectedCol = 0
        GameSnapshot.clear()
    }

    /// Moves the keyboard selection in the given direction.
    func moveSelection(_ direction: Direction) {
        switch direction {
        case .up:
            selectedRow = max(0, selectedRow - 1)
        case .down:
            selectedRow = min(Board.rows - 1, selectedRow + 1)
        case .left:
            selectedCol = max(0, selectedCol - 1)
        case .right:
            selectedCol = min(Board.cols - 1, selectedCol + 1)
        }
    }

    /// Reveals the currently selected cell.
    func revealSelected() {
        reveal(row: selectedRow, col: selectedCol)
    }

    /// Toggles the flag on the currently selected cell.
    func toggleFlagSelected() {
        toggleFlag(row: selectedRow, col: selectedCol)
    }

    /// Performs a chord reveal on the cell at the given position.
    func chordReveal(row: Int, col: Int) {
        guard status == .playing else { return }
        guard row >= 0, row < Board.rows, col >= 0, col < Board.cols else { return }

        switch board.chordReveal(row: row, col: col) {
        case .mine:
            status = .lost
            handleGameComplete(won: false)
        case .safe:
            if checkWinCondition() {
                status = .won
                handleGameComplete(won: true)
            }
        }
    }

    /// Performs a chord reveal on the currently selected cell.
    func chordRevealSelected() {
        chordReveal(row: selectedRow, col: selectedCol)
    }

    // MARK: - Private

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.elapsedTime += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isPaused = false
    }

    /// Records the game result to the stats store.
    private func recordGameResult(won: Bool) {
        let result = GameResult(
            won: won,
            elapsedTime: elapsedTime,
            dailySeed: dailySeed
        )
        Task { @MainActor in
            StatsStore.shared.record(result)
        }
    }

    private func checkWinCondition() -> Bool {
        for row in board.cells {
            for cell in row where !cell.hasMine {
                guard case .revealed = cell.state else {
                    return false
                }
            }
        }
        return true
    }

    /// Handles game completion (win or loss).
    /// Atomically marks daily puzzle as complete, records stats, and saves the board state.
    private func handleGameComplete(won: Bool) {
        stopTimer()
        markCompleteAndRecordStats(won: won, elapsedTime: elapsedTime, flagCount: flagCount)
        recordGameResult(won: won)
        save()
    }
}
