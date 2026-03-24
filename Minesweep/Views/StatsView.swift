import SwiftUI

struct StatsView: View {
    @ObservedObject var statsStore: StatsStore = .shared
    @State private var selectedDifficulty: Difficulty = .beginner

    var body: some View {
        VStack(spacing: 24) {
            Text("Statistics")
                .font(.largeTitle.bold())

            Picker("Difficulty", selection: $selectedDifficulty) {
                ForEach(Difficulty.allCases) { difficulty in
                    Text(difficulty.displayName).tag(difficulty)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            let stats = statsStore.stats(for: selectedDifficulty)

            VStack(spacing: 16) {
                statRow(label: "Games Played", value: "\(stats.gamesPlayed)")
                statRow(label: "Wins", value: "\(stats.wins)")
                statRow(label: "Losses", value: "\(stats.losses)")
                statRow(label: "Win Rate", value: formatPercent(stats.winRate))
                statRow(label: "Best Time", value: formatTime(stats.bestTime))
                statRow(label: "Avg Win Time", value: formatTime(stats.averageWinTime))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.body.monospacedDigit().bold())
        }
    }

    private func formatTime(_ seconds: Int?) -> String {
        guard let seconds else { return "—" }
        return "\(seconds)s"
    }

    private func formatPercent(_ value: Double) -> String {
        String(format: "%.0f%%", value * 100)
    }
}
