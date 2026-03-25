import Foundation
import SwiftUI

class GameViewModel: ObservableObject {
    @Published var board: Board
    @Published var gameState: GameState = .idle
    @Published private(set) var difficulty: Difficulty
    @Published private(set) var elapsedSeconds: Int = 0
    @Published var hintCell: (row: Int, col: Int)?
    private var startDate: Date?
    private var timer: Timer?
    private var hintTimer: Timer?

    var remainingFlags: Int { board.remainingFlags }
    var cells: [[Cell]] { board.cells }
    var rows: Int { board.rows }
    var columns: Int { board.columns }

    init(difficulty: Difficulty = .beginner) {
        self.difficulty = difficulty
        self.board = Board(difficulty: difficulty)
    }

    deinit {
        timer?.invalidate()
        hintTimer?.invalidate()
    }

    // MARK: - Actions

    func revealCell(row: Int, col: Int) {
        guard gameState == .idle || gameState == .playing else { return }

        if gameState == .idle {
            board.placeMines(excludingRow: row, excludingColumn: col)
            gameState = .playing
            startTimer()
        }

        let result = board.reveal(row: row, col: col)
        handleResult(result)
    }

    func toggleFlag(row: Int, col: Int) {
        guard gameState == .idle || gameState == .playing else { return }
        board.toggleFlag(row: row, col: col)
    }

    func chordCell(row: Int, col: Int) {
        guard gameState == .playing else { return }
        let result = board.chord(row: row, col: col)
        handleResult(result)
    }

    func newGame(difficulty: Difficulty? = nil) {
        if let difficulty { self.difficulty = difficulty }
        board = Board(difficulty: self.difficulty)
        gameState = .idle
        elapsedSeconds = 0
        startDate = nil
        stopTimer()
        hintTimer?.invalidate()
        hintTimer = nil
        hintCell = nil
    }

    // MARK: - Hint

    func showHint() {
        guard gameState == .playing else { return }
        guard hintCell == nil else { return }

        // Priority 1: Logically deducible safe cells
        // If a revealed number has all its mines flagged, its remaining hidden neighbors are provably safe
        var deducible = Set<Int>()
        for r in 0..<board.rows {
            for c in 0..<board.columns {
                let cell = board.cells[r][c]
                guard cell.isRevealed && cell.adjacentMines > 0 else { continue }
                let neighbors = board.neighbors(of: r, c)
                let flaggedCount = neighbors.filter { board.cells[$0.0][$0.1].isFlagged }.count
                guard flaggedCount == cell.adjacentMines else { continue }
                for (nr, nc) in neighbors {
                    if board.cells[nr][nc].isHidden {
                        deducible.insert(nr * board.columns + nc)
                    }
                }
            }
        }

        // Priority 2: Border cells (hidden non-mine cells adjacent to revealed cells)
        var frontier = [(Int, Int)]()
        // Priority 3: Any hidden non-mine cell
        var fallback = [(Int, Int)]()

        for r in 0..<board.rows {
            for c in 0..<board.columns {
                let cell = board.cells[r][c]
                guard cell.isHidden && !cell.isMine else { continue }
                let hasRevealedNeighbor = board.neighbors(of: r, c)
                    .contains { board.cells[$0.0][$0.1].isRevealed }
                if hasRevealedNeighbor {
                    frontier.append((r, c))
                } else {
                    fallback.append((r, c))
                }
            }
        }

        let deducibleCells = deducible.map { (row: $0 / board.columns, col: $0 % board.columns) }
        let candidates: [(row: Int, col: Int)]
        if !deducibleCells.isEmpty {
            candidates = deducibleCells
        } else if !frontier.isEmpty {
            candidates = frontier.map { (row: $0.0, col: $0.1) }
        } else {
            candidates = fallback.map { (row: $0.0, col: $0.1) }
        }

        guard let pick = candidates.randomElement() else { return }

        hintCell = (row: pick.row, col: pick.col)
        HapticManager.impact(.light)

        // Clear hint after 2 seconds
        hintTimer?.invalidate()
        hintTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] _ in
            self?.hintCell = nil
        }
    }

    // MARK: - Timer

    private func startTimer() {
        startDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let startDate = self.startDate else { return }
            self.elapsedSeconds = min(999, Int(Date().timeIntervalSince(startDate)))
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Result Handling

    private func handleResult(_ result: RevealResult) {
        switch result {
        case .mine:
            gameState = .lost
            stopTimer()
            hintTimer?.invalidate()
            hintTimer = nil
            hintCell = nil
            HapticManager.notification(.error)
            StatsStore.shared.recordLoss(difficulty: difficulty)
        case .won:
            gameState = .won
            stopTimer()
            hintTimer?.invalidate()
            hintTimer = nil
            hintCell = nil
            HapticManager.notification(.success)
            StatsStore.shared.recordWin(difficulty: difficulty, time: elapsedSeconds)
        case .safe, .noAction:
            break
        }
    }
}
