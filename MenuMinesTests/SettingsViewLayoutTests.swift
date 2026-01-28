import AppKit
import SwiftUI
import Testing
@testable import MenuMines

@Suite("Settings View Layout Tests")
struct SettingsViewLayoutTests {
    @Test("Settings view content fits within fixed frame")
    @MainActor
    func testSettingsViewFitsInFixedFrame() {
        let hostingView = NSHostingView(rootView: SettingsView(usesFixedFrame: false))
        hostingView.frame = NSRect(x: 0, y: 0, width: SettingsView.Layout.width, height: 1000)
        hostingView.layoutSubtreeIfNeeded()
        let fittingSize = hostingView.fittingSize

        #expect(fittingSize.height <= SettingsView.Layout.height)
    }
}
