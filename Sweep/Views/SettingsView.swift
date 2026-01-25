import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Text("Settings coming soon...")
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 150)
    }
}

#Preview {
    SettingsView()
}
