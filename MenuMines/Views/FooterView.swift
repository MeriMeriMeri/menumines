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
            // Left side: Share button
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
                .fixedSize()
                .accessibilityLabel(String(localized: "share_button"))
            }

            Spacer()
                .layoutPriority(1)

            Button {
                showControls.toggle()
            } label: {
                Image(systemName: "questionmark.circle")
            }
            .buttonStyle(.borderless)
            .fixedSize()
            .popover(isPresented: $showControls) {
                ControlsPopoverView()
            }
            .accessibilityLabel(String(localized: "controls_button_accessibility"))

            Menu {
                Button(String(localized: "reset_button")) {
                    showCopiedFeedback = false
                    onReset()
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(!canReset)
                .accessibilityHint(canReset ? String(localized: "reset_accessibility_hint") : String(localized: "reset_locked_hint"))

                Divider()

                Button(String(localized: "stats_menu_item")) {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "stats")
                }

                Button(String(localized: "settings_menu_item")) {
                    openSettings()
                }
                .keyboardShortcut(",", modifiers: .command)

                #if SPARKLE_ENABLED
                Divider()

                Button(String(localized: "check_for_updates_menu_item")) {
                    UpdateManager.checkForUpdates()
                }
                .disabled(!UpdateManager.canCheckForUpdates)
                #endif

                Divider()

                Button(String(localized: "about_menu_item")) {
                    onAbout()
                }

                Button(String(localized: "quit_menu_item")) {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            } label: {
                Image(systemName: "gearshape")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .accessibilityLabel(String(localized: "footer_menu_accessibility_label"))
        }
        .frame(width: 260)
    }
}

// MARK: - Controls Popover

private struct ControlsPopoverView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "controls_title"))
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                controlRow(key: "↑ ↓ ← →", action: String(localized: "controls_move"))
                controlRow(key: "Space", action: String(localized: "controls_reveal"))
                controlRow(key: "F", action: String(localized: "controls_flag"))
                controlRow(key: "⌘R", action: String(localized: "controls_reset"))
            }
            .font(.system(.body, design: .monospaced))
        }
        .padding()
    }

    private func controlRow(key: String, action: String) -> some View {
        HStack(spacing: 16) {
            Text(key)
                .frame(width: 70, alignment: .leading)
            Text(action)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(key): \(action)")
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
