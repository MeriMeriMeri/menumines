import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Text(String(localized: "settings_coming_soon"))
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 150)
    }
}

#Preview {
    SettingsView()
}
