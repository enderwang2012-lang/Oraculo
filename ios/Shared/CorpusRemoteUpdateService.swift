import CryptoKit
import Foundation

#if !APPLICATION_EXTENSION_API_ONLY

/// 静态 manifest + JSON 语料热更新（无自建后端）。
enum CorpusRemoteUpdateService {
    private static let appliedVersionKey = "corpusAppliedVersion"

    /// 默认会话：单请求 15s，整个 resource 30s。
    /// 防止劫持/异常 CDN 让前台启动悬挂在默认 60s+。
    private static let defaultSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    /// 前台拉 manifest，有新版本则下载并校验 SHA256。
    @MainActor
    static func refreshIfNeeded(session: URLSession? = nil) async {
        guard let manifestURL = AppConstants.corpusManifestURL else { return }
        let session = session ?? defaultSession

        do {
            let updated = try await performRefresh(manifestURL: manifestURL, session: session)
            if updated {
                PhraseStore.shared.reloadFromDisk()
                #if DEBUG
                print("[Oraculo] corpus hot-update applied, count=\(PhraseStore.shared.phraseCount)")
                #endif
            }
        } catch CorpusUpdateError.versionNotNewer {
            return
        } catch {
            #if DEBUG
            print("[Oraculo] corpus hot-update skipped: \(error)")
            #endif
        }
    }

    @MainActor
    private static func performRefresh(manifestURL: URL, session: URLSession) async throws -> Bool {
        let (manifestData, response) = try await session.data(from: manifestURL)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw CorpusUpdateError.manifestInvalid
        }

        let manifest = try JSONDecoder().decode(CorpusRemoteManifest.self, from: manifestData)

        if let minVersion = manifest.minAppVersion, !minVersion.isEmpty {
            let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
            if current.compare(minVersion, options: .numeric) == .orderedAscending {
                throw CorpusUpdateError.appVersionTooOld
            }
        }

        let bundledVersion = CorpusBundledMeta.load()?.corpusVersion ?? 0
        let appliedVersion = max(PhraseCorpusStorage.loadAppliedVersion(), UserDefaults.standard.integer(forKey: appliedVersionKey))
        let localBest = max(bundledVersion, appliedVersion)

        guard manifest.corpusVersion > localBest else {
            throw CorpusUpdateError.versionNotNewer
        }

        guard let phrasesURL = URL(string: manifest.phrases.url) else {
            throw CorpusUpdateError.manifestInvalid
        }

        let (phrasesData, phrasesResponse) = try await session.data(from: phrasesURL)
        guard let phrasesHTTP = phrasesResponse as? HTTPURLResponse, (200 ... 299).contains(phrasesHTTP.statusCode) else {
            throw CorpusUpdateError.downloadFailed
        }

        let expectedHash = manifest.phrases.sha256.lowercased()
        let actualHash = sha256Hex(phrasesData)
        guard actualHash == expectedHash else {
            throw CorpusUpdateError.checksumMismatch
        }

        guard let phrases = PhraseCorpusStorage.decodePhrases(from: phrasesData), !phrases.isEmpty else {
            throw CorpusUpdateError.downloadFailed
        }

        let meta = CorpusBundledMeta(
            corpusVersion: manifest.corpusVersion,
            generatedAt: manifest.publishedAt ?? ISO8601DateFormatter().string(from: Date()),
            phraseCount: phrases.count,
            phrasesSHA256: expectedHash
        )

        try PhraseCorpusStorage.saveCachedPhrases(data: phrasesData, meta: meta)
        UserDefaults.standard.set(manifest.corpusVersion, forKey: appliedVersionKey)

        if let defaults = UserDefaults(suiteName: AppConstants.appGroupID) {
            defaults.set(manifest.corpusVersion, forKey: AppConstants.sharedCorpusVersionKey)
        }

        return true
    }

    private static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

#endif
