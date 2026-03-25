import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    let onMenu: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HeaderView(
                    remainingFlags: viewModel.remainingFlags,
                    elapsedSeconds: viewModel.elapsedSeconds,
                    gameState: viewModel.gameState,
                    onReset: { viewModel.newGame() }
                )

                Divider()

                Spacer()

                gridView(availableWidth: geometry.size.width)
                    .padding(8)

                Spacer()

                Divider()

                bottomBar
            }
        }
        .onShake {
            viewModel.showHint()
        }
        .overlay {
            if viewModel.gameState == .won || viewModel.gameState == .lost {
                GameOverView(
                    gameState: viewModel.gameState,
                    elapsedSeconds: viewModel.elapsedSeconds,
                    onPlayAgain: { viewModel.newGame() },
                    onMenu: onMenu
                )
            }
        }
    }

    private func gridView(availableWidth: CGFloat) -> some View {
        let size = cellSize(for: availableWidth)
        return VStack(spacing: 2) {
            ForEach(0..<viewModel.rows, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<viewModel.columns, id: \.self) { col in
                        CellView(
                            cell: viewModel.cells[row][col],
                            gameState: viewModel.gameState,
                            size: size,
                            isHinted: viewModel.hintCell?.row == row && viewModel.hintCell?.col == col
                        )
                        .onTapGesture {
                            viewModel.tapCell(row: row, col: col)
                        }
                        .onLongPressGesture(minimumDuration: 0.15) {
                            handleLongPress(row: row, col: col)
                        }
                        .accessibilityLabel(accessibilityLabel(row: row, col: col))
                        .accessibilityHint(accessibilityHint(row: row, col: col))
                        .accessibilityAddTraits(viewModel.cells[row][col].isRevealed ? [] : .isButton)
                        .accessibilityAction(named: "Toggle Flag") {
                            handleLongPress(row: row, col: col)
                        }
                    }
                }
            }
        }
    }

    private func cellSize(for availableWidth: CGFloat) -> CGFloat {
        let gridWidth = availableWidth - 16
        let maxSize: CGFloat = 44
        let calculated = (gridWidth - CGFloat(viewModel.columns - 1) * 2) / CGFloat(viewModel.columns)
        return min(maxSize, max(24, calculated))
    }


    private var bottomBar: some View {
        HStack {
            Button("Menu", action: onMenu)
                .font(.subheadline)
            Spacer()
            Text(viewModel.difficulty.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Interaction

    private func handleLongPress(row: Int, col: Int) {
        viewModel.toggleFlag(row: row, col: col)
        HapticManager.impact(.medium)
    }

    // MARK: - Accessibility

    private func accessibilityLabel(row: Int, col: Int) -> String {
        let cell = viewModel.cells[row][col]
        let position = "Row \(row + 1), Column \(col + 1)"
        switch cell.state {
        case .hidden: return "\(position), hidden"
        case .flagged: return "\(position), flagged"
        case .revealed:
            if cell.isMine { return "\(position), mine" }
            if cell.adjacentMines > 0 { return "\(position), \(cell.adjacentMines) adjacent mines" }
            return "\(position), empty"
        }
    }

    private func accessibilityHint(row: Int, col: Int) -> String {
        let cell = viewModel.cells[row][col]
        switch cell.state {
        case .hidden: return "Double tap to reveal, long press to flag"
        case .flagged: return "Long press to remove flag"
        case .revealed: return ""
        }
    }
}
