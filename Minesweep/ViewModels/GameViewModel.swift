import Foundation
import SwiftUI

class GameViewModel: ObservableObject {
    @Published private(set) var board: Board
    @Published private(set) var gameState: GameState = .idle
    @Published private(set) var difficulty: Difficulty
    @Published private(set) var elapsedSeconds: Int = 0
    private var startDate: Date?
    private var timer: Timer?

    var remainingFlags: Int { board.remainingFlags }
    var cells: [[Cell]] { board.cells }
    var rows: Int { board.rows }
    var columns: Int { board.columns }

    init(difficulty: Difficulty = .beginner) {
        self.difficulty = difficulty
        self.board = Board(difficulty: difficulty)
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
            StatsStore.shared.recordLoss(difficulty: difficulty)
        case .won:
            gameState = .won
            stopTimer()
            StatsStore.shared.recordWin(difficulty: difficulty, time: elapsedSeconds)
        case .safe, .noAction:
            break
        }
    }
}
