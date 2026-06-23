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
        let now = Date()
        let dayKey = PhraseStore.dayKey(for: now)
        let shakeNonce = UUID().uuidString
        let context = ContextSnapshotBuilder.snapshot(for: now)

        var phrase = phrases.contextualPhrase(
            for: now,
            seedSuffix: "shake|\(shakeNonce)",
            excluding: current?.phrase,
            source: .appInteraction
        )
        var nippon = pickColor(
            from: colorList,
            phrase: phrase,
            excluding: current?.nipponColor,
            context: context
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
                    excluding: current.phrase,
                    source: .appInteraction
                )
                nippon = pickColor(
                    from: colorList,
                    phrase: phrase,
                    excluding: current.nipponColor,
                    context: context
                )
                attempts += 1
            }
        }

        return OracleMoment(phrase: phrase, nipponColor: nippon, dayKey: dayKey)
    }

    /// 摇一摇用：先按句的 colorMoods/colorBan 收窄候选池，再排除上次色，最后均匀随机。
    /// 与每日选色不同——这里不用 InstallID 切片，每次都要变（这是摇一摇的本质）。
    /// 传 context 时，偏好池并入「命中当日情境亲和」的色——摇出来的色也尽量应景。
    private func pickColor(
        from list: [NipponColor],
        phrase: Phrase,
        excluding: NipponColor?,
        context: ContextSnapshot? = nil
    ) -> NipponColor {
        guard !list.isEmpty else { return NipponColor.fallback }
        if list.count == 1 { return list[0] }

        let colorDispatch = phrase.effectiveColorDispatch
        let moodPool = ColorMoodPicker.candidatePool(from: list, dispatch: colorDispatch)
        let pool = moodPool.filter { $0.hex != excluding?.hex }
        let final = pool.isEmpty ? moodPool : pool

        // 偏好池 = 命中句情绪 ∪ 句色族 ∪ 当日情境的色（摇一摇也要尊重情绪倾向 + 应景）。
        let moodSet = Set(colorDispatch?.colorMoods ?? [])
        let familySet = Set(colorDispatch?.colorFamilies ?? [])
        let ctxTags = context?.activeTags ?? Set<String>()
        if !moodSet.isEmpty || !familySet.isEmpty || !ctxTags.isEmpty {
            let preferred = final.filter { c in
                (!moodSet.isEmpty && c.moods.contains(where: { moodSet.contains($0) }))
                    || (!familySet.isEmpty && familySet.contains(c.family))
                    || (!ctxTags.isEmpty && c.contextTags.contains(where: { ctxTags.contains($0) }))
            }
            // 70% 概率从偏好色里抽，30% 从整池抽——保留 248 色丰富感
            if !preferred.isEmpty, Double.random(in: 0 ..< 1) < 0.7 {
                return preferred.randomElement()!
            }
        }
        return final.randomElement()!
    }
}
