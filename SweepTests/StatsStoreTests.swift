import Foundation
import Testing
@testable import Sweep

@Suite("StatsStore Tests", .serialized)
struct StatsStoreTests {

    private let testResultsKey = "gameResults"

    private func clearStats() {
        UserDefaults.standard.removeObject(forKey: testResultsKey)
    }

    private func makeResult(
        won: Bool,
        elapsedTime: TimeInterval = 120,
        dailySeed: Int64 = 20260125,
        completedAt: Date = Date()
    ) -> GameResult {
        GameResult(won: won, elapsedTime: elapsedTime, dailySeed: dailySeed, completedAt: completedAt)
    }

    // MARK: - Empty State

    @Test("Empty store has no games played")
    func testEmptyStoreHasNoGamesPlayed() {
        let store = StatsStore.forTesting()
        #expect(store.gamesPlayed == 0)
        #expect(store.wins == 0)
        #expect(store.winRate == nil)
        #expect(store.bestTime == nil)
        #expect(store.averageTime == nil)
        #expect(store.trackedSince == nil)
        #expect(!store.hasResults)
    }

    // MARK: - Games Played

    @Test("Games played counts all results")
    func testGamesPlayedCountsAllResults() {
        let store = StatsStore.forTesting(with: [
            makeResult(won: true),
            makeResult(won: false),
            makeResult(won: true)
        ])
        #expect(store.gamesPlayed == 3)
    }

    // MARK: - Wins

    @Test("Wins counts only winning games")
    func testWinsCountsOnlyWinningGames() {
        let store = StatsStore.forTesting(with: [
            makeResult(won: true),
            makeResult(won: false),
            makeResult(won: true),
            makeResult(won: false)
        ])
        #expect(store.wins == 2)
    }

    // MARK: - Win Rate

    @Test("Win rate calculates correctly")
    func testWinRateCalculatesCorrectly() {
        let store = StatsStore.forTesting(with: [
            makeResult(won: true),
            makeResult(won: true),
            makeResult(won: false),
            makeResult(won: false)
        ])
        #expect(store.winRate == 50)
    }

    @Test("Win rate rounds to whole percent")
    func testWinRateRoundsToWholePercent() {
        let store = StatsStore.forTesting(with: [
            makeResult(won: true),
            makeResult(won: true),
            makeResult(won: false)
        ])
        // 2/3 = 66.67% -> rounds to 67%
        #expect(store.winRate == 67)
    }

    @Test("Win rate is 100% when all wins")
    func testWinRateIs100WhenAllWins() {
        let store = StatsStore.forTesting(with: [
            makeResult(won: true),
            makeResult(won: true)
        ])
        #expect(store.winRate == 100)
    }

    @Test("Win rate is 0% when no wins")
    func testWinRateIs0WhenNoWins() {
        let store = StatsStore.forTesting(with: [
            makeResult(won: false),
            makeResult(won: false)
        ])
        #expect(store.winRate == 0)
    }

    // MARK: - Best Time

    @Test("Best time is minimum of wins only")
    func testBestTimeIsMinimumOfWinsOnly() {
        let store = StatsStore.forTesting(with: [
            makeResult(won: true, elapsedTime: 120),
            makeResult(won: false, elapsedTime: 50),  // Should be ignored
            makeResult(won: true, elapsedTime: 90),
            makeResult(won: true, elapsedTime: 150)
        ])
        #expect(store.bestTime == 90)
    }

    @Test("Best time is nil when no wins")
    func testBestTimeIsNilWhenNoWins() {
        let store = StatsStore.forTesting(with: [
            makeResult(won: false, elapsedTime: 50)
        ])
        #expect(store.bestTime == nil)
    }

    // MARK: - Average Time

    @Test("Average time is calculated from wins only")
    func testAverageTimeIsCalculatedFromWinsOnly() {
        let store = StatsStore.forTesting(with: [
            makeResult(won: true, elapsedTime: 100),
            makeResult(won: false, elapsedTime: 50),  // Should be ignored
            makeResult(won: true, elapsedTime: 200)
        ])
        #expect(store.averageTime == 150)
    }

    @Test("Average time is nil when no wins")
    func testAverageTimeIsNilWhenNoWins() {
        let store = StatsStore.forTesting(with: [
            makeResult(won: false, elapsedTime: 100)
        ])
        #expect(store.averageTime == nil)
    }

    // MARK: - Tracked Since

    @Test("Tracked since is earliest result date")
    func testTrackedSinceIsEarliestResultDate() {
        let earliest = Date(timeIntervalSince1970: 1000)
        let middle = Date(timeIntervalSince1970: 2000)
        let latest = Date(timeIntervalSince1970: 3000)

        let store = StatsStore.forTesting(with: [
            makeResult(won: true, completedAt: latest),
            makeResult(won: false, completedAt: earliest),
            makeResult(won: true, completedAt: middle)
        ])
        #expect(store.trackedSince == earliest)
    }

    // MARK: - Recording

    @Test("Recording a result adds it to the store")
    @MainActor
    func testRecordingResultAddsToStore() {
        clearStats()
        let store = StatsStore.forTesting()
        let result = makeResult(won: true)

        store.record(result)

        #expect(store.gamesPlayed == 1)
        #expect(store.wins == 1)
    }

    // MARK: - Reset

    @Test("Reset clears all results")
    @MainActor
    func testResetClearsAllResults() {
        let store = StatsStore.forTesting(with: [
            makeResult(won: true),
            makeResult(won: false)
        ])

        store.reset()

        #expect(store.gamesPlayed == 0)
        #expect(!store.hasResults)
    }

    // MARK: - Persistence

    @Test("Stats persist to UserDefaults")
    @MainActor
    func testStatsPersistToUserDefaults() {
        clearStats()
        let store = StatsStore.forTesting()
        let result = makeResult(won: true, elapsedTime: 100)

        store.record(result)

        guard let data = UserDefaults.standard.data(forKey: testResultsKey) else {
            Issue.record("Expected data to be saved to UserDefaults")
            return
        }

        guard let decoded = try? JSONDecoder().decode([GameResult].self, from: data) else {
            Issue.record("Expected data to be decodable")
            return
        }

        #expect(decoded.count == 1)
        #expect(decoded[0].won == true)
        #expect(decoded[0].elapsedTime == 100)
    }
}
