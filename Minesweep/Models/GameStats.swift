import Foundation

struct GameStats: Codable {
    var gamesPlayed: Int = 0
    var wins: Int = 0
    var losses: Int = 0
    var bestTime: Int?
    var totalWinTime: Int = 0

    var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(wins) / Double(gamesPlayed)
    }

    var averageWinTime: Int? {
        guard wins > 0 else { return nil }
        return totalWinTime / wins
    }

    mutating func recordWin(time: Int) {
        gamesPlayed += 1
        wins += 1
        totalWinTime += time
        if let best = bestTime {
            bestTime = min(best, time)
        } else {
            bestTime = time
        }
    }

    mutating func recordLoss() {
        gamesPlayed += 1
        losses += 1
    }
}
