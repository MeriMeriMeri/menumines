import Foundation

#if SPARKLE_ENABLED
import Sparkle
#endif

/// Manages application updates for direct distribution builds.
/// On App Store builds, all methods are no-ops since updates go through the App Store.
enum UpdateManager {
    #if SPARKLE_ENABLED
    private static let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    /// The underlying Sparkle updater instance.
    static var updater: SPUUpdater {
        updaterController.updater
    }

    /// Whether the updater is currently able to check for updates.
    static var canCheckForUpdates: Bool {
        updater.canCheckForUpdates
    }

    /// Manually trigger an update check.
    static func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    /// Whether to automatically check for updates periodically.
    static var automaticallyChecksForUpdates: Bool {
        get { updater.automaticallyChecksForUpdates }
        set { updater.automaticallyChecksForUpdates = newValue }
    }

    /// Whether to automatically download updates when found.
    static var automaticallyDownloadsUpdates: Bool {
        get { updater.automaticallyDownloadsUpdates }
        set { updater.automaticallyDownloadsUpdates = newValue }
    }

    /// The date of the last update check, if any.
    static var lastUpdateCheckDate: Date? {
        updater.lastUpdateCheckDate
    }
    #else
    static var canCheckForUpdates: Bool { false }
    static func checkForUpdates() {}
    static var automaticallyChecksForUpdates: Bool {
        get { false }
        set { }
    }
    static var automaticallyDownloadsUpdates: Bool {
        get { false }
        set { }
    }
    static var lastUpdateCheckDate: Date? { nil }
    #endif

    /// Returns true if this build supports updates (direct distribution only).
    static var isUpdateSupported: Bool {
        #if SPARKLE_ENABLED
        return true
        #else
        return false
        #endif
    }
}
