import Foundation

protocol StatsRecording {
    func recordWin(difficulty: Difficulty, time: Int)
    func recordLoss(difficulty: Difficulty)
}

class StatsStore: ObservableObject, StatsRecording {
    static let shared = StatsStore()

    private let cloudStore = NSUbiquitousKeyValueStore.default
    private let localStore = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    @Published private(set) var statsByDifficulty: [Difficulty: GameStats]

    private init() {
        statsByDifficulty = [:]
        for difficulty in Difficulty.allCases {
            statsByDifficulty[difficulty] = load(difficulty: difficulty)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore
        )
        cloudStore.synchronize()
    }

    func stats(for difficulty: Difficulty) -> GameStats {
        statsByDifficulty[difficulty] ?? GameStats()
    }

    func recordWin(difficulty: Difficulty, time: Int) {
        var current = stats(for: difficulty)
        current.recordWin(time: time)
        save(stats: current, difficulty: difficulty)
    }

    func recordLoss(difficulty: Difficulty) {
        var current = stats(for: difficulty)
        current.recordLoss()
        save(stats: current, difficulty: difficulty)
    }

    private func key(for difficulty: Difficulty) -> String {
        "stats_\(difficulty.rawValue)"
    }

    private func save(stats: GameStats, difficulty: Difficulty) {
        statsByDifficulty[difficulty] = stats
        if let data = try? encoder.encode(stats) {
            localStore.set(data, forKey: key(for: difficulty))
            cloudStore.set(data, forKey: key(for: difficulty))
            cloudStore.synchronize()
        }
    }

    private func load(difficulty: Difficulty) -> GameStats {
        // Prefer iCloud data, fall back to local
        if let data = cloudStore.data(forKey: key(for: difficulty)),
           let stats = try? decoder.decode(GameStats.self, from: data) {
            return stats
        }
        if let data = localStore.data(forKey: key(for: difficulty)),
           let stats = try? decoder.decode(GameStats.self, from: data) {
            return stats
        }
        return GameStats()
    }

    @objc private func storeDidChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            for difficulty in Difficulty.allCases {
                let stats = self.load(difficulty: difficulty)
                self.statsByDifficulty[difficulty] = stats
                // Sync iCloud data down to local
                if let data = try? self.encoder.encode(stats) {
                    self.localStore.set(data, forKey: self.key(for: difficulty))
                }
            }
        }
    }
}
