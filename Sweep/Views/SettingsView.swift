import SwiftUI

struct SettingsView: View {
    enum Layout {
        static let width: CGFloat = 350
        static let height: CGFloat = 480
    }

    @AppStorage(Constants.SettingsKeys.showMenuBarIndicators) private var showMenuBarIndicators = true
    @AppStorage(Constants.SettingsKeys.confirmBeforeReset) private var confirmBeforeReset = false
    @AppStorage(Constants.SettingsKeys.allowRefreshAfterCompletion) private var allowRefreshAfterCompletion = false
    @AppStorage(Constants.SettingsKeys.showStreaks) private var showStreaks = true

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
                    String(localized: "settings_show_streaks"),
                    isOn: $showStreaks
                )
            } footer: {
                Text(String(localized: "settings_show_streaks_footer"))
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
        .frame(width: Layout.width, height: Layout.height)
    }
}

#Preview {
    SettingsView()
}
