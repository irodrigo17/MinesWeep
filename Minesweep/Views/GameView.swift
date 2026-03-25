import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    let onMenu: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(
                remainingFlags: viewModel.remainingFlags,
                elapsedSeconds: viewModel.elapsedSeconds,
                gameState: viewModel.gameState,
                onReset: { viewModel.newGame() }
            )

            Divider()

            Spacer()

            gridView
                .padding(8)

            Spacer()

            Divider()

            bottomBar
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

    private var gridView: some View {
        let size = cellSize
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
                            handleTap(row: row, col: col)
                        }
                        .onLongPressGesture(minimumDuration: 0.15) {
                            handleLongPress(row: row, col: col)
                        }
                        .accessibilityLabel(accessibilityLabel(row: row, col: col))
                        .accessibilityHint(accessibilityHint(row: row, col: col))
                    }
                }
            }
        }
    }

    private var cellSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 32
        let maxSize: CGFloat = 44
        let calculated = (screenWidth - CGFloat(viewModel.columns - 1) * 2) / CGFloat(viewModel.columns)
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

    private func handleTap(row: Int, col: Int) {
        let cell = viewModel.cells[row][col]
        if cell.isRevealed && cell.adjacentMines > 0 {
            viewModel.chordCell(row: row, col: col)
        } else {
            viewModel.revealCell(row: row, col: col)
        }
    }

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
