import AppKit
import Sentry
import SwiftUI

@main
struct SweepApp: App {
    @State private var gameState: GameState

    private static var eventMonitor: Any?

    init() {
        SentrySDK.start { options in
            options.dsn = "https://f8ecbb949a8bf0fd4753391a9947b061@o4510771621789696.ingest.us.sentry.io/4510771626311680"
            #if DEBUG
            options.debug = true
            #endif
            options.tracesSampleRate = 1.0
            options.enableAutoSessionTracking = true
        }

        let state = GameState(board: dailyBoard())
        _gameState = State(initialValue: state)
        Self.setupKeyboardMonitor(for: state)
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

    var body: some Scene {
        MenuBarExtra("Sweep", systemImage: "circle.grid.3x3.fill") {
            MenuContentView(gameState: gameState)
        }
        .menuBarExtraStyle(.window)
    }
}
