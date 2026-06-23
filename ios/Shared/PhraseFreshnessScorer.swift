import Foundation

enum PhraseFreshnessScorer {
    static func score(
        phrase: Phrase,
        history: [PhraseExposure],
        source: PhraseSelectionSource,
        now: Date,
        corpusVersion: Int
    ) -> Double {
        let item = itemFreshness(phrase: phrase, history: history, now: now)
        if item == 0 { return 0 }
        return item
            * clusterFreshness(phrase: phrase, history: history, source: source, now: now)
            * cadenceFreshness(phrase: phrase, history: history, source: source)
            * lifecycleBoost(phrase: phrase)
            * unseenCorpusBoost(phrase: phrase, history: history, corpusVersion: corpusVersion)
    }

    private static func itemFreshness(
        phrase: Phrase,
        history: [PhraseExposure],
        now: Date
    ) -> Double {
        guard let last = history.last(where: { $0.phraseId == phrase.id }) else { return 1.0 }
        let age = now.timeIntervalSince(last.shownAt)
        if age < 7 * 24 * 60 * 60 { return 0 }
        if age < 30 * 24 * 60 * 60 { return 0.65 }
        return 1.0
    }

    private static func clusterFreshness(
        phrase: Phrase,
        history: [PhraseExposure],
        source: PhraseSelectionSource,
        now: Date
    ) -> Double {
        let cluster = phrase.freshness.semanticCluster
        let recentThree = history.suffix(3).contains { $0.semanticCluster == cluster }
        if recentThree {
            return source == .dailyAuto ? 0.5 : 0.35
        }

        let dayAgo = now.addingTimeInterval(-24 * 60 * 60)
        let weekAgo = now.addingTimeInterval(-7 * 24 * 60 * 60)
        let dayCount = history.filter { $0.shownAt >= dayAgo && $0.semanticCluster == cluster }.count
        let weekCount = history.filter { $0.shownAt >= weekAgo && $0.semanticCluster == cluster }.count

        if dayCount >= 2 { return source == .dailyAuto ? 0.65 : 0.5 }
        if weekCount >= 5 { return 0.75 }
        return 1.0
    }

    private static func cadenceFreshness(
        phrase: Phrase,
        history: [PhraseExposure],
        source: PhraseSelectionSource
    ) -> Double {
        let cadence = phrase.freshness.cadenceGroup
        if history.last?.cadenceGroup == cadence {
            return source == .dailyAuto ? 0.7 : 0.45
        }
        let recentFiveCount = history.suffix(5).filter { $0.cadenceGroup == cadence }.count
        if recentFiveCount >= 3 {
            return source == .dailyAuto ? 0.85 : 0.7
        }
        return 1.0
    }

    private static func lifecycleBoost(phrase: Phrase) -> Double {
        switch phrase.freshness.lifecycle {
        case "new":
            return 1.18
        case "anchor":
            return 1.05
        case "cooling":
            return 0.65
        case "retired":
            return 0
        default:
            return 1.0
        }
    }

    private static func unseenCorpusBoost(
        phrase: Phrase,
        history: [PhraseExposure],
        corpusVersion: Int
    ) -> Double {
        guard !history.contains(where: { $0.phraseId == phrase.id }) else { return 1.0 }
        guard corpusVersion > 0 else { return 1.08 }
        let seenCurrentVersion = history.contains { $0.corpusVersion == corpusVersion }
        return seenCurrentVersion ? 1.18 : 1.08
    }
}
