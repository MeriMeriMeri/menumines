import Foundation
import Sentry

/// Manages persistence and retrieval of game statistics.
/// Stores raw game results and computes derived metrics at runtime.
@Observable
final class StatsStore {
    private static let resultsKey = "gameResults"

    /// All recorded game results, sorted by completion date (newest first).
    private(set) var results: [GameResult] = []

    /// Shared singleton instance.
    static let shared = StatsStore()

    private init() {
        loadResults()
    }

    // MARK: - Computed Metrics

    /// Total number of games played.
    var gamesPlayed: Int {
        results.count
    }

    /// Number of games won.
    var wins: Int {
        results.filter(\.won).count
    }

    /// Win rate as a percentage (0-100), or nil if no games played.
    var winRate: Int? {
        guard gamesPlayed > 0 else { return nil }
        return Int(round(Double(wins) / Double(gamesPlayed) * 100))
    }

    /// Best time among wins in seconds, or nil if no wins.
    var bestTime: TimeInterval? {
        let winTimes = results.filter(\.won).map(\.elapsedTime)
        return winTimes.min()
    }

    /// Average time among wins in seconds, or nil if no wins.
    var averageTime: TimeInterval? {
        let winTimes = results.filter(\.won).map(\.elapsedTime)
        guard !winTimes.isEmpty else { return nil }
        return winTimes.reduce(0, +) / Double(winTimes.count)
    }

    /// Date when tracking started (earliest recorded result), or nil if no games.
    var trackedSince: Date? {
        results.map(\.completedAt).min()
    }

    /// Whether there are any recorded games.
    var hasResults: Bool {
        !results.isEmpty
    }

    /// Current consecutive-day streak based on completed daily seeds.
    var currentStreak: Int {
        let dates = completionDates
        guard let latest = dates.last else { return 0 }

        let calendar = Self.utcCalendar
        var streak = 1
        var previous = latest

        for date in dates.dropLast().reversed() {
            guard let expected = calendar.date(byAdding: .day, value: -1, to: previous),
                  calendar.isDate(date, inSameDayAs: expected) else {
                break
            }
            streak += 1
            previous = date
        }

        return streak
    }

    /// Longest consecutive-day streak based on completed daily seeds.
    var longestStreak: Int {
        let dates = completionDates
        guard !dates.isEmpty else { return 0 }

        let calendar = Self.utcCalendar
        var longest = 1
        var current = 1
        var previous = dates[0]

        for date in dates.dropFirst() {
            if let expected = calendar.date(byAdding: .day, value: 1, to: previous),
               calendar.isDate(date, inSameDayAs: expected) {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
            previous = date
        }

        return longest
    }

    // MARK: - Recording

    /// Records a game result and persists to storage.
    /// Deduplicates by dailySeed - only one result per day is stored.
    @MainActor
    func record(_ result: GameResult) {
        // Check if we already have a result for this daily seed
        if results.contains(where: { $0.dailySeed == result.dailySeed }) {
            return
        }
        results.insert(result, at: 0)
        saveResults()
    }

    /// Clears all statistics.
    @MainActor
    func reset() {
        results = []
        UserDefaults.standard.removeObject(forKey: Self.resultsKey)
    }

    // MARK: - Persistence

    private func loadResults() {
        guard let data = UserDefaults.standard.data(forKey: Self.resultsKey) else { return }
        do {
            results = try JSONDecoder().decode([GameResult].self, from: data)
        } catch {
            SentrySDK.capture(error: error) { scope in
                scope.setTag(value: "stats_load", key: "operation")
                scope.setContext(value: [
                    "data_size_bytes": data.count
                ], key: "persistence")
            }
        }
    }

    private func saveResults() {
        do {
            let data = try JSONEncoder().encode(results)
            UserDefaults.standard.set(data, forKey: Self.resultsKey)
        } catch {
            SentrySDK.capture(error: error) { scope in
                scope.setTag(value: "stats_save", key: "operation")
                scope.setContext(value: [
                    "results_count": self.results.count
                ], key: "persistence")
            }
        }
    }

    // MARK: - Streak Helpers

    private static var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    private var completionDates: [Date] {
        let uniqueSeeds = Set(results.map(\.dailySeed))
        return uniqueSeeds.compactMap { dateFromSeed($0) }.sorted()
    }

    // MARK: - Testing Support

    /// Creates a StatsStore with the given results for testing purposes.
    /// - Parameter results: The initial results to populate.
    static func forTesting(with results: [GameResult] = []) -> StatsStore {
        let store = StatsStore()
        store.results = results
        return store
    }
}
