import AppKit
import Sentry
import SwiftUI

@main
struct MenuMinesApp: App {
    @State private var gameState: GameState
    @AppStorage(Constants.SettingsKeys.showMenuBarIndicators) private var showMenuBarIndicators = true

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

    private static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Constants.SettingsKeys.continuousPlay: true
        ])
    }

    init() {
        Self.startSentryIfNeeded()
        Self.registerDefaults()

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
            // Arrow keys for navigation
            switch event.keyCode {
            case 123: gameState.moveSelection(.left)
            case 124: gameState.moveSelection(.right)
            case 125: gameState.moveSelection(.down)
            case 126: gameState.moveSelection(.up)
            default:
                // Character-based keys
                if let chars = event.charactersIgnoringModifiers?.lowercased() {
                    switch chars {
                    case " ":
                        gameState.revealSelected()
                    case "f":
                        gameState.toggleFlagSelected()
                    default:
                        return event
                    }
                } else {
                    return event
                }
            }
            return nil
        }
    }

    private var currentIconState: MenuBarIconState {
        guard showMenuBarIndicators else {
            return .normal
        }
        return menuBarIconState(
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

        Window(String(localized: "stats_window_title"), id: "stats") {
            StatsWindow()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

/// Menu bar icon view showing state-specific icon with subtle indicators.
struct MenuBarIconView: View {
    let state: MenuBarIconState

    private var iconName: String {
        switch state {
        case .normal:
            return "square.grid.3x3.fill"
        case .incomplete:
            return "square.grid.3x3"
        case .paused:
            return "square.grid.3x3.topleft.filled"
        case .lost:
            return "square.grid.3x3.bottomright.filled"
        }
    }

    var body: some View {
        Image(systemName: iconName)
            .accessibilityLabel(String(localized: "menu_bar_title"))
    }
}
