import Foundation
import Testing
@testable import Sweep

@Suite("Settings Tests", .serialized)
struct SettingsTests {

    // MARK: - Menu Bar Indicators Setting

    @Test("Menu bar indicators key is properly namespaced")
    func testMenuBarIndicatorsKeyIsNamespaced() {
        #expect(showMenuBarIndicatorsKey == "com.sweep.showMenuBarIndicators")
    }

    @Test("Menu bar indicators can be toggled via UserDefaults")
    func testMenuBarIndicatorsCanBeToggled() {
        // Test setting to false
        UserDefaults.standard.set(false, forKey: showMenuBarIndicatorsKey)
        #expect(UserDefaults.standard.bool(forKey: showMenuBarIndicatorsKey) == false)

        // Test setting to true
        UserDefaults.standard.set(true, forKey: showMenuBarIndicatorsKey)
        #expect(UserDefaults.standard.bool(forKey: showMenuBarIndicatorsKey) == true)

        // Cleanup
        UserDefaults.standard.removeObject(forKey: showMenuBarIndicatorsKey)
    }

    // MARK: - Icon State Logic with Setting

    @Test("menuBarIconState function returns expected states for testing")
    func testIconLogicReturnsExpectedStates() {
        // Verify the menuBarIconState function returns correct states
        // (the app layer overrides these when showMenuBarIndicators is false)
        let lostState = menuBarIconState(gameStatus: .lost, isPaused: false, isDailyComplete: false)
        let pausedState = menuBarIconState(gameStatus: .playing, isPaused: true, isDailyComplete: false)
        let incompleteState = menuBarIconState(gameStatus: .notStarted, isPaused: false, isDailyComplete: false)
        let normalState = menuBarIconState(gameStatus: .won, isPaused: false, isDailyComplete: true)

        #expect(lostState == .lost)
        #expect(pausedState == .paused)
        #expect(incompleteState == .incomplete)
        #expect(normalState == .normal)
    }
}
