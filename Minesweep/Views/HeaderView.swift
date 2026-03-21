import SwiftUI

struct HeaderView: View {
    let remainingFlags: Int
    let elapsedSeconds: Int
    let gameState: GameState
    let onReset: () -> Void

    var body: some View {
        HStack {
            counterLabel(value: remainingFlags)
            Spacer()
            resetButton
            Spacer()
            counterLabel(value: elapsedSeconds)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func counterLabel(value: Int) -> some View {
        Text(String(format: "%03d", max(0, value)))
            .font(.system(size: 24, weight: .bold, design: .monospaced))
            .foregroundStyle(.red)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(.black)
            )
    }

    private var resetButton: some View {
        Button(action: onReset) {
            Text(faceEmoji)
                .font(.system(size: 32))
        }
    }

    private var faceEmoji: String {
        switch gameState {
        case .idle, .playing: "🙂"
        case .won: "😎"
        case .lost: "😵"
        }
    }
}
