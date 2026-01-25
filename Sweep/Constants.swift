import Foundation

/// Application-wide constants and configuration keys.
enum Constants {
    /// UserDefaults keys for application settings.
    enum SettingsKeys {
        /// Controls whether the menu bar icon shows dynamic status indicators.
        /// When false, the icon remains in the normal state regardless of game status.
        static let showMenuBarIndicators = "com.sweep.showMenuBarIndicators"

        /// Controls whether a confirmation dialog appears before resetting the game.
        /// When false (default), reset happens immediately.
        static let confirmBeforeReset = "com.sweep.confirmBeforeReset"

        /// Controls whether the game can be refreshed after completing the daily puzzle.
        /// When true, users can reset and replay even after winning or losing.
        /// Stats are only recorded for the first completion regardless of this setting.
        static let allowRefreshAfterCompletion = "com.sweep.allowRefreshAfterCompletion"
    }
}
