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
        syncDisplayedMoment(oracle(for: date).asMoment)
    }

    /// 主 App 当前展示的一帧写入 App Group，供 Widget 与主屏同步。
    func syncDisplayedMoment(_ moment: OracleMoment) {
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupID) else {
            #if DEBUG
            print("[Oraculo] Widget sync failed: App Group \(AppConstants.appGroupID) unavailable — check entitlements & Signing.")
            #endif
            return
        }
        defaults.set(moment.phrase.text, forKey: AppConstants.sharedTodayPhraseKey)
        defaults.set(moment.phrase.textEn, forKey: AppConstants.sharedTodayPhraseTextEnKey)
        defaults.set(moment.phrase.id, forKey: AppConstants.sharedTodayPhraseIDKey)
        defaults.set(moment.dayKey, forKey: AppConstants.sharedTodayDayKeyKey)
        defaults.set(moment.nipponColor.hex, forKey: AppConstants.sharedTodayColorHexKey)
        defaults.set(moment.nipponColor.cname, forKey: AppConstants.sharedTodayColorCnameKey)
        defaults.set(moment.nipponColor.name, forKey: AppConstants.sharedTodayColorNameKey)
        defaults.set(moment.nipponColor.foreground, forKey: AppConstants.sharedTodayColorForegroundKey)
        WidgetTimelineRefresher.reloadAllIfPossible()
    }

    /// Widget 优先读主 App 已同步的展示；未打开过 App 时返回 nil，由 Widget 自行推算。
    func loadDisplayedSnapshot(for date: Date = Date()) -> DisplayedOracleSnapshot? {
        let dayKey = PhraseStore.dayKey(for: date)
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupID),
              defaults.string(forKey: AppConstants.sharedTodayDayKeyKey) == dayKey,
              let phraseText = defaults.string(forKey: AppConstants.sharedTodayPhraseKey),
              !phraseText.isEmpty,
              let colorHex = defaults.string(forKey: AppConstants.sharedTodayColorHexKey),
              !colorHex.isEmpty
        else { return nil }

        let phraseID = defaults.string(forKey: AppConstants.sharedTodayPhraseIDKey)
        let phraseTextEn = resolvePhraseTextEn(
            stored: defaults.string(forKey: AppConstants.sharedTodayPhraseTextEnKey),
            phraseID: phraseID
        )
        let foreground = defaults.string(forKey: AppConstants.sharedTodayColorForegroundKey) ?? "dark"
        return DisplayedOracleSnapshot(
            dayKey: dayKey,
            phraseText: phraseText,
            phraseTextEn: phraseTextEn,
            colorHex: colorHex,
            usesLightText: foreground == "light"
        )
    }
}

struct DisplayedOracleSnapshot: Equatable {
    let dayKey: String
    let phraseText: String
    let phraseTextEn: String
    let colorHex: String
    let usesLightText: Bool
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
