import Foundation

#if !APPLICATION_EXTENSION_API_ONLY

/// 免费天气 API，无需密钥：https://open-meteo.com
enum OpenMeteoWeatherService {
    struct Response: Decodable {
        struct Current: Decodable {
            let weatherCode: Int
            let temperature: Double

            enum CodingKeys: String, CodingKey {
                case weatherCode = "weathercode"
                case temperature
            }
        }

        let currentWeather: Current

        enum CodingKeys: String, CodingKey {
            case currentWeather = "current_weather"
        }
    }

    static func fetch(
        latitude: Double,
        longitude: Double,
        session: URLSession = .shared
    ) async throws -> WeatherContextCache {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current_weather", value: "true"),
        ]
        guard let url = components.url else { throw URLError(.badURL) }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        let tag = mapWeatherCode(decoded.currentWeather.weatherCode)
        let temp = mapTempBand(decoded.currentWeather.temperature)
        return WeatherContextCache(weatherTag: tag, tempBand: temp, updatedAt: Date())
    }

    struct ElevationResponse: Decodable {
        let elevation: [Double]
    }

    static func fetchElevationMeters(
        latitude: Double,
        longitude: Double,
        session: URLSession = .shared
    ) async -> Double? {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/elevation")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
        ]
        guard let url = components.url else { return nil }
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
                return nil
            }
            let decoded = try JSONDecoder().decode(ElevationResponse.self, from: data)
            return decoded.elevation.first
        } catch {
            return nil
        }
    }

    static func refreshSharedCacheIfNeeded(
        latitude: Double,
        longitude: Double,
        force: Bool = false
    ) async {
        if !force {
            let existing = WeatherContextCache.load()
            guard existing.isStale else { return }
        }
        do {
            let fresh = try await fetch(latitude: latitude, longitude: longitude)
            fresh.save()
        } catch {
            // 保留旧缓存；无网络时情境下发仍可用季节/节日维度。
        }
    }

    static func refreshSharedCacheIfPossible(force: Bool = false) async {
        guard let coordinate = defaultCoordinate else { return }
        await refreshSharedCacheIfNeeded(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            force: force
        )
    }

    static var defaultCoordinate: (latitude: Double, longitude: Double)? {
        if let gps = LocationContextCache.load(), gps.isValid {
            return (gps.latitude, gps.longitude)
        }
        if let defaults = UserDefaults(suiteName: AppConstants.appGroupID),
           defaults.object(forKey: AppConstants.sharedWeatherLatitudeKey) != nil,
           defaults.object(forKey: AppConstants.sharedWeatherLongitudeKey) != nil {
            return (
                defaults.double(forKey: AppConstants.sharedWeatherLatitudeKey),
                defaults.double(forKey: AppConstants.sharedWeatherLongitudeKey)
            )
        }
        return nil
    }

    /// WMO weather code → 内部标签
    static func mapWeatherCode(_ code: Int) -> String {
        switch code {
        case 0:
            return "clear"
        case 1, 2, 3:
            return "overcast"
        case 45, 48:
            return "overcast"
        case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82:
            return "rain"
        case 71, 73, 75, 77, 85, 86:
            return "snow"
        case 95, 96, 99:
            return "rain"
        default:
            return "overcast"
        }
    }

    static func mapTempBand(_ celsius: Double) -> String {
        switch celsius {
        case ..<5:
            return "cold"
        case 5 ..< 28:
            return "mild"
        default:
            return "hot"
        }
    }
}

#endif
