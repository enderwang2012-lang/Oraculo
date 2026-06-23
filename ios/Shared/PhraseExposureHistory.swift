import Foundation

struct PhraseExposure: Codable, Equatable, Hashable {
    let phraseId: String
    let semanticCluster: String
    let cadenceGroup: String
    let source: PhraseSelectionSource
    let dayKey: String
    let shownAt: Date
    let corpusVersion: Int
}

final class PhraseExposureHistory {
    static let shared = PhraseExposureHistory()

    private let maxEntries = 200
    private let maxAge: TimeInterval = 90 * 24 * 60 * 60
    private let defaults: UserDefaults?
    private let key = AppConstants.sharedPhraseExposureHistoryKey

    init(defaults: UserDefaults? = UserDefaults(suiteName: AppConstants.appGroupID)) {
        self.defaults = defaults
    }

    func load(now: Date = Date()) -> [PhraseExposure] {
        guard let data = defaults?.data(forKey: key),
              let decoded = try? JSONDecoder().decode([PhraseExposure].self, from: data)
        else { return [] }
        return trimmed(decoded, now: now)
    }

    func record(
        phrase: Phrase,
        source: PhraseSelectionSource,
        dayKey: String,
        corpusVersion: Int,
        shownAt: Date = Date()
    ) {
        let exposure = PhraseExposure(
            phraseId: phrase.id,
            semanticCluster: phrase.freshness.semanticCluster,
            cadenceGroup: phrase.freshness.cadenceGroup,
            source: source,
            dayKey: dayKey,
            shownAt: shownAt,
            corpusVersion: corpusVersion
        )
        var entries = load(now: shownAt)
        if entries.last == exposure { return }
        entries.append(exposure)
        save(trimmed(entries, now: shownAt))
    }

    func hasExposure(source: PhraseSelectionSource, dayKey: String) -> Bool {
        load().contains { $0.source == source && $0.dayKey == dayKey }
    }

    private func save(_ entries: [PhraseExposure]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults?.set(data, forKey: key)
    }

    private func trimmed(_ entries: [PhraseExposure], now: Date) -> [PhraseExposure] {
        let cutoff = now.addingTimeInterval(-maxAge)
        let recent = entries.filter { $0.shownAt >= cutoff }
            .sorted { $0.shownAt < $1.shownAt }
        if recent.count <= maxEntries { return recent }
        return Array(recent.suffix(maxEntries))
    }
}
