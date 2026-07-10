import Foundation
import XCTest
@testable import OraculoCore

final class FestivalCalendarTests: XCTestCase {
    private var calendar: Calendar!
    private var festivals: FestivalCalendar!

    override func setUpWithError() throws {
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Shanghai"))
        festivals = try FestivalCalendar(data: Data(fixtureJSON.utf8))
    }

    func testSingleDayFestivalMatchesTheWholeCalendarDay() {
        XCTAssertTrue(
            festivals.activeFestivals(
                on: date(2026, 2, 14, 12, 30),
                calendar: calendar
            ).contains("valentine")
        )
        XCTAssertFalse(
            festivals.activeFestivals(
                on: date(2026, 2, 15, 0, 0),
                calendar: calendar
            ).contains("valentine")
        )
    }

    func testRangeEndAndPostDaysIncludeTheirWholeCalendarDays() {
        XCTAssertTrue(
            festivals.activeFestivals(
                on: date(2026, 6, 21, 23, 59),
                calendar: calendar
            ).contains("dragon_boat")
        )
        XCTAssertTrue(
            festivals.activeFestivals(
                on: date(2026, 6, 23, 23, 59),
                calendar: calendar
            ).contains("dragon_boat")
        )
        XCTAssertFalse(
            festivals.activeFestivals(
                on: date(2026, 6, 24, 0, 0),
                calendar: calendar
            ).contains("dragon_boat")
        )
    }

    func testCrossYearFestivalMatchesJanuaryDatesFromPreviousAnchorYear() {
        XCTAssertTrue(
            festivals.activeFestivals(
                on: date(2025, 12, 31, 12, 0),
                calendar: calendar
            ).contains("new_year")
        )
        XCTAssertTrue(
            festivals.activeFestivals(
                on: date(2026, 1, 1, 12, 0),
                calendar: calendar
            ).contains("new_year")
        )
        XCTAssertTrue(
            festivals.activeFestivals(
                on: date(2026, 1, 2, 23, 59),
                calendar: calendar
            ).contains("new_year")
        )
        XCTAssertFalse(
            festivals.activeFestivals(
                on: date(2026, 1, 3, 0, 0),
                calendar: calendar
            ).contains("new_year")
        )
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
        )!
    }

    private var fixtureJSON: String {
        """
        {
          "version": 1,
          "festivals": [
            {
              "id": "new_year",
              "ranges": [
                { "start": "12-31", "end": "01-02" }
              ],
              "pre_days": 0,
              "post_days": 0
            },
            {
              "id": "dragon_boat",
              "ranges": [
                { "start": "2026-06-19", "end": "2026-06-21" }
              ],
              "pre_days": 0,
              "post_days": 2
            },
            {
              "id": "valentine",
              "ranges": [
                { "start": "02-14", "end": "02-14" }
              ],
              "pre_days": 1,
              "post_days": 0
            }
          ]
        }
        """
    }
}
