import ServiceManagement
import SwiftUI

struct SettingsView: View {
    enum Layout {
        static let width: CGFloat = 420
        static let height: CGFloat = 480
    }

    @AppStorage(Constants.SettingsKeys.showMenuBarIndicators) private var showMenuBarIndicators = true
    @AppStorage(Constants.SettingsKeys.confirmBeforeReset) private var confirmBeforeReset = false
    @AppStorage(Constants.SettingsKeys.continuousPlay) private var continuousPlay = true
    @AppStorage(Constants.SettingsKeys.showStreaks) private var showStreaks = true

    private var launchAtLogin: Binding<Bool> {
        Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { newValue in
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    print("Launch at login failed: \(error)")
                }
            }
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle(isOn: launchAtLogin) {
                    Text(String(localized: "settings_launch_at_login"))
                    Text(String(localized: "settings_launch_at_login_footer"))
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Toggle(isOn: $showMenuBarIndicators) {
                    Text(String(localized: "settings_show_menu_bar_indicators"))
                    Text(String(localized: "settings_show_menu_bar_indicators_footer"))
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Toggle(isOn: $showStreaks) {
                    Text(String(localized: "settings_show_streaks"))
                    Text(String(localized: "settings_show_streaks_footer"))
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Toggle(isOn: $confirmBeforeReset) {
                    Text(String(localized: "settings_confirm_before_reset"))
                    Text(String(localized: "settings_confirm_before_reset_footer"))
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Toggle(isOn: $continuousPlay) {
                    Text(String(localized: "settings_continuous_play"))
                    Text(String(localized: "settings_continuous_play_footer"))
                        .foregroundStyle(.secondary)
                }
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
