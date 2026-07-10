import Foundation
import XCTest
@testable import OraculoCore

final class LocationContextPrivacyTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "LocationContextPrivacyTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        CountingURLProtocol.reset()
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testDisablingLocationContextClearsRawAndDerivedCaches() {
        defaults.set(true, forKey: AppConstants.sharedLocationContextEnabledKey)
        defaults.set(31.2304, forKey: AppConstants.sharedLocationLatitudeKey)
        defaults.set(121.4737, forKey: AppConstants.sharedLocationLongitudeKey)
        defaults.set(20.0, forKey: AppConstants.sharedLocationAccuracyKey)
        defaults.set(12.0, forKey: AppConstants.sharedLocationAltitudeKey)
        defaults.set(Date(), forKey: AppConstants.sharedLocationUpdatedKey)
        defaults.set("gps", forKey: AppConstants.sharedLocationSourceKey)
        defaults.set("31.2,121.5", forKey: AppConstants.sharedGeoCellKey)
        defaults.set("cn_east", forKey: AppConstants.sharedGeoRegionKey)
        defaults.set("plain", forKey: AppConstants.sharedAltitudeBandKey)
        defaults.set(31.2, forKey: AppConstants.sharedWeatherLatitudeKey)
        defaults.set(121.5, forKey: AppConstants.sharedWeatherLongitudeKey)
        defaults.set("clear", forKey: AppConstants.sharedWeatherTagKey)
        defaults.set("hot", forKey: AppConstants.sharedTempBandKey)
        defaults.set(Date(), forKey: AppConstants.sharedWeatherUpdatedKey)

        LocationContextSettings.setEnabled(false, in: defaults)

        XCTAssertFalse(LocationContextSettings.isEnabled(in: defaults))
        for key in cachedContextKeys {
            XCTAssertNil(defaults.object(forKey: key), "Expected \(key) to be removed")
        }
    }

    func testDisabledConsentRejectsPersistedCoordinateAndMakesNoNetworkRequest() async {
        defaults.set(false, forKey: AppConstants.sharedLocationContextEnabledKey)
        // Simulate stale data left by an older app version.
        defaults.set(31.2, forKey: AppConstants.sharedWeatherLatitudeKey)
        defaults.set(121.5, forKey: AppConstants.sharedWeatherLongitudeKey)

        XCTAssertNil(OpenMeteoWeatherService.defaultCoordinate(defaults: defaults))

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CountingURLProtocol.self]
        let session = URLSession(configuration: configuration)

        await OpenMeteoWeatherService.refreshSharedCacheIfPossible(
            force: true,
            defaults: defaults,
            session: session
        )

        XCTAssertEqual(CountingURLProtocol.requestCount, 0)
    }

    func testLocaleContextIgnoresCachedGPSValuesWhenConsentIsDisabled() {
        let cache = LocationContextCache(
            latitude: 31.2,
            longitude: 121.5,
            horizontalAccuracy: 10,
            altitudeMeters: 4_500,
            geoRegion: "cn_qinghai_tibet",
            altitudeBand: "high",
            geoCell: "31.2,121.5",
            source: "gps",
            updatedAt: Date()
        )
        cache.save(defaults: defaults)

        let region = GeoContext.region(
            for: Locale(identifier: "en_US"),
            defaults: defaults,
            allowCachedLocationContext: false
        )

        XCTAssertEqual(region, "north_america")
        XCTAssertEqual(
            GeoContext.altitudeBand(
                for: region,
                defaults: defaults,
                allowCachedLocationContext: false
            ),
            "plain"
        )
        XCTAssertEqual(
            GeoContext.locationSource(
                defaults: defaults,
                allowCachedLocationContext: false
            ),
            "locale"
        )
        XCTAssertNil(
            GeoContext.geoCell(
                defaults: defaults,
                allowCachedLocationContext: false
            )
        )
    }

    func testDisabledConsentHidesWeatherCacheFromContextConstruction() {
        defaults.set(false, forKey: AppConstants.sharedLocationContextEnabledKey)
        defaults.set("snow", forKey: AppConstants.sharedWeatherTagKey)
        defaults.set("cold", forKey: AppConstants.sharedTempBandKey)
        defaults.set(Date(), forKey: AppConstants.sharedWeatherUpdatedKey)

        let visibleWeather = LocationContextSettings.visibleWeatherCache(in: defaults)

        XCTAssertNil(visibleWeather.weatherTag)
        XCTAssertNil(visibleWeather.tempBand)
        XCTAssertNil(visibleWeather.updatedAt)
    }

    private var cachedContextKeys: [String] {
        [
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
    }
}

private final class CountingURLProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var storedRequestCount = 0

    static var requestCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return storedRequestCount
    }

    static func reset() {
        lock.lock()
        storedRequestCount = 0
        lock.unlock()
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lock.lock()
        Self.storedRequestCount += 1
        Self.lock.unlock()

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(#"{"current_weather":{"weathercode":0,"temperature":20}}"#.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
