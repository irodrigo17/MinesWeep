import XCTest
@testable import Minesweep

/// Mock StatsRecorder for verifying ViewModel stats integration
final class MockStatsRecorder: StatsRecording {
    var wins: [(difficulty: Difficulty, time: Int)] = []
    var losses: [Difficulty] = []

    func recordWin(difficulty: Difficulty, time: Int) {
        wins.append((difficulty: difficulty, time: time))
    }

    func recordLoss(difficulty: Difficulty) {
        losses.append(difficulty)
    }
}

final class StatsStoreTests: XCTestCase {

    // MARK: - StatsRecording Protocol via Mock

    func testRecordWinViaProtocol() {
        let mock = MockStatsRecorder()
        mock.recordWin(difficulty: .beginner, time: 42)
        XCTAssertEqual(mock.wins.count, 1)
        XCTAssertEqual(mock.wins.first?.difficulty, .beginner)
        XCTAssertEqual(mock.wins.first?.time, 42)
    }

    func testRecordLossViaProtocol() {
        let mock = MockStatsRecorder()
        mock.recordLoss(difficulty: .expert)
        XCTAssertEqual(mock.losses.count, 1)
        XCTAssertEqual(mock.losses.first, .expert)
    }

    // MARK: - ViewModel Stats Integration

    func testViewModelRecordsWinToInjectedRecorder() {
        let mock = MockStatsRecorder()
        let cells: [[Cell]] = [
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(isMine: true)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(adjacentMines: 1)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 0), Cell(adjacentMines: 0)],
        ]
        let vm = GameViewModel(difficulty: .beginner, statsRecorder: mock)
        vm.board = Board(cells: cells, mineCount: 1)
        // Flood fill from (0,0) wins the game
        vm.revealCell(row: 0, col: 0)
        XCTAssertEqual(vm.gameState, .won)
        XCTAssertEqual(mock.wins.count, 1)
        XCTAssertEqual(mock.wins.first?.difficulty, .beginner)
        XCTAssertEqual(mock.losses.count, 0)
    }

    func testViewModelRecordsLossToInjectedRecorder() {
        let mock = MockStatsRecorder()
        let cells: [[Cell]] = [
            [Cell(adjacentMines: 0), Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(isMine: true)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(adjacentMines: 1)],
            [Cell(adjacentMines: 1), Cell(adjacentMines: 1), Cell(adjacentMines: 0), Cell(adjacentMines: 0)],
            [Cell(isMine: true), Cell(adjacentMines: 1), Cell(adjacentMines: 0), Cell(adjacentMines: 0)],
        ]
        let vm = GameViewModel(difficulty: .intermediate, statsRecorder: mock)
        vm.board = Board(cells: cells, mineCount: 2)
        vm.revealCell(row: 0, col: 2) // numbered cell, starts playing
        vm.revealCell(row: 0, col: 3) // hit mine
        XCTAssertEqual(vm.gameState, .lost)
        XCTAssertEqual(mock.losses.count, 1)
        XCTAssertEqual(mock.losses.first, .intermediate)
        XCTAssertEqual(mock.wins.count, 0)
    }

    func testViewModelDoesNotRecordStatsOnSafeReveal() {
        let mock = MockStatsRecorder()
        let cells: [[Cell]] = [
            [Cell(adjacentMines: 0), Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(isMine: true)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(adjacentMines: 1)],
            [Cell(adjacentMines: 1), Cell(adjacentMines: 1), Cell(adjacentMines: 0), Cell(adjacentMines: 0)],
            [Cell(isMine: true), Cell(adjacentMines: 1), Cell(adjacentMines: 0), Cell(adjacentMines: 0)],
        ]
        let vm = GameViewModel(difficulty: .beginner, statsRecorder: mock)
        vm.board = Board(cells: cells, mineCount: 2)
        vm.revealCell(row: 0, col: 2) // safe numbered cell
        XCTAssertEqual(vm.gameState, .playing)
        XCTAssertEqual(mock.wins.count, 0)
        XCTAssertEqual(mock.losses.count, 0)
    }

    func testViewModelRecordsCorrectDifficultyOnWin() {
        let mock = MockStatsRecorder()
        let cells: [[Cell]] = [
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(isMine: true)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(adjacentMines: 1)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 0), Cell(adjacentMines: 0)],
        ]
        let vm = GameViewModel(difficulty: .expert, statsRecorder: mock)
        vm.board = Board(cells: cells, mineCount: 1)
        vm.revealCell(row: 0, col: 0) // flood fill wins
        XCTAssertEqual(mock.wins.first?.difficulty, .expert)
    }
}
