import Foundation

/// 地理与海拔：优先 GPS 缓存，其次手动覆盖，最后 Locale/时区推断。
enum GeoContext {
    static func region(
        for locale: Locale = .current,
        defaults: UserDefaults? = UserDefaults(suiteName: AppConstants.appGroupID),
        allowCachedLocationContext: Bool = true
    ) -> String {
        if allowCachedLocationContext,
           let gps = LocationContextCache.load(defaults: defaults),
           gps.isValid {
            return gps.geoRegion
        }
        if allowCachedLocationContext,
           let stored = defaults?.string(forKey: AppConstants.sharedGeoRegionKey),
            !stored.isEmpty,
            LocationContextCache.load(defaults: defaults) == nil {
            return stored
        }
        let code = locale.region?.identifier ?? locale.identifier
        switch code.uppercased() {
        case "CN":
            return inferChinaRegion(timeZone: TimeZone.current)
        case "HK", "MO", "TW":
            return "cn_south"
        case "JP":
            return "japan"
        case "KR":
            return "korea"
        case "US", "CA":
            return "north_america"
        case "GB", "IE":
            return "europe_west"
        default:
            return "global"
        }
    }

    static func altitudeBand(
        for region: String,
        defaults: UserDefaults? = UserDefaults(suiteName: AppConstants.appGroupID),
        allowCachedLocationContext: Bool = true
    ) -> String {
        if allowCachedLocationContext,
           let gps = LocationContextCache.load(defaults: defaults),
           gps.isValid {
            return gps.altitudeBand
        }
        if allowCachedLocationContext,
           let stored = defaults?.string(forKey: AppConstants.sharedAltitudeBandKey),
           !stored.isEmpty {
            return stored
        }
        switch region {
        case "cn_qinghai_tibet", "cn_yunnan_guizhou_plateau":
            return "high"
        case "cn_sichuan_basin", "cn_yangtze_mid":
            return "mid"
        default:
            return "plain"
        }
    }

    static func locationSource(
        defaults: UserDefaults? = UserDefaults(suiteName: AppConstants.appGroupID),
        allowCachedLocationContext: Bool = true
    ) -> String {
        if allowCachedLocationContext,
           let gps = LocationContextCache.load(defaults: defaults),
           gps.isValid {
            return gps.source
        }
        return "locale"
    }

    static func geoCell(
        defaults: UserDefaults? = UserDefaults(suiteName: AppConstants.appGroupID),
        allowCachedLocationContext: Bool = true
    ) -> String? {
        guard allowCachedLocationContext,
              let gps = LocationContextCache.load(defaults: defaults),
              gps.isValid,
              !gps.geoCell.isEmpty
        else {
            return nil
        }
        return gps.geoCell
    }

    private static func inferChinaRegion(timeZone: TimeZone) -> String {
        let id = timeZone.identifier
        if id.contains("Chongqing") || id.contains("Chengdu") {
            return "cn_sichuan_basin"
        }
        if id.contains("Urumqi") || id.contains("Kashgar") {
            return "cn_northwest"
        }
        if id.contains("Lhasa") {
            return "cn_qinghai_tibet"
        }
        if id.contains("Shanghai") || id.contains("Beijing") {
            return "cn_east"
        }
        if id.contains("Guangzhou") || id.contains("Hong_Kong") {
            return "cn_south"
        }
        return "cn_east"
    }
}
