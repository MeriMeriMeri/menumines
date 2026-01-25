import SwiftUI

struct FooterView: View {
    let onReset: () -> Void
    let onAbout: () -> Void

    var body: some View {
        HStack {
            Button("Reset") {
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
            .accessibilityLabel("About Sweep")
            .help("About Sweep")

            Button("Quit") {
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
