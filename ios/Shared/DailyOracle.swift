import Foundation

/// 某一天的完整呈现：一句短语 + 一种 Nippon 色。
struct DailyOracle: Equatable {
    let dayKey: String
    let phrase: Phrase
    let nipponColor: NipponColor
}

struct DailyOracleService {
    private let phrases = PhraseStore.shared
    private let colors = NipponColorStore.shared

    func oracle(for date: Date = Date()) -> DailyOracle {
        let key = PhraseStore.dayKey(for: date)
        // 先选句，再让色按句的 colorMoods/colorBan 收窄候选池，并叠加当日情境亲和。
        let context = ContextSnapshotBuilder.snapshot(for: date)
        let phrase = phrases.phrase(for: date)
        return DailyOracle(
            dayKey: key,
            phrase: phrase,
            nipponColor: colors.color(for: date, phrase: phrase, context: context)
        )
    }

    func refreshSharedCache(date: Date = Date()) {
        syncDisplayedMoment(
            oracle(for: date).asMoment,
            source: .dailyAuto,
            recordExposure: true
        )
    }

    /// 主 App 当前展示的一帧写入 App Group，供 Widget 与主屏同步。
    func syncDisplayedMoment(
        _ moment: OracleMoment,
        source: PhraseSelectionSource = .appInteraction,
        recordExposure: Bool = false,
        reloadWidgets: Bool = true
    ) {
        SharedOracleMomentStore.shared.save(
            moment: moment,
            source: source,
            corpusVersion: PhraseStore.shared.activeCorpusVersion,
            recordExposure: recordExposure,
            reloadWidgets: reloadWidgets
        )
    }

    /// Widget 优先读今天的 current moment；current 过期时恢复预生成的今日计划。
    func loadDisplayedSnapshot(for date: Date = Date()) -> DisplayedOracleSnapshot? {
        guard let shared = loadPreferredSharedMoment(for: date) else { return nil }

        let phraseTextEn = resolvePhraseTextEn(
            stored: shared.phraseTextEn,
            phraseID: shared.phraseId
        )
        return DisplayedOracleSnapshot(
            dayKey: shared.dayKey,
            phraseText: shared.phraseText,
            phraseTextEn: phraseTextEn,
            colorHex: shared.colorHex,
            usesLightText: shared.colorForeground == "light",
            colorFamily: shared.colorFamily,
            colorTextMode: shared.colorTextMode
        )
    }

    /// App 冷启动或回前台时恢复 Widget 当前显示的完整句色。
    func loadDisplayedMoment(for date: Date = Date()) -> OracleMoment? {
        guard let shared = loadPreferredSharedMoment(for: date) else { return nil }

        let catalogPhrase = phrases.phrases.first { $0.id == shared.phraseId }
            ?? phrases.phrases.first { $0.text == shared.phraseText }
        let phrase = Phrase(
            id: shared.phraseId.isEmpty
                ? catalogPhrase?.id ?? "shared-\(shared.dayKey)"
                : shared.phraseId,
            text: shared.phraseText,
            textEn: shared.phraseTextEn.isEmpty ? catalogPhrase?.textEn ?? "" : shared.phraseTextEn,
            layer: catalogPhrase?.layer ?? "shared",
            emotionTheme: catalogPhrase?.emotionTheme ?? "shared",
            dispatch: catalogPhrase?.dispatch,
            freshness: catalogPhrase?.freshness ?? .fallback
        )

        let color = colors.colors.first {
            $0.hex.caseInsensitiveCompare(shared.colorHex) == .orderedSame
        } ?? NipponColor(
            id: "shared-\(shared.colorHex)",
            name: shared.colorName,
            cname: shared.colorCname,
            hex: shared.colorHex,
            foreground: shared.colorForeground,
            family: shared.colorFamily,
            textMode: shared.colorTextMode.flatMap(NipponTextMode.init(rawValue:))
        )

        return OracleMoment(phrase: phrase, nipponColor: color, dayKey: shared.dayKey)
    }

    private func loadPreferredSharedMoment(for date: Date) -> SharedOracleMoment? {
        let dayKey = PhraseStore.dayKey(for: date)
        let current = SharedOracleMomentStore.shared.load()
        let scheduled = SharedOracleMomentStore.shared.loadScheduled(forDayKey: dayKey)

        switch SharedMomentSelectionPolicy.preferredSource(
            for: dayKey,
            currentDayKey: current?.dayKey,
            scheduledDayKey: scheduled?.dayKey
        ) {
        case .current:
            return current
        case .scheduled:
            return scheduled
        case .none:
            return nil
        }
    }
}

struct DisplayedOracleSnapshot: Equatable {
    let dayKey: String
    let phraseText: String
    let phraseTextEn: String
    let colorHex: String
    let usesLightText: Bool
    let colorFamily: String
    let colorTextMode: String?
}

private func resolvePhraseTextEn(stored: String?, phraseID: String?) -> String {
    if let stored, !stored.isEmpty { return stored }
    guard let phraseID,
          let phrase = PhraseStore.shared.phrases.first(where: { $0.id == phraseID })
    else { return "" }
    return phrase.textEn
}

private extension DailyOracle {
    var asMoment: OracleMoment {
        OracleMoment(phrase: phrase, nipponColor: nipponColor, dayKey: dayKey)
    }
}
