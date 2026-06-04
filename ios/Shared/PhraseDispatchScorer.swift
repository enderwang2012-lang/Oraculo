import Foundation

/// 与 Widget、摇一摇共用的权重计算。
enum PhraseDispatchScorer {
    static let universalBaseWeight = 1.0
    static let nonUniversalBaseWeight = 0.6
    static let negativeMultiplier = 0.12

    static func score(phrase: Phrase, context: ContextSnapshot) -> Double {
        let dispatch = phrase.dispatch ?? .fallback
        let active = context.activeTags

        if !dispatch.onlyWhen.isEmpty {
            let matched = dispatch.onlyWhen.contains { active.contains($0) }
            if !matched { return 0 }
        }

        var weight = dispatch.universal ? universalBaseWeight : nonUniversalBaseWeight

        for boost in dispatch.boost where active.contains(boost.tag) {
            weight += boost.weight
        }

        if let negatives = dispatch.negative {
            for tag in negatives where active.contains(tag) {
                weight *= negativeMultiplier
            }
        }

        return max(0, weight)
    }
}
