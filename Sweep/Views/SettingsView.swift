import SwiftUI

struct SettingsView: View {
    @AppStorage(Constants.SettingsKeys.showMenuBarIndicators) private var showMenuBarIndicators = true
    @AppStorage(Constants.SettingsKeys.confirmBeforeReset) private var confirmBeforeReset = false

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

            Section {
                Toggle(
                    String(localized: "settings_confirm_before_reset"),
                    isOn: $confirmBeforeReset
                )
            } footer: {
                Text(String(localized: "settings_confirm_before_reset_footer"))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 220)
    }
}

#Preview {
    SettingsView()
}
