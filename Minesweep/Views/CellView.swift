import SwiftUI

struct CellView: View {
    let cell: Cell
    let gameState: GameState
    let size: CGFloat

    private static let numberColors: [Int: Color] = [
        1: .blue,
        2: Color(red: 0, green: 0.5, blue: 0),
        3: .red,
        4: Color(red: 0, green: 0, blue: 0.5),
        5: Color(red: 0.5, green: 0, blue: 0),
        6: .teal,
        7: .black,
        8: .gray,
    ]

    var body: some View {
        ZStack {
            switch cell.state {
            case .hidden:
                hiddenCell
            case .flagged:
                flaggedCell
            case .revealed:
                revealedCell
            }
        }
        .frame(width: size, height: size)
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
                    .foregroundStyle(.black)
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
