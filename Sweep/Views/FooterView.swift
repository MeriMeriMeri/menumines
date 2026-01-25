import SwiftUI

struct FooterView: View {
    @Environment(\.openSettings) private var openSettings

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

            Menu {
                Button("About Sweep") {
                    onAbout()
                }

                Button("Settings...") {
                    openSettings()
                }
                .keyboardShortcut(",", modifiers: .command)

                Divider()

                Button("Quit Sweep") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            } label: {
                Image(systemName: "gearshape")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Previews

#Preview("Footer") {
    FooterView(onReset: {}, onAbout: {})
        .padding()
}
