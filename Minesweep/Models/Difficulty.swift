import Foundation

enum Difficulty: String, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case expert

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beginner: "Beginner"
        case .intermediate: "Intermediate"
        case .expert: "Expert"
        }
    }

    var rows: Int {
        switch self {
        case .beginner: 9
        case .intermediate: 16
        case .expert: 16
        }
    }

    var columns: Int {
        switch self {
        case .beginner: 9
        case .intermediate: 16
        case .expert: 30
        }
    }

    var mineCount: Int {
        switch self {
        case .beginner: 10
        case .intermediate: 40
        case .expert: 99
        }
    }
}
