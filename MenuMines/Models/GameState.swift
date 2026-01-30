import AppKit
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
    private(set) var puzzleType: PuzzleType = .daily

    private var timer: Timer?
    /// Cache the last date we checked for rollover to avoid redundant calculations
    private var lastRolloverCheckDate: Date?
    /// Task for debouncing selection change announcements to prevent overlapping VoiceOver messages.
    private var announcementTask: Task<Void, Never>?

    /// Whether continuous play mode is enabled.
    private var isContinuousPlayEnabled: Bool {
        UserDefaults.standard.bool(forKey: Constants.SettingsKeys.continuousPlay)
    }

    /// Whether reset is allowed.
    /// Reset is locked once today's puzzle is completed unless continuous play is enabled.
    var canReset: Bool {
        if isDailyPuzzleComplete() {
            return isContinuousPlayEnabled
        }
        return true
    }

    init(board: Board, dailySeed: Int64 = seedFromDate(Date()), puzzleType: PuzzleType = .daily) {
        self.board = board
        self.dailySeed = dailySeed
        self.puzzleType = puzzleType
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

        // Result line with formatted time and flag count
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let timeString = String(format: "%d:%02d", minutes, seconds)
        let markedCorrect = countCorrectlyMarkedMines()
        if status == .won {
            lines.append(String(format: String(localized: "share_solved"), timeString, markedCorrect, Board.mineCount))
        } else {
            lines.append(String(format: String(localized: "share_failed"), timeString, markedCorrect, Board.mineCount))
        }

        // Emoji grid - difficulty heat map (fully spoiler-free)
        // Every cell shows its difficulty based on adjacent mine count
        // Mines are indistinguishable from safe cells - no gaps in the pattern
        // 🟩 = 0 adjacent mines (safe zone)
        // 🟡 = 1-2 adjacent mines (easy)
        // 🟠 = 3-4 adjacent mines (medium)
        // 🔴 = 5+ adjacent mines (danger zone)
        for row in 0..<Board.rows {
            var rowEmojis = ""
            for col in 0..<Board.cols {
                // Use adjacentMineCount for ALL cells (including mines)
                // This hides mine positions by showing uniform difficulty colors
                let adjacentMines = board.adjacentMineCount(row: row, col: col)
                if adjacentMines == 0 {
                    rowEmojis += "🟩"
                } else if adjacentMines <= 2 {
                    rowEmojis += "🟡"
                } else if adjacentMines <= 4 {
                    rowEmojis += "🟠"
                } else {
                    rowEmojis += "🔴"
                }
            }
            lines.append(rowEmojis)
        }

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
            board.revealAllMines()
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
            if flagCount > 0 {
                flagCount -= 1
            } else {
                // This should never happen in normal operation - log for debugging
                SentrySDK.capture(message: "Attempted to decrement flagCount below zero") { [self] scope in
                    scope.setLevel(.warning)
                    scope.setContext(value: [
                        "row": row,
                        "col": col,
                        "flag_count": flagCount,
                        "daily_seed": dailySeed
                    ], key: "flag_underflow")
                }
            }
        }
    }

    /// Resets the game to a fresh state.
    /// If continuous play is enabled and daily puzzle is complete, starts a random puzzle.
    /// Otherwise resets to today's daily puzzle.
    /// Does nothing if reset is locked (daily puzzle already completed and continuous play disabled).
    func reset() {
        guard canReset else { return }
        stopTimer()

        // If continuous play is enabled and daily is complete, start a random puzzle
        if isContinuousPlayEnabled && isDailyPuzzleComplete() {
            resetToRandomPuzzle()
        } else {
            // Reset to today's daily puzzle
            let seed = seedFromDate(Date())
            board = Board(seed: seed)
            dailySeed = seed
            puzzleType = .daily
            status = .notStarted
            elapsedTime = 0
            flagCount = 0
            selectedRow = 0
            selectedCol = 0
            isPaused = false
            GameSnapshot.clear()
        }
    }

    /// Resets to a new random puzzle for continuous play mode.
    private func resetToRandomPuzzle() {
        let randomSeed = generateRandomSeed()
        board = Board(seed: randomSeed)
        dailySeed = randomSeed
        puzzleType = .random
        status = .notStarted
        elapsedTime = 0
        flagCount = 0
        selectedRow = 0
        selectedCol = 0
        isPaused = false
        // Don't persist random puzzles
        GameSnapshot.clear()
    }

    /// Generates a random seed that won't collide with daily seeds (YYYYMMDD format).
    /// Uses negative values to ensure no collision.
    private func generateRandomSeed() -> Int64 {
        -Int64.random(in: 1...Int64.max)
    }

    // MARK: - Persistence

    /// Saves the current game state to persistent storage.
    /// Saves in-progress and completed daily games so state persists across app restarts.
    /// Does not save if game hasn't started yet or if it's a random puzzle.
    func save() {
        guard status != .notStarted else { return }
        // Don't persist random puzzles - they're discarded on app close
        guard puzzleType == .daily else { return }

        let snapshot = GameSnapshot(
            board: board,
            status: status,
            elapsedTime: elapsedTime,
            flagCount: flagCount,
            selectedRow: selectedRow,
            selectedCol: selectedCol,
            dailySeed: dailySeed,
            puzzleType: puzzleType
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
    /// Continuous play behavior:
    /// - If daily is complete: restore completed state from stats
    /// - Continuous play only affects whether reset can start a random puzzle
    ///
    /// Error recovery behavior:
    /// - If snapshot is corrupted but daily is complete: restore completed state from stats
    /// - If snapshot is corrupted and daily is not complete: create fresh game
    static func restored() -> GameState {
        let todaySeed = seedFromDate(Date())

        // Try to restore from snapshot (only daily puzzles are persisted)
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

        // Check if daily is complete and restore completed state from stats if available
        if isDailyPuzzleComplete() {
            let board = Board(seed: todaySeed)
            if let restoredState = tryRestoreFromStats(seed: todaySeed, board: board) {
                return restoredState
            }
        }

        // Create fresh board for today
        let board = Board(seed: todaySeed)
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
        // Stats restoration uses a fresh board without flags, so trust the stored count
        state.flagCount = stats.flagCount

        // For lost games, reveal all mines so display is correct
        if !stats.won {
            state.board.revealAllMines()
        }

        if !isDailyPuzzleComplete() {
            markDailyPuzzleComplete()
        }

        return state
    }

    /// Helper to restore a GameState from a snapshot.
    private static func restoreFromSnapshot(_ snapshot: GameSnapshot) -> GameState {
        let state = GameState(board: snapshot.board, dailySeed: snapshot.dailySeed, puzzleType: snapshot.puzzleType)
        state.status = snapshot.status
        state.elapsedTime = snapshot.elapsedTime

        // Validate flagCount matches actual flags on board
        let actualFlagCount = snapshot.board.cells.flatMap { $0 }.filter {
            if case .flagged = $0.state { return true }
            return false
        }.count

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
    /// - The current game is a daily puzzle (not random)
    /// - The current game's seed is from a previous day
    /// - AND the game is not in progress (status != .playing)
    ///
    /// If game is in progress, it continues until completion.
    /// Random puzzles are not date-bound and skip rollover checks.
    func checkForDailyRollover() {
        // Random puzzles are not tied to dates - skip rollover check
        guard puzzleType == .daily else { return }

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
        puzzleType = .daily
        status = .notStarted
        elapsedTime = 0
        flagCount = 0
        // Reset to top-left cell selection
        selectedRow = 0
        selectedCol = 0
        GameSnapshot.clear()
    }

    /// Checks if continuous play was disabled while on a random puzzle.
    /// If so, restores the completed daily puzzle state.
    ///
    /// This handles the scenario where:
    /// 1. User completes daily puzzle with continuous play enabled
    /// 2. User plays random puzzles
    /// 3. User disables continuous play
    /// 4. User should now see their completed daily puzzle (locked)
    func checkContinuousPlaySetting() {
        // Only applies when on a random puzzle with continuous play disabled
        guard puzzleType == .random, !isContinuousPlayEnabled else { return }

        // If daily is complete, restore that state
        guard isDailyPuzzleComplete() else { return }

        let todaySeed = seedFromDate(Date())

        // Try to restore from saved snapshot first
        if let snapshot = GameSnapshot.load(), snapshot.dailySeed == todaySeed {
            restoreFromDailySnapshot(snapshot)
            return
        }

        // Fall back to restoring from stats
        if let stats = getStats(for: Date()), stats.seed == todaySeed {
            restoreFromDailyStats(stats, seed: todaySeed)
        }
    }

    /// Restores state from a daily snapshot.
    private func restoreFromDailySnapshot(_ snapshot: GameSnapshot) {
        stopTimer()
        board = snapshot.board
        dailySeed = snapshot.dailySeed
        puzzleType = .daily
        status = snapshot.status
        elapsedTime = snapshot.elapsedTime

        // Count actual flags on board
        let actualFlagCount = snapshot.board.cells.flatMap { $0 }.filter {
            if case .flagged = $0.state { return true }
            return false
        }.count
        flagCount = actualFlagCount

        selectedRow = snapshot.selectedRow
        selectedCol = snapshot.selectedCol
        isPaused = false
    }

    /// Restores state from daily stats when snapshot is not available.
    private func restoreFromDailyStats(_ stats: DailyStats, seed: Int64) {
        stopTimer()
        board = Board(seed: seed)
        dailySeed = seed
        puzzleType = .daily
        status = stats.won ? .won : .lost
        elapsedTime = stats.elapsedTime
        flagCount = stats.flagCount
        selectedRow = 0
        selectedCol = 0
        isPaused = false

        // For lost games, reveal all mines so display is correct
        if !stats.won {
            board.revealAllMines()
        }
    }

    /// Moves the keyboard selection in the given direction.
    func moveSelection(_ direction: Direction) {
        let oldRow = selectedRow
        let oldCol = selectedCol

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

        if selectedRow != oldRow || selectedCol != oldCol {
            announceSelectedCell()
        }
    }

    /// Announces the currently selected cell for VoiceOver users.
    /// Debounced to prevent overlapping announcements during rapid navigation.
    private func announceSelectedCell() {
        // Cancel any pending announcement
        announcementTask?.cancel()

        // Capture values for announcement
        let row = selectedRow
        let col = selectedCol
        let cell = board.cells[row][col]

        // Schedule new announcement after brief delay
        announcementTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }

            let stateDescription = cellStateDescription(cell)
            let message = String(
                format: String(localized: "announcement_selection_changed"),
                row + 1,
                col + 1,
                stateDescription
            )
            AccessibilityNotification.Announcement(message).post()
        }
    }

    /// Returns a description of the cell state for accessibility announcements.
    private func cellStateDescription(_ cell: Cell) -> String {
        switch cell.state {
        case .hidden:
            return String(localized: "cell_state_covered")
        case .flagged:
            return String(localized: "cell_state_flagged")
        case .revealed(let adjacentMines):
            if adjacentMines == 0 {
                return String(localized: "cell_state_empty")
            } else if adjacentMines == 1 {
                return String(localized: "cell_state_one_mine")
            } else {
                return String(format: String(localized: "cell_state_mines"), adjacentMines)
            }
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
            board.revealAllMines()
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
            dailySeed: dailySeed,
            puzzleType: puzzleType
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
    /// For daily puzzles: marks complete, records stats, and saves state.
    /// For random puzzles: records stats only (no daily tracking).
    private func handleGameComplete(won: Bool) {
        stopTimer()

        if puzzleType == .daily {
            // Only mark daily completion and record daily stats for daily puzzles
            markCompleteAndRecordStats(won: won, elapsedTime: elapsedTime, flagCount: flagCount)
        }

        recordGameResult(won: won)
        save()
    }
}
