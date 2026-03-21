import SwiftUI

struct GameOverView: View {
    let gameState: GameState
    let elapsedSeconds: Int
    let onPlayAgain: () -> Void
    let onMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text(gameState == .won ? "You Win!" : "Game Over")
                    .font(.largeTitle.bold())
                    .foregroundStyle(gameState == .won ? .green : .red)

                Text(gameState == .won ? "😎" : "💥")
                    .font(.system(size: 60))

                if gameState == .won {
                    Text("Time: \(elapsedSeconds)s")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    Button("Play Again", action: onPlayAgain)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accentColor)
                        )
                        .foregroundStyle(.white)

                    Button("Menu", action: onMenu)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 40)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
            )
            .padding(40)
        }
    }
}
