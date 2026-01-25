import Foundation

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

    // MARK: - Recording

    /// Records a game result and persists to storage.
    @MainActor
    func record(_ result: GameResult) {
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
        guard let decoded = try? JSONDecoder().decode([GameResult].self, from: data) else { return }
        results = decoded
    }

    private func saveResults() {
        guard let data = try? JSONEncoder().encode(results) else { return }
        UserDefaults.standard.set(data, forKey: Self.resultsKey)
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
