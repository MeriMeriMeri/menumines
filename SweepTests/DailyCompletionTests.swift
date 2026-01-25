import Foundation
import Testing
@testable import Sweep

@Suite("Daily Completion Tests", .serialized)
struct DailyCompletionTests {

    @Test("Daily puzzle is incomplete by default")
    func testDailyPuzzleIncompleteByDefault() {
        // Clear any existing completion
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")

        #expect(!isDailyPuzzleComplete())
    }

    @Test("Mark daily puzzle complete sets correct seed")
    func testMarkDailyPuzzleComplete() {
        // Clear any existing completion
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")

        markDailyPuzzleComplete()

        #expect(isDailyPuzzleComplete())
    }

    @Test("Daily puzzle completion is date-specific")
    func testDailyPuzzleCompletionIsDateSpecific() {
        // Clear any existing completion
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")

        // Mark yesterday as complete
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        markDailyPuzzleComplete(for: yesterday)

        // Today should still be incomplete
        #expect(!isDailyPuzzleComplete())

        // Yesterday should be complete
        #expect(isDailyPuzzleComplete(for: yesterday))
    }

    @Test("Different days have different completion states")
    func testDifferentDaysHaveDifferentCompletionStates() {
        // Clear any existing completion
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")

        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        markDailyPuzzleComplete(for: today)

        #expect(isDailyPuzzleComplete(for: today))
        #expect(!isDailyPuzzleComplete(for: tomorrow))
    }
}
