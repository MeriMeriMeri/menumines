import Foundation

/// Returns today's daily board using a UTC date-based seed.
func dailyBoard() -> Board {
    return boardForDate(Date())
}

/// Returns a board for a specific date using a UTC date-based seed.
func boardForDate(_ date: Date) -> Board {
    let seed = seedFromDate(date)
    return Board(seed: seed)
}

/// Computes a deterministic seed from a date using UTC timezone.
/// Formula: year * 10000 + month * 100 + day
/// Example: 2024-03-15 -> 20240315
func seedFromDate(_ date: Date) -> Int64 {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    let year = calendar.component(.year, from: date)
    let month = calendar.component(.month, from: date)
    let day = calendar.component(.day, from: date)
    return Int64(year * 10000 + month * 100 + day)
}

// MARK: - Daily Completion Tracking

private let dailyCompletionKey = "dailyCompletionSeed"
private let dailyStatsRecordedKey = "dailyStatsRecordedSeed"

/// Returns whether today's daily puzzle has been completed.
func isDailyPuzzleComplete() -> Bool {
    return isDailyPuzzleComplete(for: Date())
}

/// Returns whether the daily puzzle for a specific date has been completed.
func isDailyPuzzleComplete(for date: Date) -> Bool {
    let todaySeed = seedFromDate(date)
    let completedSeed = UserDefaults.standard.integer(forKey: dailyCompletionKey)
    return Int64(completedSeed) == todaySeed
}

/// Marks today's daily puzzle as complete.
func markDailyPuzzleComplete() {
    markDailyPuzzleComplete(for: Date())
}

/// Marks the daily puzzle for a specific date as complete.
func markDailyPuzzleComplete(for date: Date) {
    let seed = seedFromDate(date)
    UserDefaults.standard.set(Int(seed), forKey: dailyCompletionKey)
}

// MARK: - Daily Stats Recording

/// A single day's game stats.
struct DailyStats: Codable, Equatable {
    let seed: Int64
    let won: Bool
    let elapsedTime: TimeInterval
    let flagCount: Int
}

/// Returns whether stats have been recorded for today.
func hasStatsBeenRecorded() -> Bool {
    hasStatsBeenRecorded(for: Date())
}

/// Returns whether stats have been recorded for a specific date.
func hasStatsBeenRecorded(for date: Date) -> Bool {
    let todaySeed = seedFromDate(date)
    let recordedSeed = UserDefaults.standard.integer(forKey: dailyStatsRecordedKey)
    return Int64(recordedSeed) == todaySeed
}

/// Records stats for today's puzzle. Does nothing if stats have already been recorded.
/// - Parameters:
///   - won: Whether the player won
///   - elapsedTime: Time taken to complete
///   - flagCount: Number of flags placed
/// - Returns: True if stats were recorded, false if already recorded
@discardableResult
func recordStats(won: Bool, elapsedTime: TimeInterval, flagCount: Int) -> Bool {
    recordStats(for: Date(), won: won, elapsedTime: elapsedTime, flagCount: flagCount)
}

/// Records stats for a specific date's puzzle. Does nothing if stats have already been recorded.
/// - Parameters:
///   - date: The date of the puzzle
///   - won: Whether the player won
///   - elapsedTime: Time taken to complete
///   - flagCount: Number of flags placed
/// - Returns: True if stats were recorded, false if already recorded
@discardableResult
func recordStats(for date: Date, won: Bool, elapsedTime: TimeInterval, flagCount: Int) -> Bool {
    guard !hasStatsBeenRecorded(for: date) else { return false }

    let seed = seedFromDate(date)
    let stats = DailyStats(seed: seed, won: won, elapsedTime: elapsedTime, flagCount: flagCount)

    // Save the stats record
    if let data = try? JSONEncoder().encode(stats) {
        UserDefaults.standard.set(data, forKey: "dailyStats_\(seed)")
    }

    // Mark that stats have been recorded for this day
    UserDefaults.standard.set(Int(seed), forKey: dailyStatsRecordedKey)

    return true
}

/// Retrieves the stats for a specific date, if they exist.
func getStats(for date: Date) -> DailyStats? {
    let seed = seedFromDate(date)
    guard let data = UserDefaults.standard.data(forKey: "dailyStats_\(seed)") else { return nil }
    return try? JSONDecoder().decode(DailyStats.self, from: data)
}
