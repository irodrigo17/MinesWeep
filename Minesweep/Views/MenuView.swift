import SwiftUI

struct MenuView: View {
    let onSelectDifficulty: (Difficulty) -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Minesweeper")
                .font(.largeTitle.bold())

            Text("💣")
                .font(.system(size: 80))

            VStack(spacing: 16) {
                ForEach(Difficulty.allCases) { difficulty in
                    Button {
                        onSelectDifficulty(difficulty)
                    } label: {
                        VStack(spacing: 4) {
                            Text(difficulty.displayName)
                                .font(.title2.bold())
                            Text("\(difficulty.rows) × \(difficulty.columns) — \(difficulty.mineCount) mines")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }
}
