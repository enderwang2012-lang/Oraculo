import Foundation

/// 情境加权随机选句；种子不同可复现（Widget 日固定 / 摇一摇每次变）。
enum PhrasePicker {
    static func pick(
        from phrases: [Phrase],
        context: ContextSnapshot,
        seed: String,
        excluding: Phrase?,
        source: PhraseSelectionSource = .appInteraction,
        history: [PhraseExposure] = [],
        now: Date = Date(),
        corpusVersion: Int = 0
    ) -> Phrase {
        // Date eligibility takes precedence over repeat avoidance.
        let datePool = PhraseDateBindingSelector.candidatePool(
            from: phrases.filter { PhraseDispatchScorer.score(phrase: $0, context: context) > 0 },
            activeTags: context.activeTags
        )
        guard !datePool.isEmpty else { return Phrase.fallback }
        let withoutPrevious = datePool.filter { $0.id != excluding?.id }
        let pool = withoutPrevious.isEmpty ? datePool : withoutPrevious
        var weighted: [(phrase: Phrase, weight: Double)] = []
        for phrase in pool {
            let contextWeight = PhraseDispatchScorer.score(phrase: phrase, context: context)
            let freshnessWeight = PhraseFreshnessScorer.score(
                phrase: phrase,
                history: history,
                source: source,
                now: now,
                corpusVersion: corpusVersion
            )
            let w = contextWeight * freshnessWeight
            if w > 0 {
                weighted.append((phrase, w))
            }
        }

        if weighted.isEmpty {
            return pool[seededIndex(seed: seed, count: pool.count)]
        }

        let total = weighted.reduce(0) { $0 + $1.weight }
        var roll = seededUnit(seed) * total

        for entry in weighted {
            roll -= entry.weight
            if roll <= 0 {
                return entry.phrase
            }
        }
        return weighted.last!.phrase
    }

    static func seededUnit(_ seed: String) -> Double {
        let hash = StableSeed.hash64(for: seed)
        return Double(hash % 1_000_000) / 1_000_000.0
    }

    private static func seededIndex(seed: String, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return Int(StableSeed.hash64(for: seed) % UInt64(count))
    }

}
