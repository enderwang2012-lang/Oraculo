import CryptoKit
import Foundation

#if !APPLICATION_EXTENSION_API_ONLY

/// 静态 manifest + JSON 语料热更新（无自建后端）。
enum CorpusRemoteUpdateService {
    private static let appliedVersionKey = "corpusAppliedVersion"
    @MainActor private static var isRefreshing = false

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
    @discardableResult
    static func refreshIfNeeded(session: URLSession? = nil) async -> Bool {
        guard !isRefreshing else { return false }
        isRefreshing = true
        defer { isRefreshing = false }
        guard let manifestURL = AppConstants.corpusManifestURL else { return false }
        let session = session ?? defaultSession

        do {
            let updated = try await performRefresh(manifestURL: manifestURL, session: session)
            if updated {
                PhraseStore.shared.reloadFromDisk()
                WidgetTimelineRefresher.reloadAllIfPossible()
                #if DEBUG
                print("[Oraculo] corpus hot-update applied, count=\(PhraseStore.shared.phraseCount)")
                #endif
            }
            return updated
        } catch CorpusUpdateError.versionNotNewer {
            return false
        } catch {
            #if DEBUG
            print("[Oraculo] corpus hot-update skipped: \(error)")
            #endif
            return false
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
        let activeVersion = CorpusReleaseStorage.loadActiveRelease()?.meta.releaseVersion ?? 0
        let localBest = max(bundledVersion, activeVersion)

        let releaseVersion = manifest.effectiveReleaseVersion
        guard releaseVersion > localBest else {
            throw CorpusUpdateError.versionNotNewer
        }

        guard manifest.corpusVersion == releaseVersion,
              let calendarAsset = manifest.calendar,
              let calendarURL = URL(string: calendarAsset.url), calendarURL.scheme == "https",
              let phrasesURL = URL(string: manifest.phrases.url), phrasesURL.scheme == "https"
        else {
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

        do {
            let (calendarData, calendarResponse) = try await session.data(from: calendarURL)
            guard let calendarHTTP = calendarResponse as? HTTPURLResponse,
                  (200 ... 299).contains(calendarHTTP.statusCode)
            else {
                throw CorpusUpdateError.downloadFailed
            }

            let expectedCalendarHash = calendarAsset.sha256.lowercased()
            guard sha256Hex(calendarData) == expectedCalendarHash else {
                throw CorpusUpdateError.checksumMismatch
            }
            guard let calendar = try? JSONDecoder().decode(CalendarConfig.self, from: calendarData),
                  calendar.version == releaseVersion, calendar.isValid
            else {
                throw CorpusUpdateError.downloadFailed
            }

            let meta = CorpusReleaseMeta(
                releaseVersion: releaseVersion,
                generatedAt: manifest.publishedAt ?? ISO8601DateFormatter().string(from: Date()),
                phraseCount: phrases.count,
                phrasesSHA256: expectedHash,
                calendarSHA256: expectedCalendarHash
            )
            try CorpusReleaseStorage.saveRelease(
                phrasesData: phrasesData,
                calendarData: calendarData,
                meta: meta
            )
        }

        UserDefaults.standard.set(releaseVersion, forKey: appliedVersionKey)

        if let defaults = UserDefaults(suiteName: AppConstants.appGroupID) {
            defaults.set(releaseVersion, forKey: AppConstants.sharedCorpusVersionKey)
        }

        return true
    }

    private static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

#endif
