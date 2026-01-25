import SwiftUI

struct FooterView: View {
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow

    let isGameComplete: Bool
    let canReset: Bool
    let onReset: () -> Void
    let onShare: () -> Void
    let onAbout: () -> Void

    @State private var showCopiedFeedback = false
    @State private var showControls = false

    var body: some View {
        HStack {
            if isGameComplete {
                Button(showCopiedFeedback ? String(localized: "share_copied") : String(localized: "share_button")) {
                    onShare()
                    showCopiedFeedback = true
                    AccessibilityNotification.Announcement(String(localized: "share_copied")).post()
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        showCopiedFeedback = false
                    }
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(String(localized: "share_button"))
            }

            Spacer()

            Button {
                showControls.toggle()
            } label: {
                Image(systemName: "questionmark.circle")
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $showControls) {
                ControlsPopoverView(canReset: canReset)
            }
            .accessibilityLabel(String(localized: "controls_button_accessibility"))

            Menu {
                Button(String(localized: "reset_button")) {
                    showCopiedFeedback = false
                    onReset()
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(!canReset)

                Divider()

                Button(String(localized: "stats_menu_item")) {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "stats")
                }

                Button(String(localized: "settings_menu_item")) {
                    openSettings()
                }
                .keyboardShortcut(",", modifiers: .command)

                Button(String(localized: "about_menu_item")) {
                    onAbout()
                }

                Divider()

                Button(String(localized: "quit_menu_item")) {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            } label: {
                Image(systemName: "gearshape")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .accessibilityLabel(String(localized: "footer_menu_accessibility_label"))
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Controls Popover

private struct ControlsPopoverView: View {
    let canReset: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "controls_title"))
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                GridRow {
                    Text("↑ ↓ ← →")
                        .frame(width: 70, alignment: .leading)
                    Text(String(localized: "controls_move"))
                }
                GridRow {
                    Text("Space")
                        .frame(width: 70, alignment: .leading)
                    Text(String(localized: "controls_reveal"))
                }
                GridRow {
                    Text("F")
                        .frame(width: 70, alignment: .leading)
                    Text(String(localized: "controls_flag"))
                }
                if canReset {
                    GridRow {
                        Text("⌘R")
                            .frame(width: 70, alignment: .leading)
                        Text(String(localized: "controls_reset"))
                    }
                }
            }
            .font(.system(.body, design: .monospaced))
        }
        .padding()
    }
}

// MARK: - Previews

#Preview("Footer - Game In Progress") {
    FooterView(isGameComplete: false, canReset: true, onReset: {}, onShare: {}, onAbout: {})
        .padding()
}

#Preview("Footer - Game Complete") {
    FooterView(isGameComplete: true, canReset: true, onReset: {}, onShare: {}, onAbout: {})
        .padding()
}

#Preview("Footer - Reset Locked") {
    FooterView(isGameComplete: true, canReset: false, onReset: {}, onShare: {}, onAbout: {})
        .padding()
}
