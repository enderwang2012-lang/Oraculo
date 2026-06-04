import Foundation

/// 打进 App 的语料元数据（与远程 manifest 的 `corpusVersion` 对齐）。
struct CorpusBundledMeta: Codable, Equatable {
    let corpusVersion: Int
    let generatedAt: String
    let phraseCount: Int
    let phrasesSHA256: String

    static func load(from bundle: Bundle = .main) -> CorpusBundledMeta? {
        guard let url = bundle.url(forResource: "corpus_bundled_meta", withExtension: "json")
            ?? bundle.url(forResource: "corpus_bundled_meta", withExtension: "json", subdirectory: "Resources"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(CorpusBundledMeta.self, from: data)
        else { return nil }
        return decoded
    }
}

struct CorpusRemoteManifest: Codable, Equatable {
    struct Asset: Codable, Equatable {
        let url: String
        let sha256: String
    }

    let corpusVersion: Int
    let phrases: Asset
    let publishedAt: String?
    let minAppVersion: String?
    let releaseNotes: String?
}

enum PhraseCorpusStorage {
    private static let corpusDirectoryName = "corpus"
    private static let phrasesFileName = "phrases.json"
    private static let appliedMetaFileName = "applied_meta.json"

    static var appGroupContainer: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID)
    }

    static var cachedPhrasesURL: URL? {
        appGroupContainer?
            .appendingPathComponent("Library/Application Support", isDirectory: true)
            .appendingPathComponent(corpusDirectoryName, isDirectory: true)
            .appendingPathComponent(phrasesFileName)
    }

    static var appliedMetaURL: URL? {
        appGroupContainer?
            .appendingPathComponent("Library/Application Support", isDirectory: true)
            .appendingPathComponent(corpusDirectoryName, isDirectory: true)
            .appendingPathComponent(appliedMetaFileName)
    }

    static func ensureCorpusDirectory() throws -> URL {
        guard let base = appGroupContainer else { throw CorpusUpdateError.appGroupUnavailable }
        let dir = base
            .appendingPathComponent("Library/Application Support", isDirectory: true)
            .appendingPathComponent(corpusDirectoryName, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func loadCachedPhrases() -> [Phrase]? {
        guard let url = cachedPhrasesURL,
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return decodePhrases(from: data)
    }

    static func loadAppliedVersion() -> Int {
        guard let url = appliedMetaURL,
              let data = try? Data(contentsOf: url),
              let meta = try? JSONDecoder().decode(CorpusBundledMeta.self, from: data)
        else { return 0 }
        return meta.corpusVersion
    }

    static func saveCachedPhrases(data: Data, meta: CorpusBundledMeta) throws {
        let dir = try ensureCorpusDirectory()
        let phrasesURL = dir.appendingPathComponent(phrasesFileName)
        let metaURL = dir.appendingPathComponent(appliedMetaFileName)
        try data.write(to: phrasesURL, options: .atomic)
        let metaData = try JSONEncoder().encode(meta)
        try metaData.write(to: metaURL, options: .atomic)
    }

    static func decodePhrases(from data: Data) -> [Phrase]? {
        if let list = try? JSONDecoder().decode([Phrase].self, from: data), !list.isEmpty {
            return list
        }
        if let bundle = try? JSONDecoder().decode(PhraseCorpusFile.self, from: data), !bundle.phrases.isEmpty {
            return bundle.phrases
        }
        return nil
    }
}

/// 可选包络格式（远程也可直接发布裸数组，与现网一致）。
struct PhraseCorpusFile: Codable {
    let corpusVersion: Int?
    let phrases: [Phrase]
}

enum CorpusUpdateError: Error {
    case appGroupUnavailable
    case manifestURLMissing
    case manifestInvalid
    case versionNotNewer
    case downloadFailed
    case checksumMismatch
    case appVersionTooOld
}
