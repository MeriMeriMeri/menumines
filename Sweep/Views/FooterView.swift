import SwiftUI

struct FooterView: View {
    let onReset: () -> Void
    let onAbout: () -> Void

    var body: some View {
        HStack {
            Button(String(localized: "reset_button")) {
                onReset()
            }
            .buttonStyle(.bordered)
            .keyboardShortcut("r", modifiers: .command)

            Spacer()

            Button {
                onAbout()
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.borderless)
            .help(String(localized: "about_help"))
            .accessibilityLabel(String(localized: "about_help"))

            Button(String(localized: "quit_button")) {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.bordered)
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Previews

#Preview("Footer") {
    FooterView(onReset: {}, onAbout: {})
        .padding()
}
