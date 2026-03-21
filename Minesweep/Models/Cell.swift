import Foundation

enum CellState {
    case hidden
    case revealed
    case flagged
}

struct Cell {
    var isMine: Bool = false
    var state: CellState = .hidden
    var adjacentMines: Int = 0

    var isHidden: Bool { state == .hidden }
    var isRevealed: Bool { state == .revealed }
    var isFlagged: Bool { state == .flagged }
}
