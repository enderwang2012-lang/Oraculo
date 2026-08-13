import XCTest

final class InteractionHintUITests: XCTestCase {
    func testHintPersistsUntilSuccessfulLongPressThenStaysDismissed() {
        let app = XCUIApplication()
        app.launchArguments = ["--reset-interaction-hint"]
        app.launch()

        let hint = app.staticTexts["长按印记切换文字"]
        XCTAssertTrue(hint.waitForExistence(timeout: 5))

        let mark = app.buttons["换一句"]
        XCTAssertTrue(mark.waitForExistence(timeout: 5))

        Thread.sleep(forTimeInterval: 4)
        XCTAssertTrue(hint.exists, "提示不应自动消失")

        mark.press(forDuration: 0.35)
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(hint.exists, "未完成长按时不应关闭提示")

        mark.press(forDuration: 2.2)

        let dismissed = NSPredicate(format: "exists == false")
        expectation(
            for: dismissed,
            evaluatedWith: hint,
            handler: nil
        )
        waitForExpectations(timeout: 1.4)

        app.terminate()
        app.launchArguments = []
        app.launch()

        XCTAssertFalse(hint.waitForExistence(timeout: 2))
    }
}
