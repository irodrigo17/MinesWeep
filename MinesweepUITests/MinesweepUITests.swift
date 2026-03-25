import XCTest

final class MinesweepUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Menu

    func testMenuShowsDifficultyButtons() {
        XCTAssertTrue(app.staticTexts["Minesweeper"].exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Beginner'")).firstMatch.exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Intermediate'")).firstMatch.exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Expert'")).firstMatch.exists)
    }

    func testMenuShowsStatisticsButton() {
        XCTAssertTrue(app.buttons["Statistics"].exists)
    }

    // MARK: - Navigation

    func testSelectDifficultyNavigatesToGame() {
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Beginner'")).firstMatch.tap()
        // Game screen should show the grid — verify a cell exists
        let cell = app.descendants(matching: .any)["cell_0_0"]
        XCTAssertTrue(cell.waitForExistence(timeout: 2))
    }

    func testMenuButtonNavigatesBackToMenu() {
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Beginner'")).firstMatch.tap()
        let cell = app.descendants(matching: .any)["cell_0_0"]
        XCTAssertTrue(cell.waitForExistence(timeout: 2))

        app.buttons["menuButton"].tap()
        XCTAssertTrue(app.staticTexts["Minesweeper"].waitForExistence(timeout: 2))
    }

    // MARK: - Game Grid

    func testTappingCellRevealsIt() {
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Beginner'")).firstMatch.tap()
        let cell = app.descendants(matching: .any)["cell_0_0"]
        XCTAssertTrue(cell.waitForExistence(timeout: 2))

        // Cell should start as hidden
        XCTAssertTrue(cell.label.contains("hidden"))

        cell.tap()

        // After tap, the cell label should no longer say "hidden"
        let revealed = NSPredicate(format: "NOT (label CONTAINS 'hidden')")
        expectation(for: revealed, evaluatedWith: cell)
        waitForExpectations(timeout: 2)
    }

    // MARK: - Flag Mode

    func testFlagModeToggle() {
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Beginner'")).firstMatch.tap()
        let flagToggle = app.buttons["flagToggle"]
        XCTAssertTrue(flagToggle.waitForExistence(timeout: 2))

        // Initially flag mode off
        XCTAssertEqual(flagToggle.label, "Flag mode off")

        flagToggle.tap()
        XCTAssertEqual(flagToggle.label, "Flag mode on")

        flagToggle.tap()
        XCTAssertEqual(flagToggle.label, "Flag mode off")
    }

    func testFlagModeFlagsCell() {
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Beginner'")).firstMatch.tap()
        let flagToggle = app.buttons["flagToggle"]
        XCTAssertTrue(flagToggle.waitForExistence(timeout: 2))

        // Enable flag mode
        flagToggle.tap()

        // Tap a cell — should flag it instead of revealing
        let cell = app.descendants(matching: .any)["cell_4_4"]
        XCTAssertTrue(cell.waitForExistence(timeout: 2))
        cell.tap()

        let flagged = NSPredicate(format: "label CONTAINS 'flagged'")
        expectation(for: flagged, evaluatedWith: cell)
        waitForExpectations(timeout: 2)
    }

    // MARK: - Reset Button

    func testResetButtonResetsBoard() {
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Beginner'")).firstMatch.tap()
        let cell = app.descendants(matching: .any)["cell_0_0"]
        XCTAssertTrue(cell.waitForExistence(timeout: 2))

        // Reveal a cell
        cell.tap()

        // Tap reset (smiley) button
        let resetButton = app.buttons["resetButton"]
        resetButton.tap()

        // Cell should be hidden again
        let hidden = NSPredicate(format: "label CONTAINS 'hidden'")
        expectation(for: hidden, evaluatedWith: cell)
        waitForExpectations(timeout: 2)
    }

    // MARK: - Statistics

    func testStatsViewOpensAndCloses() {
        app.buttons["Statistics"].tap()

        let statsTitle = app.staticTexts["Statistics"]
        XCTAssertTrue(statsTitle.waitForExistence(timeout: 2))

        // Verify stat labels exist
        XCTAssertTrue(app.staticTexts["Games Played"].exists)
        XCTAssertTrue(app.staticTexts["Wins"].exists)
        XCTAssertTrue(app.staticTexts["Win Rate"].exists)

        // Swipe down to dismiss
        app.swipeDown()
        XCTAssertTrue(app.staticTexts["Minesweeper"].waitForExistence(timeout: 2))
    }

    // MARK: - Difficulty Labels

    func testBeginnerDifficultyShowsInGame() {
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Beginner'")).firstMatch.tap()
        let difficultyLabel = app.staticTexts["Beginner"]
        XCTAssertTrue(difficultyLabel.waitForExistence(timeout: 2))
    }

    func testIntermediateDifficultyShowsInGame() {
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Intermediate'")).firstMatch.tap()
        let difficultyLabel = app.staticTexts["Intermediate"]
        XCTAssertTrue(difficultyLabel.waitForExistence(timeout: 2))
    }

    func testExpertDifficultyShowsInGame() {
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Expert'")).firstMatch.tap()
        let difficultyLabel = app.staticTexts["Expert"]
        XCTAssertTrue(difficultyLabel.waitForExistence(timeout: 2))
    }
}
