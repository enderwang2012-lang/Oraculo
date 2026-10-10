import Foundation

final class CalendarConfigStore {
    static let shared = CalendarConfigStore()

    private let bundledConfig: CalendarConfig
    private(set) var config: CalendarConfig

    private init() {
        let bundled = Self.loadBundledConfig() ?? CalendarConfig(
            version: 0,
            festivals: [],
            solarTerms: [:]
        )
        bundledConfig = bundled
        config = bundled
        reloadFromDisk()
    }

    init(bundleConfig: CalendarConfig, remoteConfig: CalendarConfig?) {
        bundledConfig = bundleConfig
        config = remoteConfig.map { $0.version >= bundleConfig.version ? $0 : bundleConfig } ?? bundleConfig
    }

    func reloadFromDisk() {
        useRelease(CorpusReleaseStorage.loadActiveCalendarConfig())
    }

    func useRelease(_ remote: CalendarConfig?) {
        guard let remote,
              remote.version >= bundledConfig.version
        else {
            config = bundledConfig
            return
        }
        config = remote
    }

    private static func loadBundledConfig(from bundle: Bundle = .main) -> CalendarConfig? {
        if let url = bundle.url(forResource: "calendar", withExtension: "json")
            ?? bundle.url(forResource: "calendar", withExtension: "json", subdirectory: "Resources"),
           let data = try? Data(contentsOf: url),
           let config = try? JSONDecoder().decode(CalendarConfig.self, from: data) {
            return config
        }
        guard
            let festivalsURL = bundle.url(forResource: AppConstants.festivalsResourceName, withExtension: "json")
                ?? bundle.url(
                    forResource: AppConstants.festivalsResourceName,
                    withExtension: "json",
                    subdirectory: "Resources"
                ),
            let solarTermsURL = bundle.url(forResource: AppConstants.solarTermsResourceName, withExtension: "json")
                ?? bundle.url(
                    forResource: AppConstants.solarTermsResourceName,
                    withExtension: "json",
                    subdirectory: "Resources"
                ),
            let festivalsData = try? Data(contentsOf: festivalsURL),
            let solarTermsData = try? Data(contentsOf: solarTermsURL),
            let fileVersion = try? JSONDecoder().decode(VersionFile.self, from: festivalsData).version,
            let config = try? CalendarConfig.from(
                festivalsData: festivalsData,
                solarTermsData: solarTermsData,
                version: CorpusBundledMeta.load(from: bundle)?.corpusVersion ?? fileVersion
            )
        else {
            return nil
        }
        return config
    }

    private struct VersionFile: Decodable {
        let version: Int
    }
}
