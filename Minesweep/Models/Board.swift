import Foundation

struct Board {
    let rows: Int
    let columns: Int
    let mineCount: Int
    private(set) var cells: [[Cell]]
    private(set) var minesPlaced: Bool = false
    private(set) var revealedCount: Int = 0
    private(set) var flagCount: Int = 0

    var totalCells: Int { rows * columns }
    var remainingFlags: Int { mineCount - flagCount }

    init(difficulty: Difficulty) {
        self.rows = difficulty.rows
        self.columns = difficulty.columns
        self.mineCount = difficulty.mineCount
        self.cells = Array(
            repeating: Array(repeating: Cell(), count: difficulty.columns),
            count: difficulty.rows
        )
    }

    /// Test initializer: create a board from a pre-built cell grid.
    init(cells: [[Cell]], mineCount: Int) {
        self.rows = cells.count
        self.columns = cells.first?.count ?? 0
        self.mineCount = mineCount
        self.cells = cells
        self.minesPlaced = true
        let flat = cells.flatMap { $0 }
        self.revealedCount = flat.filter { $0.isRevealed }.count
        self.flagCount = flat.filter { $0.isFlagged }.count
    }

    // MARK: - Mine Placement

    private mutating func placeMinesOnce(excludingRow row: Int, excludingColumn col: Int, using rng: inout some RandomNumberGenerator) {
        guard !minesPlaced else { return }

        let exclusionZone = neighbors(of: row, col) + [(row, col)]
        let exclusionSet = Set(exclusionZone.map { $0.0 * columns + $0.1 })

        var candidates = [Int]()
        for i in 0..<totalCells where !exclusionSet.contains(i) {
            candidates.append(i)
        }

        candidates.shuffle(using: &rng)
        let minePositions = candidates.prefix(mineCount)

        for pos in minePositions {
            let r = pos / columns
            let c = pos % columns
            cells[r][c].isMine = true
        }

        computeAdjacentMineCounts()
        minesPlaced = true
    }

    mutating func placeMines(excludingRow row: Int, excludingColumn col: Int, ensureSolvable: Bool = true) {
        guard !minesPlaced else { return }
        var rng = SystemRandomNumberGenerator()
        if ensureSolvable {
            let maxAttempts = 100
            for attempt in 0..<maxAttempts {
                placeMinesOnce(excludingRow: row, excludingColumn: col, using: &rng)
                if attempt == maxAttempts - 1 || isSolvable(fromRow: row, col: col) {
                    break
                }
                resetMines()
            }
        } else {
            placeMinesOnce(excludingRow: row, excludingColumn: col, using: &rng)
        }
    }

    mutating func placeMines(excludingRow row: Int, excludingColumn col: Int, using rng: inout some RandomNumberGenerator) {
        placeMinesOnce(excludingRow: row, excludingColumn: col, using: &rng)
    }

    private mutating func resetMines() {
        for r in 0..<rows {
            for c in 0..<columns {
                cells[r][c].isMine = false
                cells[r][c].adjacentMines = 0
            }
        }
        minesPlaced = false
    }

    private mutating func computeAdjacentMineCounts() {
        for r in 0..<rows {
            for c in 0..<columns {
                guard !cells[r][c].isMine else { continue }
                cells[r][c].adjacentMines = neighbors(of: r, c)
                    .filter { cells[$0.0][$0.1].isMine }
                    .count
            }
        }
    }

    // MARK: - Cell Actions

    mutating func reveal(row: Int, col: Int) -> RevealResult {
        guard isValid(row: row, col: col) else { return .noAction }
        guard cells[row][col].isHidden else { return .noAction }

        cells[row][col].state = .revealed
        revealedCount += 1

        if cells[row][col].isMine {
            revealAllMines()
            return .mine
        }

        if cells[row][col].adjacentMines == 0 {
            floodFill(from: row, col)
        }

        if revealedCount == totalCells - mineCount {
            return .won
        }
        return .safe
    }

    mutating func toggleFlag(row: Int, col: Int) {
        guard isValid(row: row, col: col) else { return }
        switch cells[row][col].state {
        case .hidden:
            cells[row][col].state = .flagged
            flagCount += 1
        case .flagged:
            cells[row][col].state = .hidden
            flagCount -= 1
        case .revealed:
            break
        }
    }

    mutating func chord(row: Int, col: Int) -> RevealResult {
        guard isValid(row: row, col: col) else { return .noAction }
        guard cells[row][col].isRevealed else { return .noAction }
        guard cells[row][col].adjacentMines > 0 else { return .noAction }

        let adjacentFlags = neighbors(of: row, col)
            .filter { cells[$0.0][$0.1].isFlagged }
            .count

        guard adjacentFlags == cells[row][col].adjacentMines else { return .noAction }

        var hitMine = false
        for (r, c) in neighbors(of: row, col) {
            if cells[r][c].isHidden {
                cells[r][c].state = .revealed
                if cells[r][c].isMine {
                    hitMine = true
                } else {
                    revealedCount += 1
                    if !hitMine && cells[r][c].adjacentMines == 0 {
                        floodFill(from: r, c)
                    }
                }
            }
        }

        if hitMine {
            revealAllMines()
            return .mine
        }
        if revealedCount == totalCells - mineCount {
            return .won
        }
        return .safe
    }

    // MARK: - Flood Fill (BFS)

    private mutating func floodFill(from startRow: Int, _ startCol: Int) {
        var queue = [(startRow, startCol)]
        while !queue.isEmpty {
            let (r, c) = queue.removeFirst()
            for (nr, nc) in neighbors(of: r, c) {
                guard cells[nr][nc].isHidden else { continue }
                cells[nr][nc].state = .revealed
                revealedCount += 1
                if cells[nr][nc].adjacentMines == 0 {
                    queue.append((nr, nc))
                }
            }
        }
    }

    // MARK: - Mine Reveal on Loss

    private mutating func revealAllMines() {
        for r in 0..<rows {
            for c in 0..<columns {
                if cells[r][c].isMine && cells[r][c].isHidden {
                    cells[r][c].state = .revealed
                }
            }
        }
    }

    // MARK: - Solvability Check

    /// Simulates logical play from the given starting cell.
    /// Returns true if all safe cells can be revealed without guessing.
    func isSolvable(fromRow startRow: Int, col startCol: Int) -> Bool {
        // Build a simulation grid: true = revealed, false = hidden
        var revealed = Array(repeating: Array(repeating: false, count: columns), count: rows)
        var flagged = Array(repeating: Array(repeating: false, count: columns), count: rows)
        var revealedCount = 0
        let safeCellCount = totalCells - mineCount

        // Simulate initial reveal + flood fill from starting cell
        func floodFill(from r: Int, _ c: Int) {
            var queue = [(r, c)]
            while !queue.isEmpty {
                let (cr, cc) = queue.removeFirst()
                for (nr, nc) in neighbors(of: cr, cc) {
                    guard !revealed[nr][nc] && !cells[nr][nc].isMine else { continue }
                    revealed[nr][nc] = true
                    revealedCount += 1
                    if cells[nr][nc].adjacentMines == 0 {
                        queue.append((nr, nc))
                    }
                }
            }
        }

        revealed[startRow][startCol] = true
        revealedCount += 1
        if cells[startRow][startCol].adjacentMines == 0 {
            floodFill(from: startRow, startCol)
        }

        if revealedCount == safeCellCount { return true }

        // Iteratively apply logical deduction
        var progress = true
        while progress {
            progress = false

            for r in 0..<rows {
                for c in 0..<columns {
                    guard revealed[r][c] && cells[r][c].adjacentMines > 0 else { continue }

                    let neighs = neighbors(of: r, c)
                    var hiddenNeighbors = [(Int, Int)]()
                    var flaggedCount = 0
                    for (nr, nc) in neighs {
                        if flagged[nr][nc] {
                            flaggedCount += 1
                        } else if !revealed[nr][nc] {
                            hiddenNeighbors.append((nr, nc))
                        }
                    }

                    let remainingMines = cells[r][c].adjacentMines - flaggedCount

                    // Rule 1: All remaining hidden neighbors are mines → flag them
                    if remainingMines == hiddenNeighbors.count && remainingMines > 0 {
                        for (nr, nc) in hiddenNeighbors {
                            flagged[nr][nc] = true
                            progress = true
                        }
                    }

                    // Rule 2: All mines accounted for → reveal remaining hidden neighbors
                    if remainingMines == 0 && !hiddenNeighbors.isEmpty {
                        for (nr, nc) in hiddenNeighbors {
                            if !cells[nr][nc].isMine {
                                revealed[nr][nc] = true
                                revealedCount += 1
                                progress = true
                                if cells[nr][nc].adjacentMines == 0 {
                                    floodFill(from: nr, nc)
                                }
                            }
                        }
                    }
                }
            }

            if revealedCount == safeCellCount { return true }
        }

        return revealedCount == safeCellCount
    }

    // MARK: - Helpers

    func neighbors(of row: Int, _ col: Int) -> [(Int, Int)] {
        var result = [(Int, Int)]()
        for dr in -1...1 {
            for dc in -1...1 {
                guard !(dr == 0 && dc == 0) else { continue }
                let r = row + dr
                let c = col + dc
                if isValid(row: r, col: c) {
                    result.append((r, c))
                }
            }
        }
        return result
    }

    func isValid(row: Int, col: Int) -> Bool {
        row >= 0 && row < rows && col >= 0 && col < columns
    }
}

enum RevealResult {
    case safe
    case mine
    case won
    case noAction
}
