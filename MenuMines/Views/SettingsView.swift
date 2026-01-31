import SwiftUI

struct SettingsView: View {
    enum Layout {
        static let width: CGFloat = 350
        static let height: CGFloat = 480
    }

    @AppStorage(Constants.SettingsKeys.showMenuBarIndicators) private var showMenuBarIndicators = true
    @AppStorage(Constants.SettingsKeys.confirmBeforeReset) private var confirmBeforeReset = false
    @AppStorage(Constants.SettingsKeys.continuousPlay) private var continuousPlay = true
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
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section {
                Toggle(
                    String(localized: "settings_show_streaks"),
                    isOn: $showStreaks
                )
            } footer: {
                Text(String(localized: "settings_show_streaks_footer"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section {
                Toggle(
                    String(localized: "settings_confirm_before_reset"),
                    isOn: $confirmBeforeReset
                )
            } footer: {
                Text(String(localized: "settings_confirm_before_reset_footer"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section {
                Toggle(
                    String(localized: "settings_continuous_play"),
                    isOn: $continuousPlay
                )
            } footer: {
                Text(String(localized: "settings_continuous_play_footer"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            #if SPARKLE_ENABLED
            Section {
                Toggle(
                    String(localized: "settings_auto_check_updates"),
                    isOn: Binding(
                        get: { UpdateManager.automaticallyChecksForUpdates },
                        set: { UpdateManager.automaticallyChecksForUpdates = $0 }
                    )
                )

                Button(String(localized: "check_for_updates_button")) {
                    UpdateManager.checkForUpdates()
                }
                .disabled(!UpdateManager.canCheckForUpdates)
            } header: {
                Text(String(localized: "settings_updates_section"))
            }
            #endif
        }
        .formStyle(.grouped)
        .frame(width: Layout.width, height: Layout.height)
    }
}

#Preview {
    SettingsView()
}
