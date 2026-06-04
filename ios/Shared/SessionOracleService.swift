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
        var nippon = pickColor(from: colorList, excluding: current?.nipponColor)

        if let current {
            var attempts = 0
            while phrase.id == current.phrase.id,
                  nippon.hex == current.nipponColor.hex,
                  attempts < 16 {
                let retryNonce = UUID().uuidString
                phrase = phrases.contextualPhrase(
                    for: Date(),
                    seedSuffix: "shake|\(retryNonce)",
                    excluding: current.phrase
                )
                nippon = pickColor(from: colorList, excluding: current.nipponColor)
                attempts += 1
            }
        }

        return OracleMoment(phrase: phrase, nipponColor: nippon, dayKey: dayKey)
    }

    private func pickColor(from list: [NipponColor], excluding: NipponColor?) -> NipponColor {
        guard !list.isEmpty else {
            return NipponColor(id: "011", name: "nakabeni", cname: "中紅", hex: "DB4D6D", foreground: "light")
        }
        if list.count == 1 { return list[0] }
        let pool = list.filter { $0.hex != excluding?.hex }
        return (pool.isEmpty ? list : pool).randomElement()!
    }
}
