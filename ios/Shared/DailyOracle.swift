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

    /// Widget 优先读主 App 已同步的展示；未打开过 App 时返回 nil，由 Widget 自行推算。
    func loadDisplayedSnapshot(for date: Date = Date()) -> DisplayedOracleSnapshot? {
        let dayKey = PhraseStore.dayKey(for: date)
        guard let shared = SharedOracleMomentStore.shared.load(),
              shared.dayKey == dayKey
        else { return nil }

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
