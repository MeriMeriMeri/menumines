import SwiftUI

/// UserDefaults key for the menu bar status indicators setting.
let showMenuBarIndicatorsKey = "com.sweep.showMenuBarIndicators"

struct SettingsView: View {
    @AppStorage(showMenuBarIndicatorsKey) private var showMenuBarIndicators = true

    var body: some View {
        Form {
            Section {
                Toggle(
                    String(localized: "settings_show_menubar_indicators"),
                    isOn: $showMenuBarIndicators
                )
            } footer: {
                Text(String(localized: "settings_show_menubar_indicators_footer"))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 150)
    }
}

#Preview {
    SettingsView()
}
