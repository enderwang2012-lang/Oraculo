import Foundation

/// App / Widget 共用的天气情境缓存（主 App 拉取 Open-Meteo 后写入 App Group）。
struct WeatherContextCache: Equatable {
    var weatherTag: String?
    var tempBand: String?
    var updatedAt: Date?

    static func load(
        defaults: UserDefaults? = UserDefaults(suiteName: AppConstants.appGroupID)
    ) -> WeatherContextCache {
        guard let defaults else {
            return WeatherContextCache()
        }
        let tag = defaults.string(forKey: AppConstants.sharedWeatherTagKey)
        let temp = defaults.string(forKey: AppConstants.sharedTempBandKey)
        let updated = defaults.object(forKey: AppConstants.sharedWeatherUpdatedKey) as? Date
        return WeatherContextCache(weatherTag: tag, tempBand: temp, updatedAt: updated)
    }

    func save(
        defaults: UserDefaults? = UserDefaults(suiteName: AppConstants.appGroupID)
    ) {
        guard let defaults else { return }
        if let weatherTag {
            defaults.set(weatherTag, forKey: AppConstants.sharedWeatherTagKey)
        } else {
            defaults.removeObject(forKey: AppConstants.sharedWeatherTagKey)
        }
        if let tempBand {
            defaults.set(tempBand, forKey: AppConstants.sharedTempBandKey)
        } else {
            defaults.removeObject(forKey: AppConstants.sharedTempBandKey)
        }
        if let updatedAt {
            defaults.set(updatedAt, forKey: AppConstants.sharedWeatherUpdatedKey)
        }
    }

    var isStale: Bool {
        guard let updatedAt else { return true }
        return Date().timeIntervalSince(updatedAt) > 60 * 60
    }
}
