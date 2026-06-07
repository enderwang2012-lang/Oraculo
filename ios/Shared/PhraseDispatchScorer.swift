import Foundation

/// 与 Widget、摇一摇共用的权重计算。
enum PhraseDispatchScorer {
    static let universalBaseWeight = 1.0
    static let nonUniversalBaseWeight = 0.6
    static let negativeMultiplier = 0.12

    /// 主题级节日硬门槛（与 `tag_phrases_rules.py` 的 FESTIVAL_EXCLUSIVE_THEMES 对齐）。
    private static let festivalExclusiveThemes: [String: String] = [
        "新年祝福": "festival:spring_festival",
        "长久祝福": "festival:spring_festival",
    ]

    /// 字面春节对仗祝福（主题可能不是「新年祝福」）。
    private static let festivalExclusiveTexts: Set<String> = [
        "岁岁常欢愉",
        "年年皆胜意",
    ]

    /// 长月份先匹配，避免「十一月」误命中「一月」。
    private static let monthMarkers: [(String, String)] = [
        ("十一月", "month:11"),
        ("十二月", "month:12"),
        ("一月", "month:1"),
        ("元月", "month:1"),
        ("二月", "month:2"),
        ("三月", "month:3"),
        ("四月", "month:4"),
        ("五月", "month:5"),
        ("六月", "month:6"),
        ("七月", "month:7"),
        ("八月", "month:8"),
        ("九月", "month:9"),
        ("十月", "month:10"),
        ("岁末", "month:12"),
    ]

    private static func monthExclusiveTag(for phrase: Phrase) -> String? {
        guard phrase.emotionTheme == "月份希望" else { return nil }
        for (marker, tag) in monthMarkers where phrase.text.contains(marker) {
            return tag
        }
        return nil
    }

    static func score(phrase: Phrase, context: ContextSnapshot) -> Double {
        let dispatch = phrase.dispatch ?? .fallback
        let active = context.activeTags

        var requiredTags = dispatch.onlyWhen
        if requiredTags.isEmpty {
            if festivalExclusiveTexts.contains(phrase.text),
               let tag = festivalExclusiveThemes["新年祝福"] {
                requiredTags = [tag]
            } else if let themeTag = festivalExclusiveThemes[phrase.emotionTheme] {
                requiredTags = [themeTag]
            } else if let monthTag = monthExclusiveTag(for: phrase) {
                requiredTags = [monthTag]
            }
        }

        if !requiredTags.isEmpty {
            let matched = requiredTags.contains { active.contains($0) }
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
