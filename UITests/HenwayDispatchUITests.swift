import XCTest

final class HenwayDispatchUITests: XCTestCase {
    func testDispatchAndResume() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITestCleanSession", "-AppleLanguages", "(en-GB)"]
        app.launch()
        let start = app.buttons["start"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        start.tap()
        app.buttons["signal-west"].tap()
        let send = app.buttons["enter-west"]
        XCTAssertTrue(send.isEnabled)
        send.tap()
        XCTAssertFalse(send.isEnabled)
        app.buttons["pause"].tap()
        XCTAssertFalse(app.buttons["signal-west"].isEnabled)
        app.buttons["home"].tap()
        XCTAssertTrue(app.buttons["start"].label.contains("Resume"))
        app.buttons["start"].tap()
        XCTAssertTrue(app.buttons["signal-west"].isEnabled)
    }
    func testDistrictSchedule() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITestCleanSession", "-AppleLanguages", "(en-GB)"]
        app.launch()
        app.buttons["map"].tap()
        app.buttons["district-station"].tap()
        app.buttons["level-28"].tap()
        let timetable = app.buttons["timetable"]
        if !timetable.isHittable { app.swipeUp() }
        timetable.tap()
        XCTAssertTrue(app.staticTexts["Scheduled train"].firstMatch.exists)
    }
}
