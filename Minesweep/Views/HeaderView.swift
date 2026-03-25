import SwiftUI

struct HeaderView: View {
    let remainingFlags: Int
    let elapsedSeconds: Int
    let gameState: GameState
    @Binding var flagMode: Bool
    let onReset: () -> Void

    var body: some View {
        HStack {
            counterLabel(value: remainingFlags)
            Spacer()
            flagToggle
            Spacer()
            resetButton
            Spacer()
            counterLabel(value: elapsedSeconds)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var flagToggle: some View {
        Button {
            flagMode.toggle()
        } label: {
            Image(systemName: flagMode ? "flag.fill" : "flag")
                .font(.system(size: 22))
                .foregroundStyle(flagMode ? .red : .secondary)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(flagMode ? Color.red.opacity(0.15) : Color(.systemGray5))
                )
        }
        .accessibilityIdentifier("flagToggle")
        .accessibilityLabel(flagMode ? "Flag mode on" : "Flag mode off")
        .accessibilityHint("Double tap to toggle flag mode")
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
        .accessibilityIdentifier("resetButton")
    }

    private var faceEmoji: String {
        switch gameState {
        case .idle, .playing: "🙂"
        case .won: "😎"
        case .lost: "😵"
        }
    }
}
