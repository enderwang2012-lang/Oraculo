import Foundation

#if !APPLICATION_EXTENSION_API_ONLY
import CoreLocation

/// 主 App：请求 GPS，写入 App Group，并触发该坐标下的天气刷新。
@MainActor
final class LocationContextProvider: NSObject, CLLocationManagerDelegate {
    static let shared = LocationContextProvider()

    private let manager = CLLocationManager()
    private var isUpdating = false

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    static var isLocationContextEnabled: Bool {
        get {
            UserDefaults(suiteName: AppConstants.appGroupID)?
                .bool(forKey: AppConstants.sharedLocationContextEnabledKey) ?? false
        }
        set {
            UserDefaults(suiteName: AppConstants.appGroupID)?
                .set(newValue, forKey: AppConstants.sharedLocationContextEnabledKey)
        }
    }

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    func setLocationContextEnabled(_ enabled: Bool) {
        Self.isLocationContextEnabled = enabled
        if enabled {
            refreshIfNeeded()
        }
    }

    func refreshIfNeeded() {
        guard Self.isLocationContextEnabled else { return }
        // 不在主线程调用 CLLocationManager.locationServicesEnabled()（iOS 17 起会刷主线程警告）。
        // 鉴权状态足以判断是否能继续：denied/restricted 走 default 分支不动作；
        // 服务被系统关时 requestLocation 会以 didFailWithError 形式回来，由 delegate 重置 isUpdating。
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            guard !isUpdating else { return }
            isUpdating = true
            manager.requestLocation()
        default:
            break
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            refreshIfNeeded()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            isUpdating = false
            await apply(location: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            isUpdating = false
            #if DEBUG
            print("[Oraculo] location failed: \(error.localizedDescription)")
            #endif
        }
    }

    private func apply(location: CLLocation) async {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let weatherCoordinate = GeoCoordinateMapper.coarseCoordinate(latitude: lat, longitude: lon)
        let region = GeoCoordinateMapper.geoRegion(latitude: lat, longitude: lon)
        var altitude = location.altitude
        if location.verticalAccuracy < 0 || location.verticalAccuracy > 100 {
            altitude = await OpenMeteoWeatherService.fetchElevationMeters(
                latitude: weatherCoordinate.latitude,
                longitude: weatherCoordinate.longitude
            ) ?? altitude
        }
        let band = GeoCoordinateMapper.altitudeBand(meters: altitude, geoRegion: region)
        let cache = LocationContextCache(
            latitude: weatherCoordinate.latitude,
            longitude: weatherCoordinate.longitude,
            horizontalAccuracy: location.horizontalAccuracy,
            altitudeMeters: altitude,
            geoRegion: region,
            altitudeBand: band,
            geoCell: GeoCoordinateMapper.geoCell(latitude: lat, longitude: lon),
            source: "gps",
            updatedAt: Date()
        )
        cache.save()
        await OpenMeteoWeatherService.refreshSharedCacheIfNeeded(
            latitude: weatherCoordinate.latitude,
            longitude: weatherCoordinate.longitude,
            force: true
        )
    }
}

#endif
