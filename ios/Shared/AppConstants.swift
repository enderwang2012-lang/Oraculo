import Foundation

enum AppConstants {
    /// App Group — 主 App 与 Widget 扩展须在 Xcode 中勾选同一 ID。
    static let appGroupID = "group.ai.oraculo.shared"

    static let sharedTodayPhraseKey = "todayPhraseText"
    static let sharedTodayPhraseIDKey = "todayPhraseID"
    static let sharedTodayDayKeyKey = "todayDayKey"
    static let sharedTodayColorHexKey = "todayColorHex"
    static let sharedTodayColorCnameKey = "todayColorCname"
    static let sharedTodayColorNameKey = "todayColorName"
    static let sharedTodayColorForegroundKey = "todayColorForeground"

    static let sharedWeatherTagKey = "contextWeatherTag"
    static let sharedTempBandKey = "contextTempBand"
    static let sharedWeatherUpdatedKey = "contextWeatherUpdated"
    static let sharedGeoRegionKey = "contextGeoRegion"
    static let sharedAltitudeBandKey = "contextAltitudeBand"
    static let sharedWeatherLatitudeKey = "contextWeatherLatitude"
    static let sharedWeatherLongitudeKey = "contextWeatherLongitude"

    static let sharedLocationLatitudeKey = "contextLocationLatitude"
    static let sharedLocationLongitudeKey = "contextLocationLongitude"
    static let sharedLocationAccuracyKey = "contextLocationAccuracy"
    static let sharedLocationAltitudeKey = "contextLocationAltitude"
    static let sharedLocationUpdatedKey = "contextLocationUpdated"
    static let sharedLocationSourceKey = "contextLocationSource"
    static let sharedGeoCellKey = "contextGeoCell"
    static let sharedCorpusVersionKey = "corpusAppliedVersion"

    /// 静态热更新 manifest URL。留空则关闭。见 docs/CORPUS_REMOTE.md
    /// 勿用 oraculo.vercel.app（已被其他站点占用）。Vercel Project Name 请设为 oraculo-corpus。
    static let corpusManifestURLString = "https://oraculo-corpus.vercel.app/oraculo/manifest.json"

    static var corpusManifestURL: URL? {
        let trimmed = corpusManifestURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }

    static let festivalsResourceName = "festivals_cn"
    static let solarTermsResourceName = "solar_terms_cn"
    static let phrasesResourceName = "phrases"
    static let nipponColorsResourceName = "nippon_colors"
}
