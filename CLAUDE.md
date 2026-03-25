# CLAUDE.md - Minesweep Project Guide

## Project Overview

Minesweep is a Minesweeper game for iOS built with Swift and SwiftUI. Zero third-party dependencies.

- **Language:** Swift 5
- **UI:** SwiftUI
- **Architecture:** MVVM
- **Min target:** iOS 17.0
- **Xcode:** 15+

## Build & Test Commands

```bash
# Build
xcodebuild -project Minesweep.xcodeproj \
  -scheme Minesweep \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build

# Run all tests (unit + UI)
xcodebuild -project Minesweep.xcodeproj \
  -scheme Minesweep \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test

# Run unit tests only
xcodebuild -project Minesweep.xcodeproj \
  -scheme Minesweep \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:MinesweepTests \
  test

# Run UI tests only
xcodebuild -project Minesweep.xcodeproj \
  -scheme Minesweep \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:MinesweepUITests \
  test
```

## Project Structure

```
Minesweep/
├── App/
│   └── MinesweepApp.swift           # @main, ContentView with menu↔game navigation
├── Models/
│   ├── Cell.swift                   # Cell struct, CellState enum (hidden/revealed/flagged)
│   ├── GameState.swift              # GameState enum (idle/playing/won/lost)
│   ├── Difficulty.swift             # Difficulty enum with rows/columns/mineCount presets
│   ├── Board.swift                  # Game engine: mines, reveal, flood fill, chord, flags, solvability
│   ├── GameStats.swift              # Per-difficulty stats (Codable)
│   ├── StatsStore.swift             # StatsRecording protocol + iCloud/UserDefaults persistence
│   └── Settings.swift               # User settings (long press duration), persisted via UserDefaults
├── ViewModels/
│   └── GameViewModel.swift          # ObservableObject bridging Board to views
├── Views/
│   ├── CellView.swift               # Cell rendering + shimmer hint animation
│   ├── HeaderView.swift             # Flag counter, flag toggle, reset button, timer
│   ├── MenuView.swift               # Difficulty selection + stats access
│   ├── GameView.swift               # Main game screen, grid, gestures, accessibility
│   ├── GameOverView.swift           # Win/loss overlay
│   ├── StatsView.swift              # Per-difficulty statistics display
│   └── SettingsView.swift           # Settings configuration (long press duration slider)
├── Utilities/
│   ├── HapticManager.swift          # UIKit haptic feedback wrapper
│   └── ShakeDetector.swift          # Device shake detection for hints
MinesweepTests/                      # 74 unit tests
├── BoardTests.swift                 # 41 tests - core game engine
├── GameViewModelTests.swift         # 15 tests - state transitions, hints
├── GameStatsTests.swift             # 7 tests - stats recording
├── StatsStoreTests.swift            # 6 tests - protocol, DI integration
└── DifficultyTests.swift            # 5 tests - preset validation
MinesweepUITests/                    # 11 UI tests
└── MinesweepUITests.swift           # End-to-end XCUITests
```

## Architecture

### MVVM Layers

- **Models** (`Foundation` only): Pure game logic — `Board` owns `Cell` grid, handles mine placement, reveal, flood fill, chord, flagging, win detection. No UI dependencies.
- **ViewModel** (`Foundation` + `Combine`): `GameViewModel` is an `ObservableObject` with `@Published` properties. Bridges `Board` to views. Manages timer, hints, flag mode, stats recording.
- **Views** (`SwiftUI`): Declarative UI. `ContentView` manages navigation state. `GameView` renders grid via `GeometryReader` for sizing.

### Key Patterns

- **`ObservableObject` + `@Published`** — not `@Observable` (iOS 17 compatibility)
- **Protocol-based DI** — `StatsRecording` protocol allows injecting `MockStatsRecorder` in tests
- **First-tap safety** — mines placed after first tap; tapped cell + neighbors excluded
- **Deferred mine placement** — `Board` starts empty, `placeMines()` called on first reveal
- **Incremental counters** — `revealedCount` and `flagCount` are stored properties updated incrementally, not computed via O(n) scans
- **Singleton settings** — `Settings.shared` persists user preferences to `UserDefaults`, observed by views via `@ObservedObject`
- **Timer pause/resume** — `GameViewModel.pauseTimer()`/`resumeTimer()` track accumulated time so opening settings mid-game doesn't count toward elapsed time

### Game Flow

1. App launches → `MenuView` (difficulty selection)
2. User picks difficulty → `GameViewModel` created → `GameView` shown
3. First tap → `Board.placeMines()` → `gameState` transitions `idle` → `playing`
4. Tap hidden cell → reveal; tap revealed number → chord; flag mode tap → toggle flag
5. All safe cells revealed → `won`; mine revealed → `lost`
6. Stats recorded via `StatsRecording` on win/loss

### Navigation

`ContentView` uses `@State private var currentViewModel: GameViewModel?` — `nil` = menu, non-nil = game. Slide transitions between screens.

## Testing Conventions

- **Unit tests** use pre-built boards via `Board(cells:mineCount:)` test initializer for deterministic behavior
- **Mock injection** — `GameViewModelTests` uses `MockStatsRecorder` (defined in `StatsStoreTests.swift`) to prevent tests writing to real stats
- **`try XCTSkipIf`** — used instead of silent `guard/return` when flood fill might win the game before the test condition can be evaluated
- **UI tests** use `app.descendants(matching: .any)["identifier"]` to find cells since their accessibility type changes (button when hidden, other when revealed)
- **Accessibility identifiers** for XCUITest: `cell_{row}_{col}`, `flagToggle`, `resetButton`, `menuButton`, `settingsButton`

## Difficulty Levels

| Level | Grid | Mines |
|-------|------|-------|
| Beginner | 9x9 | 10 |
| Intermediate | 12x12 | 22 |
| Expert | 16x10 | 32 |

Board sizes optimized for mobile portrait, not classic desktop sizes.

## Key Algorithms

- **Flood fill**: BFS from empty (adjacentMines=0) cells, reveals neighbors, stops at numbered cells
- **Chord**: When tapping revealed number with correct adjacent flags, auto-reveals remaining hidden neighbors
- **Smart hints** (shake to trigger): 3-tier priority — (1) logically deducible safe cells, (2) frontier cells adjacent to revealed, (3) any hidden non-mine cell
- **Solvable board generation**: Generate-and-test approach — place mines, simulate logical play (flag deduction + reveal deduction), retry up to 100 times if unsolvable. Configurable via `Settings.solvableBoards`
