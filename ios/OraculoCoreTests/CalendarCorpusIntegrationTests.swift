import Foundation
import XCTest
@testable import OraculoCore

final class CalendarCorpusIntegrationTests: XCTestCase {
    private var resources: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Shared/Resources")
    }

    func testApprovedCorpusMatchesFestivalDatesAcrossManySeeds() throws {
        let config = try JSONDecoder().decode(CalendarConfig.self, from: Data(contentsOf: resources.appendingPathComponent("calendar.json")))
        let phrases = try XCTUnwrap(PhraseCorpusStorage.decodePhrases(from: Data(contentsOf: resources.appendingPathComponent("phrases.json"))))
        let festivals = FestivalCalendar(config: config)
        let calendar = ContextCalendar.calendar()
        let cases: [(Int, Int, Set<String>)] = [
            (10, 18, ["sb_2084", "sb_2085", "sb_2086", "sb_2101", "sb_2102"]),
            (10, 31, ["sb_2087", "sb_2088"]),
            (11, 26, ["sb_2089", "sb_2090", "sb_2091"]),
            (12, 24, ["sb_2094", "sb_2095"]),
            (12, 25, ["sb_2096", "sb_2097", "sb_2112", "sb_2113"]),
            (12, 31, ["sb_2098", "sb_2099", "sb_2100", "sb_2115"])
        ]
        for (month, day, ids) in cases {
            let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12)))
            let dayKey = String(format: "2026-%02d-%02d", month, day)
            let context = ContextSnapshot(
                dayKey: dayKey, season: month < 12 ? "autumn" : "winter", month: month,
                weekday: calendar.component(.weekday, from: date), dayPart: "noon",
                festivals: festivals.activeFestivals(on: date), weather: nil, tempBand: nil,
                solarTerm: SolarTermCalendar(config: config).activeTermID(on: date),
                geoRegion: "", altitudeBand: "", geoCell: nil, locationSource: "", localeID: ""
            )
            for seed in 0..<100 {
                let phrase = PhrasePicker.pick(from: phrases, context: context, seed: "\(seed)", excluding: nil, now: date)
                XCTAssertTrue(ids.contains(phrase.id), "\(dayKey): \(phrase.id)")
            }
        }
    }

    func testShanghaiDateIgnoresDeviceTimezoneAndCalendarIdentifier() throws {
        let data = try Data(contentsOf: resources.appendingPathComponent("calendar.json"))
        let config = try JSONDecoder().decode(CalendarConfig.self, from: data)
        var device = Calendar(identifier: .buddhist)
        device.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        let formatter = ISO8601DateFormatter()
        let before = try XCTUnwrap(formatter.date(from: "2026-10-30T15:59:59Z"))
        let after = try XCTUnwrap(formatter.date(from: "2026-10-30T16:00:00Z"))
        XCTAssertFalse(FestivalCalendar(config: config).activeFestivals(on: before, calendar: device).contains("halloween"))
        XCTAssertTrue(FestivalCalendar(config: config).activeFestivals(on: after, calendar: device).contains("halloween"))
    }
}
