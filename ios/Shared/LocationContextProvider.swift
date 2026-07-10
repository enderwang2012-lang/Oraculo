import Foundation

#if !APPLICATION_EXTENSION_API_ONLY
import Combine
import CoreLocation

enum LocationContextActivationResult: Equatable {
    case enabled
    case denied
    case restricted
}

/// 主 App：请求 GPS，写入 App Group，并触发该坐标下的天气刷新。
@MainActor
final class LocationContextProvider: NSObject, CLLocationManagerDelegate, ObservableObject {
    static let shared = LocationContextProvider()

    @Published private(set) var isEnabled: Bool
    @Published private(set) var authorizationStatus: CLAuthorizationStatus

    private let manager: CLLocationManager
    private var isUpdating = false
    private var authorizationContinuations: [CheckedContinuation<CLAuthorizationStatus, Never>] = []

    override private init() {
        let manager = CLLocationManager()
        self.manager = manager
        isEnabled = LocationContextSettings.isEnabled()
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    static var isLocationContextEnabled: Bool {
        get {
            LocationContextSettings.isEnabled()
        }
        set {
            LocationContextSettings.setEnabled(newValue)
        }
    }

    func activationAction() -> LocationAuthorizationActivationAction {
        let currentStatus = manager.authorizationStatus
        authorizationStatus = currentStatus
        return LocationAuthorizationPolicy.activationAction(for: currentStatus)
    }

    func enableLocationContext() async -> LocationContextActivationResult {
        var currentStatus = manager.authorizationStatus
        authorizationStatus = currentStatus

        if LocationAuthorizationPolicy.activationAction(for: currentStatus) == .requestPermission {
            currentStatus = await requestWhenInUseAuthorization()
            authorizationStatus = currentStatus
        }

        switch LocationAuthorizationPolicy.activationAction(for: currentStatus) {
        case .enable:
            updateEnabledState(true)
            requestLocationIfNeeded()
            return .enabled
        case .showSettings:
            updateEnabledState(false)
            return .denied
        case .showRestriction, .requestPermission:
            updateEnabledState(false)
            return .restricted
        }
    }

    func disableLocationContext() {
        updateEnabledState(false)
    }

    func refreshIfNeeded() {
        guard isEnabled else { return }
        // 不在主线程调用 CLLocationManager.locationServicesEnabled()（iOS 17 起会刷主线程警告）。
        // 鉴权状态足以判断是否能继续；权限失效时同步关闭位置情境并清除缓存。
        // 服务被系统关时 requestLocation 会以 didFailWithError 形式回来，由 delegate 重置 isUpdating。
        let currentStatus = manager.authorizationStatus
        authorizationStatus = currentStatus
        switch LocationAuthorizationPolicy.activationAction(for: currentStatus) {
        case .enable:
            requestLocationIfNeeded()
        case .requestPermission, .showSettings, .showRestriction:
            // 不在回前台时突兀弹权限；必须由用户再次点击定位按钮发起。
            updateEnabledState(false)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let currentStatus = manager.authorizationStatus
        Task { @MainActor in
            authorizationStatus = currentStatus
            if currentStatus != .notDetermined {
                resumeAuthorizationRequests(with: currentStatus)
            }

            guard isEnabled else { return }
            switch LocationAuthorizationPolicy.activationAction(for: currentStatus) {
            case .enable:
                requestLocationIfNeeded()
            case .requestPermission, .showSettings, .showRestriction:
                updateEnabledState(false)
            }
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
        guard isEnabled else { return }
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
        guard isEnabled else { return }
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
        guard isEnabled else {
            LocationContextSettings.clearCachedContext()
            return
        }
        await OpenMeteoWeatherService.refreshSharedCacheIfNeeded(
            latitude: weatherCoordinate.latitude,
            longitude: weatherCoordinate.longitude,
            force: true
        )
    }

    private func requestWhenInUseAuthorization() async -> CLAuthorizationStatus {
        let currentStatus = manager.authorizationStatus
        guard currentStatus == .notDetermined else { return currentStatus }

        return await withCheckedContinuation { continuation in
            authorizationContinuations.append(continuation)
            if authorizationContinuations.count == 1 {
                manager.requestWhenInUseAuthorization()
            }
        }
    }

    private func resumeAuthorizationRequests(with status: CLAuthorizationStatus) {
        let continuations = authorizationContinuations
        authorizationContinuations.removeAll()
        for continuation in continuations {
            continuation.resume(returning: status)
        }
    }

    private func requestLocationIfNeeded() {
        guard !isUpdating else { return }
        isUpdating = true
        manager.requestLocation()
    }

    private func updateEnabledState(_ enabled: Bool) {
        isEnabled = enabled
        Self.isLocationContextEnabled = enabled
        if !enabled {
            isUpdating = false
            manager.stopUpdatingLocation()
        }
    }
}

#endif
