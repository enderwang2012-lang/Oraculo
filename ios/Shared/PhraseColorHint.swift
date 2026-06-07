import Foundation

/// 从句面字面颜色/意象推断色情绪约束，补足语料未标注 colorMoods 的缺口。
enum PhraseColorHint {
    struct Hint: Equatable {
        var moods: [String] = []
        var bans: [String] = []
    }

    /// 合并语料 dispatch 与句面推断；语料已标注的 colorMoods 优先，colorBan 取并集。
    static func mergedDispatch(
        base: PhraseDispatch?,
        text: String,
        textEn: String
    ) -> PhraseDispatch? {
        let inferred = infer(text: text, textEn: textEn)
        let hasBaseMoods = !(base?.colorMoods ?? []).isEmpty
        let hasBaseBans = !(base?.colorBan ?? []).isEmpty
        guard !inferred.moods.isEmpty || !inferred.bans.isEmpty || hasBaseMoods || hasBaseBans else {
            return base
        }

        var merged = base ?? .fallback
        if !hasBaseMoods, !inferred.moods.isEmpty {
            merged.colorMoods = inferred.moods
        }
        var bans = Set(merged.colorBan ?? [])
        bans.formUnion(inferred.bans)
        if !bans.isEmpty {
            merged.colorBan = Array(bans).sorted()
        }
        return merged
    }

    static func infer(text: String, textEn: String) -> Hint {
        var hint = Hint()
        let zh = text
        let en = textEn.lowercased()

        // 冷色 / 水象：蔚蓝、海、绿、青等
        if containsAny(in: zh, ["蔚蓝", "蓝天", "碧海", "海面", "大海", "星辰大海"])
            || containsAny(in: zh, ["翠", "绿茶", "青", "碧", "澄"])
            || (zh.contains("海") && !zh.contains("热爱"))
            || containsAny(in: en, ["azure", "blue", "ocean", "sea", "emerald", "teal", "aqua"]) {
            append(&hint.moods, "cool")
            append(&hint.bans, "warm")
        }

        // 暖色 / 火象
        if containsAny(in: zh, ["红", "绯", "赤", "橙", "焰", "烈", "艳阳", "暖阳", "热爱"])
            || containsAny(in: en, ["red", "crimson", "scarlet", "flame", "amber", "warm"]) {
            append(&hint.moods, "warm")
            append(&hint.bans, "cool")
        }

        // 深色 / 夜
        if containsAny(in: zh, ["夜", "黑", "暗", "深", "墨", "寂", "孤独"])
            || containsAny(in: en, ["night", "dark", "shadow", "midnight"]) {
            append(&hint.moods, "dark")
            append(&hint.bans, "light")
        }

        // 浅色 / 晴雪
        if containsAny(in: zh, ["雪", "白", "浅", "淡", "明", "晴空", "晴朗"])
            || containsAny(in: en, ["snow", "white", "pale", "bright", "clear sky"]) {
            append(&hint.moods, "light")
            append(&hint.bans, "dark")
        }

        return hint
    }

    private static func containsAny(in text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }

    private static func append(_ list: inout [String], _ value: String) {
        if !list.contains(value) { list.append(value) }
    }
}

extension Phrase {
    /// 选色用 dispatch：语料标注 + 句面颜色词推断。
    var effectiveColorDispatch: PhraseDispatch? {
        PhraseColorHint.mergedDispatch(base: dispatch, text: text, textEn: textEn)
    }
}
