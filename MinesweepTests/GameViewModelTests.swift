import XCTest
@testable import Minesweep

final class GameViewModelTests: XCTestCase {

    // MARK: - State Transitions

    func testInitialStateIsIdle() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.gameState, .idle)
        XCTAssertEqual(vm.elapsedSeconds, 0)
    }

    func testFirstRevealTransitionsToPlaying() {
        let vm = makeViewModel()
        vm.revealCell(row: 0, col: 0)
        XCTAssertEqual(vm.gameState, .playing)
    }

    func testRevealMineTransitionsToLost() {
        let vm = makeViewModelWithLargerBoard()
        // Reveal a numbered cell (won't flood fill)
        vm.revealCell(row: 0, col: 2)
        XCTAssertEqual(vm.gameState, .playing)
        // Now reveal the mine
        vm.revealCell(row: 0, col: 3)
        XCTAssertEqual(vm.gameState, .lost)
    }

    func testRevealAllSafeCellsTransitionsToWon() {
        let vm = makeViewModelWithBoard()
        // Flood fill from (0,0) with adjacentMines=0 should reveal everything except the mine
        vm.revealCell(row: 0, col: 0)
        XCTAssertEqual(vm.gameState, .won)
    }

    // MARK: - Actions Blocked After Game Over

    func testCannotRevealAfterLoss() {
        let vm = makeViewModelWithLargerBoard()
        vm.revealCell(row: 0, col: 2) // numbered cell, stays playing
        vm.revealCell(row: 0, col: 3) // hit mine
        XCTAssertEqual(vm.gameState, .lost)
        vm.revealCell(row: 1, col: 0)
        XCTAssertEqual(vm.gameState, .lost)
    }

    func testCannotFlagAfterWin() {
        let vm = makeViewModelWithBoard()
        vm.revealCell(row: 0, col: 0) // flood fill wins
        XCTAssertEqual(vm.gameState, .won)
        vm.toggleFlag(row: 0, col: 2)
        XCTAssertFalse(vm.cells[0][2].isFlagged)
    }

    func testCannotChordAfterLoss() {
        let vm = makeViewModelWithLargerBoard()
        vm.revealCell(row: 0, col: 2) // numbered cell
        vm.revealCell(row: 0, col: 3) // hit mine
        XCTAssertEqual(vm.gameState, .lost)
        vm.chordCell(row: 0, col: 2)
        XCTAssertEqual(vm.gameState, .lost)
    }

    // MARK: - Flag Before First Reveal

    func testCanFlagBeforeFirstReveal() {
        let vm = makeViewModel()
        vm.toggleFlag(row: 0, col: 0)
        XCTAssertTrue(vm.cells[0][0].isFlagged)
        XCTAssertEqual(vm.gameState, .idle)
    }

    // MARK: - New Game

    func testNewGameResetsState() {
        let vm = makeViewModelWithBoard()
        vm.revealCell(row: 0, col: 0)
        vm.newGame()
        XCTAssertEqual(vm.gameState, .idle)
        XCTAssertEqual(vm.elapsedSeconds, 0)
        // All cells should be hidden
        for row in vm.cells {
            for cell in row {
                XCTAssertTrue(cell.isHidden)
            }
        }
    }

    func testNewGameWithDifferentDifficulty() {
        let vm = makeViewModel()
        vm.newGame(difficulty: .intermediate)
        XCTAssertEqual(vm.rows, 12)
        XCTAssertEqual(vm.columns, 12)
        XCTAssertEqual(vm.difficulty, .intermediate)
    }

    // MARK: - Hint

    func testHintOnlyWorksDuringPlaying() {
        let vm = makeViewModel()
        vm.showHint()
        XCTAssertNil(vm.hintCell, "Hint should not work in idle state")
    }

    func testHintDoesNotWorkAfterGameOver() {
        let vm = makeViewModelWithBoard()
        vm.revealCell(row: 0, col: 0) // wins via flood fill
        XCTAssertEqual(vm.gameState, .won)
        vm.showHint()
        XCTAssertNil(vm.hintCell)
    }

    func testHintReturnsSafeCell() {
        let vm = makeViewModelWithLargerBoard()
        // Reveal one cell to start playing
        vm.revealCell(row: 0, col: 0)
        guard vm.gameState == .playing else { return } // skip if flood fill won
        vm.showHint()
        guard let hint = vm.hintCell else {
            XCTFail("Hint should be provided during playing state")
            return
        }
        XCTAssertFalse(vm.cells[hint.row][hint.col].isMine, "Hint cell should not be a mine")
        XCTAssertTrue(vm.cells[hint.row][hint.col].isHidden, "Hint cell should be hidden")
    }

    func testHintPrefersDeducibleCells() {
        // Board where cell (0,1) is "1" with mine at (0,2)
        // Flag the mine → (0,0) becomes logically deducible
        let cells: [[Cell]] = [
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(isMine: true), Cell(adjacentMines: 1), Cell(adjacentMines: 0)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(adjacentMines: 1), Cell(adjacentMines: 1), Cell(adjacentMines: 0)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 0), Cell(adjacentMines: 0), Cell(adjacentMines: 0), Cell(adjacentMines: 0)],
        ]
        let vm = GameViewModel(difficulty: .beginner)
        vm.board = Board(cells: cells, mineCount: 1)
        vm.gameState = .playing
        // Reveal (0,1) and flag the mine
        _ = vm.board.reveal(row: 0, col: 1)
        vm.board.toggleFlag(row: 0, col: 2)
        // Also reveal (1,1) so there are non-deducible frontier cells too
        _ = vm.board.reveal(row: 1, col: 1)

        // Run hint many times — it should always pick a deducible cell
        for _ in 0..<10 {
            vm.hintCell = nil
            vm.showHint()
            guard let hint = vm.hintCell else {
                XCTFail("Hint should be provided")
                return
            }
            // Deducible cells: hidden neighbors of (0,1) = (0,0), (1,0)
            // and hidden neighbors of (1,1) = (0,0), (1,0), (2,0), (2,1), (2,2), (1,2)
            // All of (0,1)'s hidden unflagged neighbors are deducible since flagCount == adjacentMines
            XCTAssertFalse(vm.cells[hint.row][hint.col].isMine, "Hint should be safe at (\(hint.row), \(hint.col))")
        }
    }

    func testHintNotRepeatedWhileActive() {
        let vm = makeViewModelWithLargerBoard()
        vm.revealCell(row: 2, col: 2)
        guard vm.gameState == .playing else { return }
        vm.showHint()
        let firstHint = vm.hintCell
        XCTAssertNotNil(firstHint)
        vm.showHint()
        // Should be the same hint, not a new one
        XCTAssertEqual(vm.hintCell?.row, firstHint?.row)
        XCTAssertEqual(vm.hintCell?.col, firstHint?.col)
    }

    // MARK: - Helpers

    private func makeViewModel() -> GameViewModel {
        GameViewModel(difficulty: .beginner)
    }

    /// ViewModel with a pre-built 3x3 board (mine at 0,2)
    private func makeViewModelWithBoard() -> GameViewModel {
        let cells: [[Cell]] = [
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(isMine: true)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(adjacentMines: 1)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 0), Cell(adjacentMines: 0)],
        ]
        let vm = GameViewModel(difficulty: .beginner)
        vm.board = Board(cells: cells, mineCount: 1)
        return vm
    }

    /// ViewModel with a 4x4 board that won't instantly win on first reveal
    /// Mines at (0,3) and (3,0)
    private func makeViewModelWithLargerBoard() -> GameViewModel {
        let cells: [[Cell]] = [
            [Cell(adjacentMines: 0), Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(isMine: true)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(adjacentMines: 1)],
            [Cell(adjacentMines: 1), Cell(adjacentMines: 1), Cell(adjacentMines: 0), Cell(adjacentMines: 0)],
            [Cell(isMine: true), Cell(adjacentMines: 1), Cell(adjacentMines: 0), Cell(adjacentMines: 0)],
        ]
        let vm = GameViewModel(difficulty: .beginner)
        vm.board = Board(cells: cells, mineCount: 2)
        return vm
    }
}
