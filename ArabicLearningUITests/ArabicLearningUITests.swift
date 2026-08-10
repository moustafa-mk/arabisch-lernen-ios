import XCTest

final class ArabicLearningUITests: XCTestCase {
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        return app
    }

    func testOnboardingSettingsAndHome() {
        let app = launchApp()

        XCTAssertTrue(app.buttons["start-learning"].waitForExistence(timeout: 5))
        app.buttons["Lesbarkeit und Fokus anpassen"].tap()
        XCTAssertTrue(app.navigationBars["Lesbarkeit & Fokus"].waitForExistence(timeout: 2))
        app.buttons["close-settings"].tap()
        app.buttons["start-learning"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["home-screen"].waitForExistence(timeout: 3)
        )
    }

    func testCompletesAlphabetLessonUsingPaperPractice() {
        let app = launchApp()
        app.buttons["start-learning"].tap()
        XCTAssertTrue(app.buttons["start-lesson"].waitForExistence(timeout: 3))
        app.buttons["start-lesson"].tap()

        XCTAssertTrue(app.buttons["continue-to-discrimination"].waitForExistence(timeout: 3))
        app.buttons["continue-to-discrimination"].tap()
        app.buttons["candidate-alif"].tap()
        app.buttons["continue-to-writing"].tap()

        app.segmentedControls.buttons["Auf Papier"].tap()
        app.buttons["create-practice-sheet"].tap()
        XCTAssertTrue(app.buttons["share-practice-sheet"].waitForExistence(timeout: 3))
        app.switches["paper-practice-confirmation"].tap()
        app.buttons["complete-paper-writing"].tap()

        app.buttons["word-tile-0"].tap()
        app.buttons["word-tile-1"].tap()
        app.buttons["word-tile-2"].tap()
        app.buttons["complete-word-bridge"].tap()

        XCTAssertTrue(app.buttons["finish-lesson"].waitForExistence(timeout: 3))
        app.buttons["finish-lesson"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["home-screen"].waitForExistence(timeout: 3)
        )
    }

    func testCreatesAlphabetHomeworkWorkbook() {
        let app = launchApp()
        app.buttons["start-learning"].tap()

        let createButton = app.buttons["create-homework-workbook"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 3))
        for _ in 0..<3 {
            if createButton.isHittable {
                break
            }
            app.swipeUp()
        }

        XCTAssertTrue(createButton.isHittable)
        createButton.tap()
        XCTAssertTrue(
            app.buttons["share-homework-workbook"].waitForExistence(timeout: 10)
        )
    }
}
