import XCTest
@testable import Minesweep

final class DifficultyTests: XCTestCase {

    func testBeginnerPreset() {
        let d = Difficulty.beginner
        XCTAssertEqual(d.rows, 9)
        XCTAssertEqual(d.columns, 9)
        XCTAssertEqual(d.mineCount, 10)
        XCTAssertEqual(d.displayName, "Beginner")
    }

    func testIntermediatePreset() {
        let d = Difficulty.intermediate
        XCTAssertEqual(d.rows, 12)
        XCTAssertEqual(d.columns, 12)
        XCTAssertEqual(d.mineCount, 22)
        XCTAssertEqual(d.displayName, "Intermediate")
    }

    func testExpertPreset() {
        let d = Difficulty.expert
        XCTAssertEqual(d.rows, 16)
        XCTAssertEqual(d.columns, 10)
        XCTAssertEqual(d.mineCount, 32)
        XCTAssertEqual(d.displayName, "Expert")
    }

    func testMineCountLessThanTotalCells() {
        for difficulty in Difficulty.allCases {
            XCTAssertLessThan(difficulty.mineCount, difficulty.rows * difficulty.columns,
                "\(difficulty.displayName) has too many mines")
        }
    }

    func testAllCasesCount() {
        XCTAssertEqual(Difficulty.allCases.count, 3)
    }
}
