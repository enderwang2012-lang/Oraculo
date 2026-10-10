import CryptoKit
import Foundation

struct CorpusReleaseMeta: Codable, Equatable {
    let releaseVersion: Int
    let generatedAt: String
    let phraseCount: Int
    let phrasesSHA256: String
    let calendarSHA256: String
}

enum CorpusReleaseStorage {
    struct Release: Equatable {
        let meta: CorpusReleaseMeta
        let phrases: [Phrase]
        let calendar: CalendarConfig
    }

    private static let rootName = "corpus"
    private static let releasesName = "releases"
    private static let activeName = "active_release.json"

    static var appGroupContainer: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID)
    }

    static func loadActiveRelease(container: URL? = appGroupContainer) -> Release? {
        guard
            let activeURL = container?
                .appendingPathComponent("Library/Application Support", isDirectory: true)
                .appendingPathComponent(rootName, isDirectory: true)
                .appendingPathComponent(activeName),
            let activeData = try? Data(contentsOf: activeURL),
            let active = try? JSONDecoder().decode(ActiveRelease.self, from: activeData),
            let releaseDir = releaseDirectory(version: active.releaseVersion, container: container),
            let metaData = try? Data(contentsOf: releaseDir.appendingPathComponent("release_meta.json")),
            let meta = try? JSONDecoder().decode(CorpusReleaseMeta.self, from: metaData),
            let phrasesData = try? Data(contentsOf: releaseDir.appendingPathComponent("phrases.json")),
            let phrases = PhraseCorpusStorage.decodePhrases(from: phrasesData),
            let calendarData = try? Data(contentsOf: releaseDir.appendingPathComponent("calendar.json")),
            let calendar = try? JSONDecoder().decode(CalendarConfig.self, from: calendarData),
            meta.releaseVersion == active.releaseVersion,
            calendar.version == active.releaseVersion,
            isValid(phrasesData: phrasesData, calendarData: calendarData, meta: meta)
        else {
            return nil
        }
        return Release(meta: meta, phrases: phrases, calendar: calendar)
    }

    static func loadActiveCalendarConfig() -> CalendarConfig? {
        loadActiveRelease()?.calendar
    }

    static func saveRelease(
        phrasesData: Data,
        calendarData: Data,
        meta: CorpusReleaseMeta,
        container: URL? = appGroupContainer
    ) throws {
        guard let container else {
            throw CorpusUpdateError.appGroupUnavailable
        }
        guard isValid(phrasesData: phrasesData, calendarData: calendarData, meta: meta) else {
            throw CorpusUpdateError.checksumMismatch
        }

        let root = container
            .appendingPathComponent("Library/Application Support", isDirectory: true)
            .appendingPathComponent(rootName, isDirectory: true)
        let releases = root.appendingPathComponent(releasesName, isDirectory: true)
        let staging = releases.appendingPathComponent(".staging-\(UUID().uuidString)", isDirectory: true)
        let destination = releases.appendingPathComponent("v\(meta.releaseVersion)", isDirectory: true)
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: staging) }

        try phrasesData.write(to: staging.appendingPathComponent("phrases.json"), options: .atomic)
        try calendarData.write(to: staging.appendingPathComponent("calendar.json"), options: .atomic)
        try JSONEncoder().encode(meta).write(
            to: staging.appendingPathComponent("release_meta.json"),
            options: .atomic
        )

        if FileManager.default.fileExists(atPath: destination.path) {
            guard try loadReleaseMeta(from: destination) == meta,
                  try Data(contentsOf: destination.appendingPathComponent("phrases.json")) == phrasesData,
                  try Data(contentsOf: destination.appendingPathComponent("calendar.json")) == calendarData
            else {
                throw CorpusUpdateError.immutableAssetMismatch
            }
        } else {
            try FileManager.default.moveItem(at: staging, to: destination)
        }

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try JSONEncoder().encode(ActiveRelease(releaseVersion: meta.releaseVersion))
            .write(to: root.appendingPathComponent(activeName), options: .atomic)
    }

    private static func releaseDirectory(version: Int, container: URL?) -> URL? {
        container?
            .appendingPathComponent("Library/Application Support", isDirectory: true)
            .appendingPathComponent(rootName, isDirectory: true)
            .appendingPathComponent(releasesName, isDirectory: true)
            .appendingPathComponent("v\(version)", isDirectory: true)
    }

    private static func loadReleaseMeta(from directory: URL) throws -> CorpusReleaseMeta {
        let data = try Data(contentsOf: directory.appendingPathComponent("release_meta.json"))
        return try JSONDecoder().decode(CorpusReleaseMeta.self, from: data)
    }

    static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func isValid(phrasesData: Data, calendarData: Data, meta: CorpusReleaseMeta) -> Bool {
        guard meta.releaseVersion > 0,
              sha256(phrasesData) == meta.phrasesSHA256.lowercased(),
              sha256(calendarData) == meta.calendarSHA256.lowercased(),
              let phrases = PhraseCorpusStorage.decodePhrases(from: phrasesData),
              phrases.count == meta.phraseCount,
              Set(phrases.map(\.id)).count == phrases.count,
              let calendar = try? JSONDecoder().decode(CalendarConfig.self, from: calendarData),
              calendar.version == meta.releaseVersion,
              calendar.isValid
        else { return false }
        let festivals = Set(calendar.festivals.map(\.id))
        let terms = Set(calendar.solarTerms.values.flatMap { $0.map(\.id) })
        return phrases.allSatisfy { phrase in
            let dispatch = phrase.dispatch ?? .fallback
            if let binding = dispatch.dateBinding, binding.rules.isEmpty { return false }
            let tags = dispatch.onlyWhen + (dispatch.dateBinding?.rules ?? [])
            return tags.allSatisfy { tag in
                if tag.hasPrefix("festival:") { return festivals.contains(String(tag.dropFirst(9))) }
                if tag.hasPrefix("solar_term:") { return terms.contains(String(tag.dropFirst(11))) }
                if tag.hasPrefix("month_day:") {
                    return CalendarConfig.isValidDateToken(String(tag.dropFirst(10)))
                }
                return true
            }
        }
    }

    private struct ActiveRelease: Codable {
        let releaseVersion: Int
    }
}
