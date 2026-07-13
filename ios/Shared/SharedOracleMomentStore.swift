import Foundation

struct SharedOracleMoment: Codable, Equatable {
    let phraseId: String
    let phraseText: String
    let phraseTextEn: String
    let colorHex: String
    let colorName: String
    let colorCname: String
    let colorForeground: String
    let colorFamily: String
    let colorTextMode: String?
    let dayKey: String
    let shownAt: Date
    let source: PhraseSelectionSource
    let corpusVersion: Int
}

final class SharedOracleMomentStore {
    static let shared = SharedOracleMomentStore()

    private let defaults: UserDefaults?
    private let key = AppConstants.sharedCurrentMomentKey
    private let scheduledKey = AppConstants.sharedScheduledMomentsKey

    init(defaults: UserDefaults? = UserDefaults(suiteName: AppConstants.appGroupID)) {
        self.defaults = defaults
    }

    func load() -> SharedOracleMoment? {
        guard let data = defaults?.data(forKey: key) else {
            return loadLegacySnapshot()
        }
        return try? JSONDecoder().decode(SharedOracleMoment.self, from: data)
    }

    func save(
        moment: OracleMoment,
        source: PhraseSelectionSource,
        corpusVersion: Int,
        shownAt: Date = Date(),
        recordExposure: Bool = false,
        reloadWidgets: Bool = true
    ) {
        let shared = makeSharedMoment(
            moment: moment,
            source: source,
            corpusVersion: corpusVersion,
            shownAt: shownAt
        )
        save(shared)
        if recordExposure {
            PhraseExposureHistory.shared.record(
                phrase: moment.phrase,
                source: source,
                dayKey: moment.dayKey,
                corpusVersion: corpusVersion,
                shownAt: shownAt
            )
        }
        if reloadWidgets {
            WidgetTimelineRefresher.reloadAllIfPossible()
        }
    }

    func loadScheduled(forDayKey dayKey: String) -> SharedOracleMoment? {
        loadScheduledMoments()[dayKey]
    }

    /// Future Widget entries are generated ahead of time, so persist their exact display state now.
    func saveScheduled(
        moment: OracleMoment,
        source: PhraseSelectionSource,
        corpusVersion: Int,
        shownAt: Date
    ) {
        var moments = loadScheduledMoments()
        moments[moment.dayKey] = makeSharedMoment(
            moment: moment,
            source: source,
            corpusVersion: corpusVersion,
            shownAt: shownAt
        )

        let retained = moments.sorted { $0.key < $1.key }.suffix(32)
        let pruned = Dictionary(uniqueKeysWithValues: retained.map { ($0.key, $0.value) })
        guard let data = try? JSONEncoder().encode(pruned) else { return }
        defaults?.set(data, forKey: scheduledKey)
        defaults?.synchronize()
    }

    func save(_ shared: SharedOracleMoment) {
        guard let data = try? JSONEncoder().encode(shared) else { return }
        defaults?.set(data, forKey: key)
        saveLegacyKeys(shared)
        defaults?.synchronize()
    }

    private func saveLegacyKeys(_ shared: SharedOracleMoment) {
        defaults?.set(shared.phraseText, forKey: AppConstants.sharedTodayPhraseKey)
        defaults?.set(shared.phraseTextEn, forKey: AppConstants.sharedTodayPhraseTextEnKey)
        defaults?.set(shared.phraseId, forKey: AppConstants.sharedTodayPhraseIDKey)
        defaults?.set(shared.dayKey, forKey: AppConstants.sharedTodayDayKeyKey)
        defaults?.set(shared.colorHex, forKey: AppConstants.sharedTodayColorHexKey)
        defaults?.set(shared.colorCname, forKey: AppConstants.sharedTodayColorCnameKey)
        defaults?.set(shared.colorName, forKey: AppConstants.sharedTodayColorNameKey)
        defaults?.set(shared.colorForeground, forKey: AppConstants.sharedTodayColorForegroundKey)
        defaults?.set(shared.colorFamily, forKey: AppConstants.sharedTodayColorFamilyKey)
        defaults?.set(shared.colorTextMode, forKey: AppConstants.sharedTodayColorTextModeKey)
    }

    private func loadScheduledMoments() -> [String: SharedOracleMoment] {
        guard let data = defaults?.data(forKey: scheduledKey),
              let moments = try? JSONDecoder().decode([String: SharedOracleMoment].self, from: data)
        else { return [:] }
        return moments
    }

    private func makeSharedMoment(
        moment: OracleMoment,
        source: PhraseSelectionSource,
        corpusVersion: Int,
        shownAt: Date
    ) -> SharedOracleMoment {
        SharedOracleMoment(
            phraseId: moment.phrase.id,
            phraseText: moment.phrase.text,
            phraseTextEn: moment.phrase.textEn,
            colorHex: moment.nipponColor.hex,
            colorName: moment.nipponColor.name,
            colorCname: moment.nipponColor.cname,
            colorForeground: moment.nipponColor.foreground,
            colorFamily: moment.nipponColor.family,
            colorTextMode: moment.nipponColor.textMode?.rawValue,
            dayKey: moment.dayKey,
            shownAt: shownAt,
            source: source,
            corpusVersion: corpusVersion
        )
    }

    private func loadLegacySnapshot() -> SharedOracleMoment? {
        guard let defaults,
              let phraseText = defaults.string(forKey: AppConstants.sharedTodayPhraseKey),
              !phraseText.isEmpty,
              let colorHex = defaults.string(forKey: AppConstants.sharedTodayColorHexKey),
              !colorHex.isEmpty
        else { return nil }

        return SharedOracleMoment(
            phraseId: defaults.string(forKey: AppConstants.sharedTodayPhraseIDKey) ?? "",
            phraseText: phraseText,
            phraseTextEn: defaults.string(forKey: AppConstants.sharedTodayPhraseTextEnKey) ?? "",
            colorHex: colorHex,
            colorName: defaults.string(forKey: AppConstants.sharedTodayColorNameKey) ?? "",
            colorCname: defaults.string(forKey: AppConstants.sharedTodayColorCnameKey) ?? "",
            colorForeground: defaults.string(forKey: AppConstants.sharedTodayColorForegroundKey) ?? "dark",
            colorFamily: defaults.string(forKey: AppConstants.sharedTodayColorFamilyKey) ?? "",
            colorTextMode: defaults.string(forKey: AppConstants.sharedTodayColorTextModeKey),
            dayKey: defaults.string(forKey: AppConstants.sharedTodayDayKeyKey) ?? PhraseStore.dayKey(for: Date()),
            shownAt: Date.distantPast,
            source: .fallback,
            corpusVersion: defaults.integer(forKey: AppConstants.sharedCorpusVersionKey)
        )
    }
}
