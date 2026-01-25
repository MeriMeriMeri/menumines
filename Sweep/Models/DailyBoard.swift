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
