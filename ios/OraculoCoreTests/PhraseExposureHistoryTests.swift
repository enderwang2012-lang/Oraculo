import Foundation
import XCTest
@testable import OraculoCore

final class PhraseExposureHistoryTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var history: PhraseExposureHistory!

    override func setUp() {
        super.setUp()
        suiteName = "PhraseExposureHistoryTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        history = PhraseExposureHistory(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        history = nil
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testConsecutiveLifecycleSyncOfSameDisplayIsRecordedOnce() {
        let phrase = makePhrase(id: "same")
        let first = Date(timeIntervalSince1970: 1_800_000_000)
        let second = first.addingTimeInterval(30)

        history.record(
            phrase: phrase,
            source: .appInteraction,
            dayKey: "2027-01-15",
            corpusVersion: 6,
            shownAt: first
        )
        history.record(
            phrase: phrase,
            source: .appInteraction,
            dayKey: "2027-01-15",
            corpusVersion: 6,
            shownAt: second
        )

        let entries = history.load(now: second)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.shownAt, first)
    }

    func testSamePhraseCanBeRecordedAgainAfterAnotherDisplay() {
        let phraseA = makePhrase(id: "a")
        let phraseB = makePhrase(id: "b")
        let start = Date(timeIntervalSince1970: 1_800_000_000)

        history.record(
            phrase: phraseA,
            source: .appInteraction,
            dayKey: "2027-01-15",
            corpusVersion: 6,
            shownAt: start
        )
        history.record(
            phrase: phraseB,
            source: .appInteraction,
            dayKey: "2027-01-15",
            corpusVersion: 6,
            shownAt: start.addingTimeInterval(30)
        )
        history.record(
            phrase: phraseA,
            source: .appInteraction,
            dayKey: "2027-01-15",
            corpusVersion: 6,
            shownAt: start.addingTimeInterval(60)
        )

        XCTAssertEqual(
            history.load(now: start.addingTimeInterval(60)).map(\.phraseId),
            ["a", "b", "a"]
        )
    }

    private func makePhrase(id: String) -> Phrase {
        Phrase(
            id: id,
            text: id,
            layer: "anchor",
            emotionTheme: "light_comfort",
            freshness: PhraseFreshness(
                semanticCluster: "cluster-\(id)",
                cadenceGroup: "cadence-\(id)",
                lifecycle: "active"
            )
        )
    }
}
