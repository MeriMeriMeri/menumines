import SwiftUI

struct FooterView: View {
    @Environment(\.openSettings) private var openSettings

    let isGameComplete: Bool
    let onReset: () -> Void
    let onShare: () -> Void
    let onAbout: () -> Void

    @State private var showCopiedFeedback = false

    var body: some View {
        HStack {
            Button(String(localized: "reset_button")) {
                showCopiedFeedback = false
                onReset()
            }
            .buttonStyle(.bordered)
            .keyboardShortcut("r", modifiers: .command)
            .accessibilityLabel(String(localized: "reset_accessibility_label"))

            Spacer()

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

            Menu {
                Button(String(localized: "about_menu_item")) {
                    onAbout()
                }

                Button(String(localized: "settings_menu_item")) {
                    openSettings()
                }
                .keyboardShortcut(",", modifiers: .command)

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

// MARK: - Previews

#Preview("Footer - Game In Progress") {
    FooterView(isGameComplete: false, onReset: {}, onShare: {}, onAbout: {})
        .padding()
}

#Preview("Footer - Game Complete") {
    FooterView(isGameComplete: true, onReset: {}, onShare: {}, onAbout: {})
        .padding()
}
