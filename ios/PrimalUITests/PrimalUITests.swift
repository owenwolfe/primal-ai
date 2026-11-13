import XCTest

final class PrimalUITests: XCTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-apiBaseURL", "http://localhost:8765"]
        app.launch()
        return app
    }

    func testExampleLabelReachesTheRealBackend() {
        let app = launch()
        app.swipeUp()
        let example = app.buttons["exampleLabel"]
        XCTAssertTrue(example.waitForExistence(timeout: 5))
        example.tap()
        app.buttons["evaluateLabel"].tap()
        let result = app.staticTexts["resultTitle"]
        XCTAssertTrue(result.waitForExistence(timeout: 15))
        XCTAssertEqual(result.label, "A few things to consider")
        XCTAssertTrue(app.staticTexts["honey"].exists)
    }

    func testUnknownIngredientsWithholdOverallRating() {
        let app = launch()
        app.swipeUp()
        let editor = app.textViews["ingredientText"]
        editor.tap()
        editor.typeText("oats, mystery ingredient")
        app.buttons["Done"].tap()
        app.buttons["evaluateLabel"].tap()
        let result = app.staticTexts["resultTitle"]
        XCTAssertTrue(result.waitForExistence(timeout: 15))
        XCTAssertEqual(result.label, "A closer look needed")
        XCTAssertTrue(app.staticTexts["Not yet recognized"].exists)
    }

    func testSimulatorHasAnAlternativeToCameraCapture() {
        let app = launch()
        app.buttons["Photograph a label"].tap()
        XCTAssertTrue(app.alerts["Let’s try that again"].waitForExistence(timeout: 5))
        app.alerts.buttons["OK"].tap()
        XCTAssertTrue(app.buttons["Choose a photo"].exists)
    }
}
