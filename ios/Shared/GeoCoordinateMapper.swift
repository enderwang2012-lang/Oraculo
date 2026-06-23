import Foundation

/// 将 WGS84 坐标映射为粗粒度 `geo:*` 与 `altitude:*` 标签（无需逆地理 API）。
enum GeoCoordinateMapper {
    private struct Box {
        let minLat: Double
        let maxLat: Double
        let minLon: Double
        let maxLon: Double
        let region: String
    }

    /// 中国大陆常见大区（简化矩形，重叠时取先匹配）。
    private static let chinaBoxes: [Box] = [
        Box(minLat: 40, maxLat: 53.5, minLon: 118, maxLon: 135, region: "cn_northeast"),
        Box(minLat: 34, maxLat: 42, minLon: 110, maxLon: 120, region: "cn_north"),
        Box(minLat: 28, maxLat: 35, minLon: 118, maxLon: 123, region: "cn_east"),
        Box(minLat: 20, maxLat: 28, minLon: 108, maxLon: 118, region: "cn_south"),
        Box(minLat: 27, maxLat: 40, minLon: 78, maxLon: 100, region: "cn_qinghai_tibet"),
        Box(minLat: 22, maxLat: 33, minLon: 98, maxLon: 108, region: "cn_southwest"),
        Box(minLat: 28, maxLat: 33, minLon: 103, maxLon: 108, region: "cn_sichuan_basin"),
        Box(minLat: 28, maxLat: 35, minLon: 110, maxLon: 118, region: "cn_yangtze_mid"),
        Box(minLat: 35, maxLat: 48, minLon: 75, maxLon: 110, region: "cn_northwest"),
    ]

    static func geoRegion(latitude: Double, longitude: Double) -> String {
        if isInChinaMainland(lat: latitude, lon: longitude) {
            for box in chinaBoxes where contains(box, lat: latitude, lon: longitude) {
                return box.region
            }
            return "cn_inland"
        }

        if latitude >= 24 && latitude <= 46 && longitude >= 122 && longitude <= 146 {
            return "japan"
        }
        if latitude >= 33 && latitude <= 39 && longitude >= 124 && longitude <= 132 {
            return "korea"
        }
        if latitude >= 24 && latitude <= 49 && longitude >= -125 && longitude <= -66 {
            return "north_america"
        }
        if latitude >= 35 && latitude <= 72 && longitude >= -10 && longitude <= 40 {
            return "europe_west"
        }
        if latitude >= -44 && latitude <= -10 && longitude >= 113 && longitude <= 154 {
            return "oceania"
        }
        return "global"
    }

    static func geoCell(latitude: Double, longitude: Double, precision: Double = 0.1) -> String {
        let lat = (latitude / precision).rounded() * precision
        let lon = (longitude / precision).rounded() * precision
        return String(format: "%.1f,%.1f", lat, lon)
    }

    static func coarseCoordinate(
        latitude: Double,
        longitude: Double,
        precision: Double = 0.1
    ) -> (latitude: Double, longitude: Double) {
        let lat = (latitude / precision).rounded() * precision
        let lon = (longitude / precision).rounded() * precision
        return (lat, lon)
    }

    static func altitudeBand(meters: Double?, geoRegion: String) -> String {
        if let m = meters, m > -500 {
            switch m {
            case ..<200: return "sea_level"
            case ..<1_000: return "low_hill"
            case ..<3_000: return "plateau_1000"
            default: return "high_3000"
            }
        }
        switch geoRegion {
        case "cn_qinghai_tibet":
            return "plateau_1000"
        case "cn_sichuan_basin", "cn_yunnan_guizhou_plateau":
            return "mid"
        default:
            return "plain"
        }
    }

    private static func isInChinaMainland(lat: Double, lon: Double) -> Bool {
        lat >= 18 && lat <= 54 && lon >= 73 && lon <= 135
    }

    private static func contains(_ box: Box, lat: Double, lon: Double) -> Bool {
        lat >= box.minLat && lat <= box.maxLat && lon >= box.minLon && lon <= box.maxLon
    }
}
