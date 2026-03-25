import Foundation

class Settings: ObservableObject {
    static let shared = Settings()

    private let store = UserDefaults.standard
    private let longPressDurationKey = "longPressDuration"

    @Published var longPressDuration: Double {
        didSet { store.set(longPressDuration, forKey: longPressDurationKey) }
    }

    private init() {
        let stored = store.double(forKey: longPressDurationKey)
        self.longPressDuration = stored > 0 ? stored : 0.2
    }
}
