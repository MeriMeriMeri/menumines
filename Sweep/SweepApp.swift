import SwiftUI

@main
struct SweepApp: App {
    var body: some Scene {
        MenuBarExtra("Sweep", systemImage: "circle.grid.3x3.fill") {
            MenuContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
