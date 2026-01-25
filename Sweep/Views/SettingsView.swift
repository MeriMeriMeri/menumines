import SwiftUI

struct SettingsView: View {
    @AppStorage(Constants.SettingsKeys.showMenuBarIndicators) private var showMenuBarIndicators = true

    var body: some View {
        Form {
            Section {
                Toggle(
                    String(localized: "settings_show_menu_bar_indicators"),
                    isOn: $showMenuBarIndicators
                )
            } footer: {
                Text(String(localized: "settings_show_menu_bar_indicators_footer"))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        // Fixed frame for initial release. Will need adjustment when adding more settings.
        .frame(width: 350, height: 150)
    }
}

#Preview {
    SettingsView()
}
