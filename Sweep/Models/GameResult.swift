import Foundation

/// Represents the outcome of a single completed game.
/// Stores raw data to enable computing derived metrics at runtime.
struct GameResult: Codable, Equatable {
    /// Whether the player won this game.
    let won: Bool

    /// Time taken to complete the game in seconds.
    let elapsedTime: TimeInterval

    /// The UTC date of the daily puzzle (stored as seed: YYYYMMDD).
    let dailySeed: Int64

    /// Timestamp when the game was completed.
    let completedAt: Date

    /// Creates a game result from the current game state.
    /// - Parameters:
    ///   - won: Whether the player won.
    ///   - elapsedTime: Time taken in seconds.
    ///   - dailySeed: The daily puzzle seed.
    init(won: Bool, elapsedTime: TimeInterval, dailySeed: Int64, completedAt: Date = Date()) {
        self.won = won
        self.elapsedTime = elapsedTime
        self.dailySeed = dailySeed
        self.completedAt = completedAt
    }
}
