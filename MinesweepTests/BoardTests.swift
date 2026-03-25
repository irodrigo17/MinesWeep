import XCTest
@testable import Minesweep

// Seeded RNG for deterministic tests
struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

final class BoardTests: XCTestCase {

    // MARK: - Mine Placement

    func testMinePlacementCount() {
        var board = Board(difficulty: .beginner)
        board.placeMines(excludingRow: 0, excludingColumn: 0)
        let mineCount = board.cells.flatMap { $0 }.filter { $0.isMine }.count
        XCTAssertEqual(mineCount, 10)
    }

    func testFirstTapIsSafe() {
        for _ in 0..<20 {
            var board = Board(difficulty: .beginner)
            let row = Int.random(in: 0..<board.rows)
            let col = Int.random(in: 0..<board.columns)
            board.placeMines(excludingRow: row, excludingColumn: col)
            XCTAssertFalse(board.cells[row][col].isMine, "First tap cell should never be a mine")
        }
    }

    func testFirstTapNeighborsAreSafe() {
        for _ in 0..<20 {
            var board = Board(difficulty: .beginner)
            let row = Int.random(in: 0..<board.rows)
            let col = Int.random(in: 0..<board.columns)
            board.placeMines(excludingRow: row, excludingColumn: col)
            for (nr, nc) in board.neighbors(of: row, col) {
                XCTAssertFalse(board.cells[nr][nc].isMine, "Neighbor (\(nr),\(nc)) of first tap should not be a mine")
            }
        }
    }

    func testDeterministicPlacement() {
        var rng1 = SeededRNG(state: 42)
        var rng2 = SeededRNG(state: 42)
        var board1 = Board(difficulty: .beginner)
        var board2 = Board(difficulty: .beginner)
        board1.placeMines(excludingRow: 4, excludingColumn: 4, using: &rng1)
        board2.placeMines(excludingRow: 4, excludingColumn: 4, using: &rng2)
        for r in 0..<board1.rows {
            for c in 0..<board1.columns {
                XCTAssertEqual(board1.cells[r][c].isMine, board2.cells[r][c].isMine)
                XCTAssertEqual(board1.cells[r][c].adjacentMines, board2.cells[r][c].adjacentMines)
            }
        }
    }

    func testAdjacentMineCountsCorrect() {
        var board = Board(difficulty: .beginner)
        var rng = SeededRNG(state: 99)
        board.placeMines(excludingRow: 0, excludingColumn: 0, using: &rng)

        for r in 0..<board.rows {
            for c in 0..<board.columns {
                guard !board.cells[r][c].isMine else { continue }
                let actual = board.neighbors(of: r, c).filter { board.cells[$0.0][$0.1].isMine }.count
                XCTAssertEqual(board.cells[r][c].adjacentMines, actual, "Wrong count at (\(r),\(c))")
            }
        }
    }

    // MARK: - Reveal

    func testRevealSafeCell() {
        var board = makeTestBoard()
        // Reveal a numbered cell (adjacentMines=1) so flood fill doesn't trigger a win
        let result = board.reveal(row: 0, col: 1)
        XCTAssertEqual(result, .safe)
        XCTAssertTrue(board.cells[0][1].isRevealed)
    }

    func testRevealMine() {
        var board = makeTestBoard()
        let result = board.reveal(row: 0, col: 2)
        XCTAssertEqual(result, .mine)
    }

    func testRevealFlaggedCellIsNoAction() {
        var board = makeTestBoard()
        board.toggleFlag(row: 0, col: 0)
        let result = board.reveal(row: 0, col: 0)
        XCTAssertEqual(result, .noAction)
        XCTAssertTrue(board.cells[0][0].isFlagged)
    }

    func testRevealAlreadyRevealedIsNoAction() {
        var board = makeTestBoard()
        _ = board.reveal(row: 0, col: 0)
        let result = board.reveal(row: 0, col: 0)
        XCTAssertEqual(result, .noAction)
    }

    // MARK: - Flood Fill

    func testFloodFillRevealsEmptyRegion() {
        // 3x3 board with mine at (2,2), rest empty
        // Tapping (0,0) which has 0 adjacent mines should flood fill
        let cells: [[Cell]] = [
            [Cell(adjacentMines: 0), Cell(adjacentMines: 0), Cell(adjacentMines: 0)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(adjacentMines: 1)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(isMine: true)],
        ]
        var board = Board(cells: cells, mineCount: 1)
        let result = board.reveal(row: 0, col: 0)
        XCTAssertEqual(result, .won)
        // All non-mine cells should be revealed
        for r in 0..<3 {
            for c in 0..<3 {
                if r == 2 && c == 2 { continue } // mine
                XCTAssertTrue(board.cells[r][c].isRevealed, "Cell (\(r),\(c)) should be revealed")
            }
        }
    }

    func testFloodFillStopsAtNumbers() {
        // 3x3: mine at (0,2)
        // (0,0)=0 (0,1)=1 (0,2)=M
        // (1,0)=0 (1,1)=1 (1,2)=1
        // (2,0)=0 (2,1)=0 (2,2)=0
        let cells: [[Cell]] = [
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(isMine: true)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(adjacentMines: 1)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 0), Cell(adjacentMines: 0)],
        ]
        var board = Board(cells: cells, mineCount: 1)
        _ = board.reveal(row: 2, col: 0)
        // Flood fill from (2,0) should reveal all zeros and stop at numbers
        XCTAssertTrue(board.cells[2][0].isRevealed)
        XCTAssertTrue(board.cells[2][1].isRevealed)
        XCTAssertTrue(board.cells[2][2].isRevealed)
        XCTAssertTrue(board.cells[1][0].isRevealed)
        XCTAssertTrue(board.cells[0][0].isRevealed)
        // Numbers get revealed but their neighbors don't cascade
        XCTAssertTrue(board.cells[1][1].isRevealed)
        XCTAssertTrue(board.cells[0][1].isRevealed)
        XCTAssertTrue(board.cells[1][2].isRevealed)
        // Mine stays hidden
        XCTAssertFalse(board.cells[0][2].isRevealed)
    }

    // MARK: - Flagging

    func testToggleFlag() {
        var board = makeTestBoard()
        XCTAssertTrue(board.cells[0][0].isHidden)
        board.toggleFlag(row: 0, col: 0)
        XCTAssertTrue(board.cells[0][0].isFlagged)
        board.toggleFlag(row: 0, col: 0)
        XCTAssertTrue(board.cells[0][0].isHidden)
    }

    func testFlagRevealedCellIsIgnored() {
        var board = makeTestBoard()
        _ = board.reveal(row: 0, col: 0)
        board.toggleFlag(row: 0, col: 0)
        XCTAssertTrue(board.cells[0][0].isRevealed)
    }

    func testRemainingFlags() {
        var board = makeTestBoard()
        XCTAssertEqual(board.remainingFlags, 1)
        board.toggleFlag(row: 0, col: 0)
        XCTAssertEqual(board.remainingFlags, 0)
    }

    // MARK: - Chord

    func testChordRevealsNeighbors() {
        // 3x3: mine at (0,2), flag it, then chord on (0,1) which is "1"
        let cells: [[Cell]] = [
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(isMine: true)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(adjacentMines: 1)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 0), Cell(adjacentMines: 0)],
        ]
        var board = Board(cells: cells, mineCount: 1)
        // Reveal (0,1) and flag the mine (0,2)
        _ = board.reveal(row: 0, col: 1)
        board.toggleFlag(row: 0, col: 2)
        // Chord on (0,1) — should reveal (0,0), (1,0), (1,1), (1,2)
        let result = board.chord(row: 0, col: 1)
        XCTAssertEqual(result, .won)
        XCTAssertTrue(board.cells[0][0].isRevealed)
        XCTAssertTrue(board.cells[1][1].isRevealed)
    }

    func testChordWithWrongFlagHitsMine() {
        // 3x3: mine at (0,2), but flag (0,0) instead — wrong flag
        let cells: [[Cell]] = [
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(isMine: true)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(adjacentMines: 1)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 0), Cell(adjacentMines: 0)],
        ]
        var board = Board(cells: cells, mineCount: 1)
        _ = board.reveal(row: 0, col: 1)
        board.toggleFlag(row: 0, col: 0) // wrong flag
        let result = board.chord(row: 0, col: 1)
        XCTAssertEqual(result, .mine)
    }

    func testChordNoActionWhenFlagsMismatch() {
        let cells: [[Cell]] = [
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(isMine: true)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(adjacentMines: 1)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 0), Cell(adjacentMines: 0)],
        ]
        var board = Board(cells: cells, mineCount: 1)
        _ = board.reveal(row: 0, col: 1)
        // No flags placed — chord should be noAction
        let result = board.chord(row: 0, col: 1)
        XCTAssertEqual(result, .noAction)
    }

    // MARK: - Win Detection

    func testWinWhenAllNonMinesRevealed() {
        // 2x2 board with 1 mine
        let cells: [[Cell]] = [
            [Cell(adjacentMines: 1), Cell(isMine: true)],
            [Cell(adjacentMines: 1), Cell(adjacentMines: 1)],
        ]
        var board = Board(cells: cells, mineCount: 1)
        _ = board.reveal(row: 0, col: 0)
        _ = board.reveal(row: 1, col: 0)
        let result = board.reveal(row: 1, col: 1)
        XCTAssertEqual(result, .won)
    }

    // MARK: - Neighbors

    func testCornerNeighbors() {
        let board = Board(difficulty: .beginner)
        let neighbors = board.neighbors(of: 0, 0)
        XCTAssertEqual(neighbors.count, 3)
    }

    func testEdgeNeighbors() {
        let board = Board(difficulty: .beginner)
        let neighbors = board.neighbors(of: 0, 4)
        XCTAssertEqual(neighbors.count, 5)
    }

    func testCenterNeighbors() {
        let board = Board(difficulty: .beginner)
        let neighbors = board.neighbors(of: 4, 4)
        XCTAssertEqual(neighbors.count, 8)
    }

    // MARK: - Helpers

    /// 3x3 board: mine at (0,2)
    private func makeTestBoard() -> Board {
        let cells: [[Cell]] = [
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(isMine: true)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 1), Cell(adjacentMines: 1)],
            [Cell(adjacentMines: 0), Cell(adjacentMines: 0), Cell(adjacentMines: 0)],
        ]
        return Board(cells: cells, mineCount: 1)
    }
}
