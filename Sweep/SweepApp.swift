import AppKit
import Sentry
import SwiftUI

@main
struct SweepApp: App {
    @State private var gameState: GameState

    private static var eventMonitor: Any?

    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    private static var sentryDsn: String? {
        guard let dsn = Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String else {
            return nil
        }
        let trimmed = dsn.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func startSentryIfNeeded() {
        guard !isDebugBuild, !isRunningTests else { return }
        guard let dsn = sentryDsn else { return }

        SentrySDK.start { options in
            options.dsn = dsn
            options.tracesSampleRate = 1.0
            options.enableAutoSessionTracking = true
        }
    }

    init() {
        Self.startSentryIfNeeded()

        let state = GameState.restored()
        _gameState = State(initialValue: state)
        Self.setupKeyboardMonitor(for: state)
        Self.setupTerminationObserver(for: state)
    }

    private static func setupTerminationObserver(for gameState: GameState) {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            gameState.save()
        }
    }

    private static func setupKeyboardMonitor(for gameState: GameState) {
        guard eventMonitor == nil else { return }

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 123: gameState.moveSelection(.left)
            case 124: gameState.moveSelection(.right)
            case 125: gameState.moveSelection(.down)
            case 126: gameState.moveSelection(.up)
            case 49:  gameState.revealSelected()
            default:
                if event.charactersIgnoringModifiers?.lowercased() == "f" {
                    gameState.toggleFlagSelected()
                } else {
                    return event
                }
            }
            return nil
        }
    }

    private var currentIconState: MenuBarIconState {
        menuBarIconState(
            gameStatus: gameState.status,
            isPaused: gameState.isPaused,
            isDailyComplete: isDailyPuzzleComplete()
        )
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(gameState: gameState)
        } label: {
            MenuBarIconView(state: currentIconState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}

/// Menu bar icon view with base grid icon and state-specific variant.
struct MenuBarIconView: View {
    let state: MenuBarIconState

    private var iconName: String {
        switch state {
        case .normal:
            return "circle.grid.3x3.fill"
        case .incomplete:
            return "circle.grid.3x3.fill"
        case .paused:
            return "pause.circle.fill"
        case .lost:
            return "xmark.circle.fill"
        }
    }

    var body: some View {
        Image(systemName: iconName)
            .accessibilityLabel(String(localized: "menubar_title"))
    }
}
