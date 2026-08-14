import XCTest

final class InteractionHintUITests: XCTestCase {
    func testResumeKeepsCurrentPhraseAfterAutomaticRefreshWindow() {
        let app = XCUIApplication()
        app.launch()

        let phrase = app.staticTexts.matching(identifier: "current-oracle-phrase").firstMatch
        XCTAssertTrue(phrase.waitForExistence(timeout: 5))
        let originalText = phrase.label

        Thread.sleep(forTimeInterval: 5)
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 3))

        app.activate()
        XCTAssertTrue(phrase.waitForExistence(timeout: 3))
        Thread.sleep(forTimeInterval: 2.6)

        XCTAssertEqual(
            phrase.label,
            originalText,
            "回前台应重播当前句动画，不应自动换句"
        )
    }

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
