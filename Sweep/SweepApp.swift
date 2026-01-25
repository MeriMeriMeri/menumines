import AppKit
import SwiftUI

@main
struct SweepApp: App {
    @State private var gameState: GameState

    private static var eventMonitor: Any?

    init() {
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
            case 49: gameState.revealSelected()
            case 3: gameState.toggleFlagSelected()
            default: break
            }
            return event
        }
    }

    var body: some Scene {
        MenuBarExtra("Sweep", systemImage: "circle.grid.3x3.fill") {
            MenuContentView(gameState: gameState)
        }
        .menuBarExtraStyle(.window)
    }
}
