import Foundation
import Sentry

/// Keeps daily results in step across a player's Macs.
///
/// Streaks are the reason this exists: they are the thing that makes the daily worth coming
/// back to, and losing them to a new machine or a reinstall is the worst possible time to
/// lose them. Backed by `NSUbiquitousKeyValueStore`, which needs no CloudKit container and
/// is generous enough for one small record per day.
///
/// Compiled only into the App Store build. Key-value storage requires an entitlement the
/// direct-distribution build cannot carry without an embedded provisioning profile, and
/// Apple restricts the store to App Store distribution regardless.
@MainActor
enum StatsSync {
    private static let resultsKey = "dailyResults"
    /// A conservative ceiling. The store allows 1MB in total and 64KB per value; a year of
    /// daily results is a few KB, so exceeding this means something has gone wrong.
    private static let maximumPayloadBytes = 64_000

    #if ICLOUD_SYNC_ENABLED
    private static var store: NSUbiquitousKeyValueStore { .default }
    private static var observer: NSObjectProtocol?

    /// Begins syncing, merging whatever the cloud already knows about.
    static func start() {
        guard observer == nil else { return }

        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated { pullFromCloud() }
        }

        store.synchronize()
        pullFromCloud()
        pushToCloud()
    }

    /// Merges the cloud's daily results into the local store.
    static func pullFromCloud() {
        guard let data = store.data(forKey: resultsKey) else { return }

        do {
            let remote = try JSONDecoder().decode([GameResult].self, from: data)
            // A device that learns about days it had not seen should hand back the union, so
            // the next device to look finds everything rather than only its own history.
            if StatsStore.shared.merge(dailyResults: remote) {
                pushToCloud()
            }
        } catch {
            SentrySDK.capture(error: error) { scope in
                scope.setTag(value: "stats_sync_pull", key: "operation")
                scope.setContext(value: ["data_size_bytes": data.count], key: "sync")
            }
        }
    }

    /// Publishes the local daily results.
    static func pushToCloud() {
        let daily = StatsStore.shared.dailyResults
        guard !daily.isEmpty else { return }

        do {
            let data = try JSONEncoder().encode(daily)
            guard data.count <= maximumPayloadBytes else {
                SentrySDK.capture(message: "Daily results too large to sync") { scope in
                    scope.setLevel(.warning)
                    scope.setContext(value: [
                        "data_size_bytes": data.count,
                        "result_count": daily.count
                    ], key: "sync")
                }
                return
            }
            store.set(data, forKey: resultsKey)
            store.synchronize()
        } catch {
            SentrySDK.capture(error: error) { scope in
                scope.setTag(value: "stats_sync_push", key: "operation")
                scope.setContext(value: ["result_count": daily.count], key: "sync")
            }
        }
    }
    #else
    static func start() {}
    static func pullFromCloud() {}
    static func pushToCloud() {}
    #endif
}
