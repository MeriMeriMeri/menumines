import SwiftUI

struct FooterView: View {
    let onReset: () -> Void

    var body: some View {
        HStack {
            Button("Reset") {
                onReset()
            }
            .buttonStyle(.bordered)

            Spacer()

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
    FooterView(onReset: {})
        .padding()
}
