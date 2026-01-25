import SwiftUI

struct MenuContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Sweep")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Coming soon...")
                .foregroundStyle(.secondary)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding()
        .frame(width: 280, height: 320)
    }
}

#Preview {
    MenuContentView()
}
