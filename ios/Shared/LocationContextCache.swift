import Foundation

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

    static func load() -> LocationContextCache? {
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupID),
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

    func save() {
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupID) else { return }
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
