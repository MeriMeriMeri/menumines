import AppKit
import SwiftUI

@MainActor
enum AboutWindow {
    /// Singleton window controller to maintain About window across show/hide cycles.
    /// Window is kept in memory (isReleasedWhenClosed = false) to preserve state
    /// and avoid repeated allocations. This is intentional for the About window.
    private static var windowController: NSWindowController?

    static func show() {
        if let existingWindow = windowController?.window, existingWindow.isVisible {
            WindowActivation.raise(existingWindow)
            return
        }

        let aboutView = AboutView()
        let hostingController = NSHostingController(rootView: aboutView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = String(localized: "about_menu_item")
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()

        let controller = NSWindowController(window: window)
        windowController = controller
        controller.showWindow(nil)
        // Raised only once the window exists; activating first leaves it behind the app
        // the user was in.
        WindowActivation.raise(window)
    }
}

private struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    private var channel: BuildChannel {
        BuildChannel.current
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 80, height: 80)
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text(String(localized: "about_title"))
                    .font(.title)
                    .fontWeight(.semibold)

                Text(String(format: String(localized: "build_info_version"), appVersion, buildNumber))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(channel.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(channel.isPreRelease ? Color.orange : Color.secondary)
            }

            Text(String(localized: "about_description"))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let supportURL = URL(string: "mailto:support@merimerimeri.com") {
                Link(String(localized: "about_support_email"), destination: supportURL)
                    .font(.caption)
            }

            Text(String(localized: "about_copyright"))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(width: 300)
    }
}

#Preview {
    AboutView()
}
