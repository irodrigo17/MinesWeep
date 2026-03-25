import XCTest
@testable import Minesweep

final class GameStatsTests: XCTestCase {

    func testInitialStats() {
        let stats = GameStats()
        XCTAssertEqual(stats.gamesPlayed, 0)
        XCTAssertEqual(stats.wins, 0)
        XCTAssertEqual(stats.losses, 0)
        XCTAssertNil(stats.bestTime)
        XCTAssertEqual(stats.winRate, 0)
        XCTAssertNil(stats.averageWinTime)
    }

    func testRecordWin() {
        var stats = GameStats()
        stats.recordWin(time: 30)
        XCTAssertEqual(stats.gamesPlayed, 1)
        XCTAssertEqual(stats.wins, 1)
        XCTAssertEqual(stats.losses, 0)
        XCTAssertEqual(stats.bestTime, 30)
        XCTAssertEqual(stats.winRate, 1.0)
        XCTAssertEqual(stats.averageWinTime, 30)
    }

    func testRecordLoss() {
        var stats = GameStats()
        stats.recordLoss()
        XCTAssertEqual(stats.gamesPlayed, 1)
        XCTAssertEqual(stats.wins, 0)
        XCTAssertEqual(stats.losses, 1)
        XCTAssertEqual(stats.winRate, 0)
    }

    func testBestTimeTracksMinimum() {
        var stats = GameStats()
        stats.recordWin(time: 50)
        stats.recordWin(time: 30)
        stats.recordWin(time: 40)
        XCTAssertEqual(stats.bestTime, 30)
    }

    func testAverageWinTime() {
        var stats = GameStats()
        stats.recordWin(time: 20)
        stats.recordWin(time: 40)
        XCTAssertEqual(stats.averageWinTime, 30)
    }

    func testWinRate() {
        var stats = GameStats()
        stats.recordWin(time: 10)
        stats.recordLoss()
        stats.recordWin(time: 20)
        stats.recordLoss()
        XCTAssertEqual(stats.winRate, 0.5, accuracy: 0.001)
    }

    func testCodable() throws {
        var stats = GameStats()
        stats.recordWin(time: 42)
        stats.recordLoss()

        let data = try JSONEncoder().encode(stats)
        let decoded = try JSONDecoder().decode(GameStats.self, from: data)

        XCTAssertEqual(decoded.gamesPlayed, 2)
        XCTAssertEqual(decoded.wins, 1)
        XCTAssertEqual(decoded.losses, 1)
        XCTAssertEqual(decoded.bestTime, 42)
        XCTAssertEqual(decoded.totalWinTime, 42)
    }
}
