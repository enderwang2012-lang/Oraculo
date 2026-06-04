import Foundation

/// 加载语料（App Group 热更新缓存 → Bundle 兜底），并向 App Group 同步「今日一句」供 Widget 读取。
final class PhraseStore {
    static let shared = PhraseStore()

    private(set) var phrases: [Phrase] = []
    private(set) var activeCorpusVersion: Int = 0

    var phraseCount: Int { phrases.count }
    private let calendar = Calendar.current

    private init() {
        reloadFromDisk()
    }

    /// 热更新成功后调用，主 App 与 Widget 下次读盘即生效。
    func reloadFromDisk() {
        let loaded = Self.loadEffectivePhrases()
        phrases = loaded.phrases
        activeCorpusVersion = loaded.corpusVersion
    }

    private static func loadEffectivePhrases() -> (phrases: [Phrase], corpusVersion: Int) {
        if let cached = PhraseCorpusStorage.loadCachedPhrases(), !cached.isEmpty {
            let version = PhraseCorpusStorage.loadAppliedVersion()
            return (cached, version)
        }
        let bundled = loadBundledPhrases()
        let version = CorpusBundledMeta.load()?.corpusVersion ?? 0
        return (bundled, version)
    }

    static func loadBundledPhrases() -> [Phrase] {
        if let decoded = loadPhrases(from: .main), !decoded.isEmpty {
            return decoded
        }
        return [Phrase.fallback]
    }

    private static func jsonURL(in bundle: Bundle, name: String) -> URL? {
        if let url = bundle.url(forResource: name, withExtension: "json") {
            return url
        }
        return bundle.url(forResource: name, withExtension: "json", subdirectory: "Resources")
    }

    /// 与 Widget 扩展共用：优先用主 bundle，Widget 里 Bundle.main 指向 extension 时需把 JSON 打进两处 target。
    static func loadPhrases(from bundle: Bundle) -> [Phrase]? {
        guard let url = jsonURL(in: bundle, name: AppConstants.phrasesResourceName),
              let data = try? Data(contentsOf: url)
        else {
            return nil
        }
        return PhraseCorpusStorage.decodePhrases(from: data)
    }

    func phrase(for date: Date = Date()) -> Phrase {
        contextualPhrase(for: date, seedSuffix: nil, excluding: nil)
    }

    /// Widget / 今日一句：日种子 + 情境指纹，与摇一摇共用打分。
    func contextualPhrase(
        for date: Date = Date(),
        seedSuffix: String? = nil,
        excluding: Phrase? = nil
    ) -> Phrase {
        guard !phrases.isEmpty else {
            return Phrase.fallback
        }
        let context = ContextSnapshotBuilder.snapshot(for: date, calendar: calendar)
        let dayKey = Self.dayKey(for: date, calendar: calendar)
        // 末尾混入 InstallID：同日同情境的不同用户拿到不同句子（B 方案——"集合变小"靠标签控制，
        // 集合内的"哪一句"靠用户切片）。InstallID 放最后，便于 grep 调试。
        var seed = "\(dayKey)|\(context.selectionFingerprint)|\(InstallID.value)"
        if let seedSuffix, !seedSuffix.isEmpty {
            seed += "|\(seedSuffix)"
        }
        return PhrasePicker.pick(from: phrases, context: context, seed: seed, excluding: excluding)
    }

    func syncTodayToSharedDefaults(date: Date = Date()) {
        let phrase = phrase(for: date)
        let key = Self.dayKey(for: date, calendar: calendar)
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupID) else { return }
        defaults.set(phrase.text, forKey: AppConstants.sharedTodayPhraseKey)
        defaults.set(phrase.id, forKey: AppConstants.sharedTodayPhraseIDKey)
        defaults.set(key, forKey: AppConstants.sharedTodayDayKeyKey)
        defaults.set(activeCorpusVersion, forKey: AppConstants.sharedCorpusVersionKey)
    }

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let start = calendar.startOfDay(for: date)
        let y = calendar.component(.year, from: start)
        let m = calendar.component(.month, from: start)
        let d = calendar.component(.day, from: start)
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    /// FNV-1a 风格稳定哈希，避免 `hashValue` 跨版本漂移。
    static func stableIndex(for dayKey: String, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return Int(stableHash64(for: dayKey) % UInt64(count))
    }

    static func stableHash64(for string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        let prime: UInt64 = 0x100000001b3
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= prime
        }
        return hash
    }
}
