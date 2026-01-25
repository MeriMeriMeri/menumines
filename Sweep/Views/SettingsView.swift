import SwiftUI

struct SettingsView: View {
    @AppStorage(Constants.SettingsKeys.showMenuBarIndicators) private var showMenuBarIndicators = true
    @AppStorage(Constants.SettingsKeys.confirmBeforeReset) private var confirmBeforeReset = false
    @AppStorage(Constants.SettingsKeys.allowRefreshAfterCompletion) private var allowRefreshAfterCompletion = false

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

            Section {
                Toggle(
                    String(localized: "settings_allow_refresh_after_completion"),
                    isOn: $allowRefreshAfterCompletion
                )
            } footer: {
                Text(String(localized: "settings_allow_refresh_after_completion_footer"))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        // Fixed frame for initial release. Adjust when adding more settings (currently 3 settings).
        .frame(width: 350, height: 290)
    }
}

#Preview {
    SettingsView()
}
