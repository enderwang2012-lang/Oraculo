import Foundation
import XCTest
@testable import OraculoCore

final class DateBindingTests: XCTestCase {
    func testExclusiveDateBindingNarrowsTheCandidatePool() {
        let ordinary = Phrase(
            id: "ordinary",
            text: "通用",
            layer: "active",
            emotionTheme: "daily_romance",
            dispatch: PhraseDispatch(
                universal: true,
                onlyWhen: [],
                boost: [],
                dateBinding: nil
            )
        )
        let exclusive = Phrase(
            id: "exclusive",
            text: "年末",
            layer: "active",
            emotionTheme: "daily_romance",
            dispatch: PhraseDispatch(
                universal: true,
                onlyWhen: [],
                boost: [],
                dateBinding: PhraseDateBinding(
                    mode: .exclusive,
                    rules: ["month_day:12-31"],
                    priority: 100
                )
            )
        )

        let pool = PhraseDateBindingSelector.candidatePool(
            from: [ordinary, exclusive],
            activeTags: ["month_day:12-31"]
        )

        XCTAssertEqual(pool.map(\.id), ["exclusive"])
    }

    func testNonMatchingExclusiveBindingDoesNotRemoveOrdinaryPool() {
        let ordinary = Phrase(
            id: "ordinary",
            text: "通用",
            layer: "active",
            emotionTheme: "daily_romance"
        )
        let exclusive = Phrase(
            id: "exclusive",
            text: "年末",
            layer: "active",
            emotionTheme: "daily_romance",
            dispatch: PhraseDispatch(
                universal: true,
                onlyWhen: [],
                boost: [],
                dateBinding: PhraseDateBinding(
                    mode: .exclusive,
                    rules: ["month_day:12-31"],
                    priority: 100
                )
            )
        )

        let pool = PhraseDateBindingSelector.candidatePool(
            from: [ordinary, exclusive],
            activeTags: ["month_day:12-30"]
        )

        XCTAssertEqual(pool.map(\.id), ["ordinary"])
    }

    func testExclusivePoolSurvivesRepeatExclusionAndFreshnessExhaustion() {
        let phrase = bound("year_end", tag: "month_day:12-31")
        let history = [
            PhraseExposure(
                phraseId: phrase.id, semanticCluster: phrase.freshness.semanticCluster,
                cadenceGroup: phrase.freshness.cadenceGroup, source: .dailyAuto,
                dayKey: "2026-12-31", shownAt: Date(), corpusVersion: 13
            )
        ]
        for seed in 0..<30 {
            let picked = PhrasePicker.pick(
                from: [Phrase.fallback, phrase], context: context("2026-12-31"),
                seed: String(seed), excluding: phrase, history: history
            )
            XCTAssertEqual(picked.id, phrase.id)
        }
    }

    func testExclusivePriorityAndOnlyWhenAreBothRespected() {
        let low = bound("low", tag: "month_day:12-31", priority: 10)
        let high = bound("high", tag: "month_day:12-31", priority: 100)
        let invalid = Phrase(
            id: "invalid", text: "invalid", layer: "active", emotionTheme: "daily_romance",
            dispatch: PhraseDispatch(
                universal: false, onlyWhen: ["season:summer"], boost: [],
                dateBinding: PhraseDateBinding(mode: .exclusive, rules: ["month_day:12-31"], priority: 999)
            )
        )
        XCTAssertEqual(PhrasePicker.pick(
            from: [low, high, invalid, .fallback], context: context("2026-12-31"), seed: "date", excluding: nil
        ).id, "high")
    }

    func testHardDateGatesSurviveFallback() {
        let phrase = bound("year_end", tag: "month_day:12-31")
        for seed in 0..<30 {
            XCTAssertEqual(PhrasePicker.pick(
                from: [phrase, .fallback], context: context("2027-01-01"), seed: String(seed), excluding: nil
            ).id, Phrase.fallback.id)
        }
    }

    func testBoostBindingIncreasesWeightWithoutExcludingOrdinaryPool() {
        let phrase = Phrase(
            id: "boost", text: "boost", layer: "active", emotionTheme: "daily_romance",
            dispatch: PhraseDispatch(universal: true, onlyWhen: [], boost: [],
                dateBinding: PhraseDateBinding(mode: .boost, rules: ["month_day:12-31"]))
        )
        XCTAssertGreaterThan(PhraseDispatchScorer.score(phrase: phrase, context: context("2026-12-31")),
                             PhraseDispatchScorer.score(phrase: phrase, context: context("2026-12-30")))
        XCTAssertEqual(PhraseDateBindingSelector.candidatePool(
            from: [phrase, .fallback], activeTags: ["month_day:12-31"]
        ).count, 2)
    }

    private func bound(_ id: String, tag: String, priority: Int = 100) -> Phrase {
        Phrase(id: id, text: id, layer: "active", emotionTheme: "daily_romance",
               dispatch: PhraseDispatch(universal: false, onlyWhen: [tag], boost: [],
                   dateBinding: PhraseDateBinding(mode: .exclusive, rules: [tag], priority: priority)))
    }

    private func context(_ day: String) -> ContextSnapshot {
        ContextSnapshot(
            dayKey: day, season: "winter", month: Int(day.dropFirst(5).prefix(2))!,
            weekday: 1, dayPart: "noon", festivals: ["new_year"], weather: nil, tempBand: nil,
            solarTerm: nil, geoRegion: "", altitudeBand: "", geoCell: nil, locationSource: "", localeID: ""
        )
    }
}
