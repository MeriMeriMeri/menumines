import SwiftUI

@main
struct SweepApp: App {
    @State private var gameState = GameState(board: dailyBoard())

    var body: some Scene {
        MenuBarExtra("Sweep", systemImage: "circle.grid.3x3.fill") {
            MenuContentView(gameState: gameState)
        }
        .menuBarExtraStyle(.window)
    }
}
