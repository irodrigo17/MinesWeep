import SwiftUI

struct CellView: View {
    let cell: Cell
    let gameState: GameState
    let size: CGFloat
    var isHinted: Bool = false

    private static let numberColors: [Int: Color] = [
        1: .blue,
        2: Color(.systemGreen),
        3: .red,
        4: .purple,
        5: .orange,
        6: .teal,
        7: Color(.label),
        8: Color(.secondaryLabel),
    ]

    var body: some View {
        ZStack {
            switch cell.state {
            case .hidden:
                hiddenCell
                    .transition(.identity)
            case .flagged:
                flaggedCell
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            case .revealed:
                revealedCell
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.15), value: cell.state)
        .frame(width: size, height: size)
        .overlay {
            if isHinted {
                ShimmerOverlay(size: size)
            }
        }
    }

    private var hiddenCell: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(.systemGray4))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(Color(.systemGray3), lineWidth: 1)
            )
    }

    private var flaggedCell: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(.systemGray4))
            .overlay(
                Image(systemName: "flag.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(.red)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(Color(.systemGray3), lineWidth: 1)
            )
    }

    @ViewBuilder
    private var revealedCell: some View {
        if cell.isMine {
            mineCell
        } else if cell.adjacentMines > 0 {
            numberCell
        } else {
            emptyCell
        }
    }

    private var mineCell: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.red.opacity(0.3))
            .overlay(
                Image(systemName: "circle.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(.primary)
            )
    }

    private var numberCell: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(.systemGray6))
            .overlay(
                Text("\(cell.adjacentMines)")
                    .font(.system(size: size * 0.55, weight: .bold, design: .rounded))
                    .foregroundStyle(Self.numberColors[cell.adjacentMines, default: .black])
            )
    }

    private var emptyCell: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(.systemGray6))
    }
}

struct ShimmerOverlay: View {
    let size: CGFloat
    @State private var phase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.6),
                        .white.opacity(0.8),
                        .white.opacity(0.6),
                        .clear,
                    ],
                    startPoint: UnitPoint(x: phase - 0.3, y: phase - 0.3),
                    endPoint: UnitPoint(x: phase + 0.3, y: phase + 0.3)
                )
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    phase = 1.3
                }
            }
    }
}
