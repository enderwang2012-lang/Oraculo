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
        return DailyOracle(
            dayKey: key,
            phrase: phrases.phrase(for: date),
            nipponColor: colors.color(for: date)
        )
    }

    func refreshSharedCache(date: Date = Date()) {
        let o = oracle(for: date)
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupID) else { return }
        defaults.set(o.phrase.text, forKey: AppConstants.sharedTodayPhraseKey)
        defaults.set(o.phrase.id, forKey: AppConstants.sharedTodayPhraseIDKey)
        defaults.set(o.dayKey, forKey: AppConstants.sharedTodayDayKeyKey)
        defaults.set(o.nipponColor.hex, forKey: AppConstants.sharedTodayColorHexKey)
        defaults.set(o.nipponColor.cname, forKey: AppConstants.sharedTodayColorCnameKey)
        defaults.set(o.nipponColor.name, forKey: AppConstants.sharedTodayColorNameKey)
        defaults.set(o.nipponColor.foreground, forKey: AppConstants.sharedTodayColorForegroundKey)
    }
}
