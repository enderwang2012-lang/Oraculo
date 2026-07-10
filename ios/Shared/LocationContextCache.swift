import Foundation
#if canImport(CoreLocation)
import CoreLocation
#endif

#if canImport(CoreLocation)
enum LocationAuthorizationActivationAction: Equatable {
    case requestPermission
    case enable
    case showSettings
    case showRestriction
}

enum LocationAuthorizationPolicy {
    static func activationAction(for status: CLAuthorizationStatus) -> LocationAuthorizationActivationAction {
        switch status {
        case .notDetermined:
            return .requestPermission
        case .authorizedWhenInUse, .authorizedAlways:
            return .enable
        case .denied:
            return .showSettings
        case .restricted:
            return .showRestriction
        @unknown default:
            return .showRestriction
        }
    }
}
#endif

/// 位置情境的授权状态与缓存生命周期。关闭授权时必须同时删除原始坐标和所有派生数据。
enum LocationContextSettings {
    static let cachedContextKeys: [String] = [
        AppConstants.sharedLocationLatitudeKey,
        AppConstants.sharedLocationLongitudeKey,
        AppConstants.sharedLocationAccuracyKey,
        AppConstants.sharedLocationAltitudeKey,
        AppConstants.sharedLocationUpdatedKey,
        AppConstants.sharedLocationSourceKey,
        AppConstants.sharedGeoCellKey,
        AppConstants.sharedGeoRegionKey,
        AppConstants.sharedAltitudeBandKey,
        AppConstants.sharedWeatherLatitudeKey,
        AppConstants.sharedWeatherLongitudeKey,
        AppConstants.sharedWeatherTagKey,
        AppConstants.sharedTempBandKey,
        AppConstants.sharedWeatherUpdatedKey,
    ]

    static func isEnabled(
        in defaults: UserDefaults? = UserDefaults(suiteName: AppConstants.appGroupID)
    ) -> Bool {
        defaults?.bool(forKey: AppConstants.sharedLocationContextEnabledKey) ?? false
    }

    static func setEnabled(
        _ enabled: Bool,
        in defaults: UserDefaults? = UserDefaults(suiteName: AppConstants.appGroupID)
    ) {
        defaults?.set(enabled, forKey: AppConstants.sharedLocationContextEnabledKey)
        if !enabled {
            clearCachedContext(in: defaults)
        }
    }

    static func clearCachedContext(
        in defaults: UserDefaults? = UserDefaults(suiteName: AppConstants.appGroupID)
    ) {
        for key in cachedContextKeys {
            defaults?.removeObject(forKey: key)
        }
    }

    static func visibleWeatherCache(
        in defaults: UserDefaults? = UserDefaults(suiteName: AppConstants.appGroupID)
    ) -> WeatherContextCache {
        guard isEnabled(in: defaults) else { return WeatherContextCache() }
        return WeatherContextCache.load(defaults: defaults)
    }
}

/// GPS 定位结果（主 App 写入，Widget 只读）。
struct LocationContextCache: Equatable {
    var latitude: Double
    var longitude: Double
    var horizontalAccuracy: Double
    var altitudeMeters: Double?
    var geoRegion: String
    var altitudeBand: String
    /// 约 0.1° 网格，用于情境指纹（不暴露原始坐标到 UI）。
    var geoCell: String
    var source: String
    var updatedAt: Date

    static let maxAge: TimeInterval = 24 * 60 * 60
    static let maxHorizontalAccuracy: Double = 3_000

    var isValid: Bool {
        horizontalAccuracy >= 0
            && horizontalAccuracy <= Self.maxHorizontalAccuracy
            && Date().timeIntervalSince(updatedAt) <= Self.maxAge
    }

    static func load(
        defaults: UserDefaults? = UserDefaults(suiteName: AppConstants.appGroupID)
    ) -> LocationContextCache? {
        guard let defaults,
              defaults.object(forKey: AppConstants.sharedLocationLatitudeKey) != nil
        else { return nil }

        return LocationContextCache(
            latitude: defaults.double(forKey: AppConstants.sharedLocationLatitudeKey),
            longitude: defaults.double(forKey: AppConstants.sharedLocationLongitudeKey),
            horizontalAccuracy: defaults.double(forKey: AppConstants.sharedLocationAccuracyKey),
            altitudeMeters: defaults.object(forKey: AppConstants.sharedLocationAltitudeKey) as? Double,
            geoRegion: defaults.string(forKey: AppConstants.sharedGeoRegionKey) ?? "global",
            altitudeBand: defaults.string(forKey: AppConstants.sharedAltitudeBandKey) ?? "plain",
            geoCell: defaults.string(forKey: AppConstants.sharedGeoCellKey) ?? "",
            source: defaults.string(forKey: AppConstants.sharedLocationSourceKey) ?? "gps",
            updatedAt: defaults.object(forKey: AppConstants.sharedLocationUpdatedKey) as? Date ?? .distantPast
        )
    }

    func save(
        defaults: UserDefaults? = UserDefaults(suiteName: AppConstants.appGroupID)
    ) {
        guard let defaults else { return }
        defaults.set(latitude, forKey: AppConstants.sharedLocationLatitudeKey)
        defaults.set(longitude, forKey: AppConstants.sharedLocationLongitudeKey)
        defaults.set(horizontalAccuracy, forKey: AppConstants.sharedLocationAccuracyKey)
        defaults.set(geoRegion, forKey: AppConstants.sharedGeoRegionKey)
        defaults.set(altitudeBand, forKey: AppConstants.sharedAltitudeBandKey)
        defaults.set(geoCell, forKey: AppConstants.sharedGeoCellKey)
        defaults.set(source, forKey: AppConstants.sharedLocationSourceKey)
        defaults.set(updatedAt, forKey: AppConstants.sharedLocationUpdatedKey)
        defaults.set(latitude, forKey: AppConstants.sharedWeatherLatitudeKey)
        defaults.set(longitude, forKey: AppConstants.sharedWeatherLongitudeKey)
        if let altitudeMeters {
            defaults.set(altitudeMeters, forKey: AppConstants.sharedLocationAltitudeKey)
        } else {
            defaults.removeObject(forKey: AppConstants.sharedLocationAltitudeKey)
        }
    }
}
