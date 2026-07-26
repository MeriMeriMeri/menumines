import Foundation
import Sentry

#if GAME_CENTER_ENABLED
import GameKit
#endif

/// Submits daily times to Game Center.
///
/// Only today's puzzle is ever submitted. Replays and random boards are unranked, and a
/// recurring daily leaderboard would be meaningless if yesterday's board could be posted to
/// today's list.
///
/// Compiled into the App Store build only: the entitlement lives in that target's
/// entitlements file, and the direct build has no provisioning profile to carry it.
@MainActor
enum Leaderboard {
    /// Matches the recurring leaderboard configured in App Store Connect, which resets daily
    /// at 00:00 UTC to line up with the puzzle itself.
    static let dailyTimeID = "com.merimerimeri.MenuMines.daily.time"

    #if GAME_CENTER_ENABLED
    private(set) static var isAuthenticated = false

    /// Signs the player in. Safe to call when Game Center is unavailable or declined — the
    /// player simply gets no leaderboard, and everything else keeps working.
    static func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            MainActor.assumeIsolated {
                if let error {
                    // Declining the sign-in is a normal outcome, not something to report.
                    if !isCancellation(error) {
                        SentrySDK.capture(error: error) { scope in
                            scope.setLevel(.info)
                            scope.setTag(value: "game_center_auth", key: "operation")
                        }
                    }
                    isAuthenticated = false
                    return
                }

                // A view controller means Game Center wants to show a sign-in sheet. This is
                // an agent app with no window to present from, so leave it to the player to
                // sign in through System Settings rather than forcing a window on them.
                guard viewController == nil else {
                    isAuthenticated = false
                    return
                }

                isAuthenticated = GKLocalPlayer.local.isAuthenticated
            }
        }
    }

    /// Submits a completed daily time.
    /// - Parameters:
    ///   - elapsedTime: Seconds taken. Submitted whole, since the leaderboard is formatted
    ///     as elapsed time to the second.
    ///   - puzzleType: Only `.daily` is submitted; anything else is ignored.
    ///   - won: Losses are not submitted — a leaderboard of times for boards nobody finished
    ///     would rank whoever hit a mine fastest.
    static func submitDailyTime(elapsedTime: TimeInterval, puzzleType: PuzzleType, won: Bool) {
        guard puzzleType.isRanked, won, isAuthenticated else { return }

        let seconds = Int(elapsedTime.rounded())
        guard seconds > 0 else { return }

        GKLeaderboard.submitScore(
            seconds,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [dailyTimeID]
        ) { error in
            guard let error else { return }
            SentrySDK.capture(error: error) { scope in
                scope.setTag(value: "game_center_submit", key: "operation")
                scope.setContext(value: [
                    "leaderboard": dailyTimeID,
                    "seconds": seconds
                ], key: "leaderboard")
            }
        }
    }

    private static func isCancellation(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == GKErrorDomain
            && (nsError.code == GKError.cancelled.rawValue || nsError.code == GKError.userDenied.rawValue)
    }
    #else
    static let isAuthenticated = false
    static func authenticate() {}
    static func submitDailyTime(elapsedTime: TimeInterval, puzzleType: PuzzleType, won: Bool) {}
    #endif
}
