import Foundation

/// 每次打开 App 时随机抽取短句 + 色（小组件仍用每日固定逻辑）。
struct SessionOracleService {
    private let daily = DailyOracleService()
    private let phrases = PhraseStore.shared
    private let colors = NipponColorStore.shared

    /// 冷启动首帧：与 Widget 一致的「今日」。
    func todayBaseline() -> OracleMoment {
        let o = daily.oracle()
        return OracleMoment(phrase: o.phrase, nipponColor: o.nipponColor, dayKey: o.dayKey)
    }

    func randomMoment(excluding current: OracleMoment?) -> OracleMoment {
        let colorList = colors.colors
        let dayKey = PhraseStore.dayKey(for: Date())
        let shakeNonce = UUID().uuidString

        var phrase = phrases.contextualPhrase(
            for: Date(),
            seedSuffix: "shake|\(shakeNonce)",
            excluding: current?.phrase
        )
        var nippon = pickColor(
            from: colorList,
            phrase: phrase,
            excluding: current?.nipponColor
        )

        if let current {
            var attempts = 0
            // 保证至少一项变化：句 *或* 色与上次不同。
            // 之前用 AND 会让「同句换色」直接通过，违背「换一句、换一色」的承诺。
            while (phrase.id == current.phrase.id || nippon.hex == current.nipponColor.hex),
                  attempts < 16 {
                let retryNonce = UUID().uuidString
                phrase = phrases.contextualPhrase(
                    for: Date(),
                    seedSuffix: "shake|\(retryNonce)",
                    excluding: current.phrase
                )
                nippon = pickColor(
                    from: colorList,
                    phrase: phrase,
                    excluding: current.nipponColor
                )
                attempts += 1
            }
        }

        return OracleMoment(phrase: phrase, nipponColor: nippon, dayKey: dayKey)
    }

    /// 摇一摇用：先按句的 colorMoods/colorBan 收窄候选池，再排除上次色，最后均匀随机。
    /// 与每日选色不同——这里不用 InstallID 切片，每次都要变（这是摇一摇的本质）。
    private func pickColor(
        from list: [NipponColor],
        phrase: Phrase,
        excluding: NipponColor?
    ) -> NipponColor {
        guard !list.isEmpty else { return NipponColor.fallback }
        if list.count == 1 { return list[0] }

        let moodPool = ColorMoodPicker.candidatePool(from: list, dispatch: phrase.dispatch)
        let pool = moodPool.filter { $0.hex != excluding?.hex }
        let final = pool.isEmpty ? moodPool : pool

        // 在 mood 池里仍按 colorMoods 加权倾向（摇一摇也要尊重情绪倾向）。
        if let moods = phrase.dispatch?.colorMoods, !moods.isEmpty {
            let moodSet = Set(moods)
            let preferred = final.filter { c in c.moods.contains(where: { moodSet.contains($0) }) }
            // 70% 概率从偏好色里抽，30% 从整池抽——保留 248 色丰富感
            if !preferred.isEmpty, Double.random(in: 0 ..< 1) < 0.7 {
                return preferred.randomElement()!
            }
        }
        return final.randomElement()!
    }
}
