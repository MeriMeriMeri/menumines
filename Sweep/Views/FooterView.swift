import SwiftUI

struct FooterView: View {
    @Environment(\.openSettings) private var openSettings

    let onReset: () -> Void
    let onAbout: () -> Void

    var body: some View {
        HStack {
            Button(String(localized: "reset_button")) {
                onReset()
            }
            .buttonStyle(.bordered)
            .keyboardShortcut("r", modifiers: .command)
            .accessibilityLabel(String(localized: "reset_accessibility_label"))

            Spacer()

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

#Preview("Footer") {
    FooterView(onReset: {}, onAbout: {})
        .padding()
}
