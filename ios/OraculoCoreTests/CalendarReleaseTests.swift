import Foundation
import XCTest
@testable import OraculoCore

final class CalendarReleaseTests: XCTestCase {
    func testRemoteCalendarConfigTakesPrecedenceOverBundledConfig() {
        let bundled = CalendarConfig(
            version: 1,
            timezone: "Asia/Shanghai",
            festivals: [
                FestivalDefinition(
                    id: "bundled_only",
                    name: "内置",
                    ranges: [],
                    recurrence: nil,
                    preDays: 0,
                    postDays: 0
                )
            ],
            solarTerms: [:]
        )
        let remote = CalendarConfig(
            version: 2,
            timezone: "Asia/Shanghai",
            festivals: [
                FestivalDefinition(
                    id: "remote_only",
                    name: "远程",
                    ranges: [],
                    recurrence: nil,
                    preDays: 0,
                    postDays: 0
                )
            ],
            solarTerms: [:]
        )

        let store = CalendarConfigStore(bundleConfig: bundled, remoteConfig: remote)

        XCTAssertEqual(store.config.version, 2)
        XCTAssertEqual(store.config.festivals.map(\.id), ["remote_only"])
    }

    func testCalendarConfigRoundTripsCombinedRemoteAsset() throws {
        let config = CalendarConfig(
            version: 13,
            timezone: "Asia/Shanghai",
            festivals: [],
            solarTerms: [
                "2027": [
                    SolarTermDefinition(id: "dongzhi", name: "冬至", start: "2027-12-22")
                ]
            ]
        )

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(CalendarConfig.self, from: data)

        XCTAssertEqual(decoded, config)
    }

    func testOlderRemoteCalendarCannotOverrideNewBundle() {
        let bundled = CalendarConfig(version: 14, festivals: [], solarTerms: [:])
        let remote = CalendarConfig(version: 13, festivals: [], solarTerms: [:])
        let store = CalendarConfigStore(bundleConfig: bundled, remoteConfig: remote)
        XCTAssertEqual(store.config.version, 14)
        store.useRelease(remote)
        XCTAssertEqual(store.config.version, 14)
    }

    func testBadCalendarDoesNotActivateHalfARelease() throws {
        let container = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: container) }
        let phrases = try JSONEncoder().encode([Phrase.fallback])
        let calendar = try JSONEncoder().encode(CalendarConfig(version: 13, festivals: [], solarTerms: [:]))
        let meta = makeMeta(version: 13, phrases: phrases, calendar: calendar)
        try CorpusReleaseStorage.saveRelease(phrasesData: phrases, calendarData: calendar, meta: meta, container: container)

        let bad = Data("{}".utf8)
        let newerMeta = makeMeta(version: 14, phrases: phrases, calendar: bad)
        XCTAssertThrowsError(try CorpusReleaseStorage.saveRelease(
            phrasesData: phrases, calendarData: bad, meta: newerMeta, container: container
        ))
        XCTAssertEqual(CorpusReleaseStorage.loadActiveRelease(container: container)?.meta.releaseVersion, 13)
        XCTAssertEqual(CorpusReleaseStorage.loadActiveRelease(container: container)?.phrases, [Phrase.fallback])
    }

    func testTamperedCacheIsRejectedOnRead() throws {
        let container = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: container) }
        let phrases = try JSONEncoder().encode([Phrase.fallback])
        let calendar = try JSONEncoder().encode(CalendarConfig(version: 13, festivals: [], solarTerms: [:]))
        try CorpusReleaseStorage.saveRelease(
            phrasesData: phrases, calendarData: calendar,
            meta: makeMeta(version: 13, phrases: phrases, calendar: calendar), container: container
        )
        let target = container.appendingPathComponent("Library/Application Support/corpus/releases/v13/phrases.json")
        try JSONEncoder().encode([Phrase.firstInstallGreeting]).write(to: target)
        XCTAssertNil(CorpusReleaseStorage.loadActiveRelease(container: container))
    }

    func testVersionMismatchAndChecksumMismatchKeepPreviousRelease() throws {
        let container = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: container) }
        let phrases = try JSONEncoder().encode([Phrase.fallback])
        let calendar = try JSONEncoder().encode(CalendarConfig(version: 13, festivals: [], solarTerms: [:]))
        let meta = makeMeta(version: 13, phrases: phrases, calendar: calendar)
        try CorpusReleaseStorage.saveRelease(phrasesData: phrases, calendarData: calendar, meta: meta, container: container)
        let newerMeta = makeMeta(version: 14, phrases: phrases, calendar: calendar)
        XCTAssertThrowsError(try CorpusReleaseStorage.saveRelease(
            phrasesData: phrases, calendarData: calendar, meta: newerMeta, container: container
        ))
        XCTAssertThrowsError(try CorpusReleaseStorage.saveRelease(
            phrasesData: Data("[]".utf8), calendarData: calendar, meta: meta, container: container
        ))
        XCTAssertEqual(CorpusReleaseStorage.loadActiveRelease(container: container)?.meta.releaseVersion, 13)
    }

    func testCalendarValidationRejectsWrongTimezoneAndInvalidDate() {
        XCTAssertFalse(CalendarConfig(version: 13, timezone: "UTC", festivals: [], solarTerms: [:]).isValid)
        XCTAssertFalse(CalendarConfig.isValidDateToken("02-30"))
        XCTAssertTrue(CalendarConfig.isValidDateToken("02-29"))
        XCTAssertFalse(CalendarConfig.isValidDateToken("2026-02-29"))
    }

    private func makeMeta(version: Int, phrases: Data, calendar: Data) -> CorpusReleaseMeta {
        CorpusReleaseMeta(
            releaseVersion: version, generatedAt: "2026-10-10T00:00:00Z", phraseCount: 1,
            phrasesSHA256: CorpusReleaseStorage.sha256(phrases),
            calendarSHA256: CorpusReleaseStorage.sha256(calendar)
        )
    }
}
