import SwiftUI

/// Window for displaying game statistics.
struct StatsWindow: View {
    @State private var showResetConfirmation = false

    private var store: StatsStore {
        StatsStore.shared
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            Divider()

            if store.hasResults {
                metricsSection
            } else {
                emptyStateSection
            }

            Divider()
            footerSection
        }
        .frame(width: 380)
        .fixedSize()
        .alert(String(localized: "stats_reset_confirmation_title"), isPresented: $showResetConfirmation) {
            Button(String(localized: "stats_reset_confirmation_cancel"), role: .cancel) {}
            Button(String(localized: "stats_reset_confirmation_confirm"), role: .destructive) {
                store.reset()
            }
        } message: {
            Text(String(localized: "stats_reset_confirmation_message"))
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "stats_title"))
                .font(.title2)
                .fontWeight(.semibold)
            Text(String(localized: "stats_subtitle"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: - Metrics

    private var metricsSection: some View {
        VStack(spacing: 12) {
            metricRow(label: String(localized: "stats_games_played"), value: "\(store.gamesPlayed)")
            metricRow(label: String(localized: "stats_wins"), value: "\(store.wins)")
            metricRow(label: String(localized: "stats_win_rate"), value: formattedWinRate)
            metricRow(label: String(localized: "stats_best_time"), value: formattedBestTime)
            metricRow(label: String(localized: "stats_avg_time"), value: formattedAverageTime)
        }
        .padding()
    }

    private func metricRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var formattedWinRate: String {
        guard let rate = store.winRate else { return "—" }
        return "\(rate)%"
    }

    private var formattedBestTime: String {
        guard let time = store.bestTime else { return "—" }
        return formatTime(time)
    }

    private var formattedAverageTime: String {
        guard let time = store.averageTime else { return "—" }
        return formatTime(time)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    // MARK: - Empty State

    private var emptyStateSection: some View {
        VStack(spacing: 8) {
            Text(String(localized: "stats_empty_message"))
                .font(.headline)
            Text(String(localized: "stats_empty_subtitle"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let trackedSince = store.trackedSince {
                Text(String(format: String(localized: "stats_tracked_since"), formattedDate(trackedSince)))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Button(String(localized: "stats_reset_button")) {
                showResetConfirmation = true
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .font(.caption)
            .accessibilityHint("Permanently deletes all game statistics")
        }
        .padding()
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Previews

#Preview("Stats - Empty") {
    StatsWindow()
}
