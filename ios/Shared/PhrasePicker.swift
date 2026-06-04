import Foundation

/// 情境加权随机选句；种子不同可复现（Widget 日固定 / 摇一摇每次变）。
enum PhrasePicker {
    static func pick(
        from phrases: [Phrase],
        context: ContextSnapshot,
        seed: String,
        excluding: Phrase?
    ) -> Phrase {
        let pool = phrases.filter { $0.id != excluding?.id }
        guard !pool.isEmpty else {
            return excluding ?? fallbackPhrase
        }

        var weighted: [(phrase: Phrase, weight: Double)] = []
        for phrase in pool {
            let w = PhraseDispatchScorer.score(phrase: phrase, context: context)
            if w > 0 {
                weighted.append((phrase, w))
            }
        }

        if weighted.isEmpty {
            let universalPool = pool.filter { ($0.dispatch ?? .fallback).universal }
            if let phrase = universalPool.randomElement() ?? pool.randomElement() {
                return phrase
            }
            return fallbackPhrase
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
        let hash = PhraseStore.stableHash64(for: seed)
        return Double(hash % 1_000_000) / 1_000_000.0
    }

    private static let fallbackPhrase = Phrase(
        id: "fallback",
        text: "先缓一缓",
        textEn: "Pause, and soften",
        layer: "anchor",
        emotionTheme: "light_comfort"
    )
}
