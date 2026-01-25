import Foundation
import Testing
@testable import Sweep

// .serialized required since tests manipulate shared UserDefaults state
@Suite("Settings Tests", .serialized)
struct SettingsTests {

    // MARK: - Menu Bar Indicators Setting

    @Test("Menu bar indicators key is properly namespaced")
    func testMenuBarIndicatorsKeyIsNamespaced() {
        #expect(Constants.SettingsKeys.showMenuBarIndicators == "com.sweep.showMenuBarIndicators")
    }

    // MARK: - Confirm Before Reset Setting

    @Test("Confirm before reset key is properly namespaced")
    func testConfirmBeforeResetKeyIsNamespaced() {
        #expect(Constants.SettingsKeys.confirmBeforeReset == "com.sweep.confirmBeforeReset")
    }

    @Test("Confirm before reset can be toggled via UserDefaults")
    func testConfirmBeforeResetCanBeToggled() {
        let key = Constants.SettingsKeys.confirmBeforeReset

        // Save initial state to restore after test
        let initialValue = UserDefaults.standard.object(forKey: key)

        // Test setting to true
        UserDefaults.standard.set(true, forKey: key)
        #expect(UserDefaults.standard.bool(forKey: key) == true)

        // Test setting to false
        UserDefaults.standard.set(false, forKey: key)
        #expect(UserDefaults.standard.bool(forKey: key) == false)

        // Restore initial state
        if let initial = initialValue {
            UserDefaults.standard.set(initial, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    @Test("Confirm before reset defaults to false when not set")
    func testConfirmBeforeResetDefaultsToFalse() {
        let key = Constants.SettingsKeys.confirmBeforeReset

        // Save initial state
        let initialValue = UserDefaults.standard.object(forKey: key)

        // Remove value to test default behavior
        UserDefaults.standard.removeObject(forKey: key)

        // bool(forKey:) returns false when key is not set
        #expect(UserDefaults.standard.bool(forKey: key) == false)

        // Restore initial state
        if let initial = initialValue {
            UserDefaults.standard.set(initial, forKey: key)
        }
    }

    // MARK: - Streaks Setting

    @Test("Show streaks key is properly namespaced")
    func testShowStreaksKeyIsNamespaced() {
        #expect(Constants.SettingsKeys.showStreaks == "com.sweep.showStreaks")
    }

    @Test("Show streaks can be toggled via UserDefaults")
    func testShowStreaksCanBeToggled() {
        let key = Constants.SettingsKeys.showStreaks
        // Save initial state to restore after test
        let initialValue = UserDefaults.standard.object(forKey: key)

        // Test setting to false
        UserDefaults.standard.set(false, forKey: key)
        #expect(UserDefaults.standard.bool(forKey: key) == false)

        // Test setting to true
        UserDefaults.standard.set(true, forKey: key)
        #expect(UserDefaults.standard.bool(forKey: key) == true)

        // Restore initial state
        if let initial = initialValue {
            UserDefaults.standard.set(initial, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: - Allow Refresh After Completion Setting

    @Test("Allow refresh after completion key is properly namespaced")
    func testAllowRefreshAfterCompletionKeyIsNamespaced() {
        #expect(Constants.SettingsKeys.allowRefreshAfterCompletion == "com.sweep.allowRefreshAfterCompletion")
    }

    @Test("Allow refresh after completion can be toggled via UserDefaults")
    func testAllowRefreshAfterCompletionCanBeToggled() {
        let key = Constants.SettingsKeys.allowRefreshAfterCompletion

        // Save initial state to restore after test
        let initialValue = UserDefaults.standard.object(forKey: key)

        // Test setting to false
        UserDefaults.standard.set(false, forKey: key)
        #expect(UserDefaults.standard.bool(forKey: key) == false)

        // Test setting to true
        UserDefaults.standard.set(true, forKey: key)
        #expect(UserDefaults.standard.bool(forKey: key) == true)

        // Restore initial state
        if let initial = initialValue {
            UserDefaults.standard.set(initial, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    @Test("canReset is true after completion when allowRefreshAfterCompletion is enabled")
    func testCanResetTrueAfterCompletionWhenSettingEnabled() {
        let settingKey = Constants.SettingsKeys.allowRefreshAfterCompletion

        // Save initial states
        let initialSettingValue = UserDefaults.standard.object(forKey: settingKey)
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
        let todaySeed = seedFromDate(Date())
        UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")

        defer {
            // Restore initial states
            if let initial = initialSettingValue {
                UserDefaults.standard.set(initial, forKey: settingKey)
            } else {
                UserDefaults.standard.removeObject(forKey: settingKey)
            }
            UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        }

        // Enable the setting
        UserDefaults.standard.set(true, forKey: settingKey)

        // Mark daily as complete
        markDailyPuzzleComplete()

        // Create a game state and check canReset
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.canReset == true, "canReset should be true when allowRefreshAfterCompletion is enabled")
    }

    @Test("canReset is false after completion when allowRefreshAfterCompletion is disabled")
    func testCanResetFalseAfterCompletionWhenSettingDisabled() {
        let settingKey = Constants.SettingsKeys.allowRefreshAfterCompletion

        // Save initial states
        let initialSettingValue = UserDefaults.standard.object(forKey: settingKey)
        UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
        UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
        let todaySeed = seedFromDate(Date())
        UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")

        defer {
            // Restore initial states
            if let initial = initialSettingValue {
                UserDefaults.standard.set(initial, forKey: settingKey)
            } else {
                UserDefaults.standard.removeObject(forKey: settingKey)
            }
            UserDefaults.standard.removeObject(forKey: "dailyCompletionSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStatsRecordedSeed")
            UserDefaults.standard.removeObject(forKey: "dailyStats_\(todaySeed)")
        }

        // Disable the setting (default behavior)
        UserDefaults.standard.set(false, forKey: settingKey)

        // Mark daily as complete
        markDailyPuzzleComplete()

        // Create a game state and check canReset
        let board = Board(seed: 12345)
        let gameState = GameState(board: board)

        #expect(gameState.canReset == false, "canReset should be false when allowRefreshAfterCompletion is disabled")
    }
    @Test("Menu bar indicators can be toggled via UserDefaults")
    func testMenuBarIndicatorsCanBeToggled() {
        let key = Constants.SettingsKeys.showMenuBarIndicators

        // Save initial state to restore after test
        let initialValue = UserDefaults.standard.object(forKey: key)

        // Test setting to false
        UserDefaults.standard.set(false, forKey: key)
        #expect(UserDefaults.standard.bool(forKey: key) == false)

        // Test setting to true
        UserDefaults.standard.set(true, forKey: key)
        #expect(UserDefaults.standard.bool(forKey: key) == true)

        // Restore initial state
        if let initial = initialValue {
            UserDefaults.standard.set(initial, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: - Icon State Logic

    @Test("menuBarIconState function returns expected states")
    func testMenuBarIconStateFunctionLogic() {
        // Verify the pure menuBarIconState function returns correct states
        let lostState = menuBarIconState(gameStatus: .lost, isPaused: false, isDailyComplete: false)
        let pausedState = menuBarIconState(gameStatus: .playing, isPaused: true, isDailyComplete: false)
        let incompleteState = menuBarIconState(gameStatus: .notStarted, isPaused: false, isDailyComplete: false)
        let normalState = menuBarIconState(gameStatus: .won, isPaused: false, isDailyComplete: true)

        #expect(lostState == .lost)
        #expect(pausedState == .paused)
        #expect(incompleteState == .incomplete)
        #expect(normalState == .normal)
    }

    @Test("Icon state respects showMenuBarIndicators setting when disabled")
    func testIconStateRespectsSettingWhenDisabled() {
        let key = Constants.SettingsKeys.showMenuBarIndicators

        // Save initial state
        let initialValue = UserDefaults.standard.object(forKey: key)

        // Simulate showMenuBarIndicators = false
        UserDefaults.standard.set(false, forKey: key)
        let showIndicators = UserDefaults.standard.bool(forKey: key)

        // Simulate the currentIconState logic from SweepApp
        let iconStateWhenLost: MenuBarIconState
        if showIndicators {
            iconStateWhenLost = menuBarIconState(gameStatus: .lost, isPaused: false, isDailyComplete: false)
        } else {
            iconStateWhenLost = .normal
        }

        // When setting is disabled, icon should be .normal regardless of game state
        #expect(iconStateWhenLost == .normal)

        // Simulate showMenuBarIndicators = true
        UserDefaults.standard.set(true, forKey: key)
        let showIndicatorsEnabled = UserDefaults.standard.bool(forKey: key)

        let iconStateWhenLostEnabled: MenuBarIconState
        if showIndicatorsEnabled {
            iconStateWhenLostEnabled = menuBarIconState(gameStatus: .lost, isPaused: false, isDailyComplete: false)
        } else {
            iconStateWhenLostEnabled = .normal
        }

        // When setting is enabled, icon should reflect actual game state
        #expect(iconStateWhenLostEnabled == .lost)

        // Restore initial state
        if let initial = initialValue {
            UserDefaults.standard.set(initial, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
