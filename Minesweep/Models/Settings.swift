import Foundation

class Settings: ObservableObject {
    static let shared = Settings()

    private let store = UserDefaults.standard
    private let longPressDurationKey = "longPressDuration"
    private let solvableBoardsKey = "solvableBoards"

    @Published var longPressDuration: Double {
        didSet { store.set(longPressDuration, forKey: longPressDurationKey) }
    }

    @Published var solvableBoards: Bool {
        didSet { store.set(solvableBoards, forKey: solvableBoardsKey) }
    }

    private init() {
        let stored = store.double(forKey: longPressDurationKey)
        self.longPressDuration = stored > 0 ? stored : 0.2
        self.solvableBoards = store.object(forKey: solvableBoardsKey) == nil ? true : store.bool(forKey: solvableBoardsKey)
    }
}
