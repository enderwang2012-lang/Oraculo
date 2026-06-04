import Foundation

/// 当前时刻的情境标签快照，供 Widget 与摇一摇共用同一套打分逻辑。
struct ContextSnapshot: Equatable {
    let dayKey: String
    let season: String
    let month: Int
    let weekday: Int
    let dayPart: String
    let festivals: Set<String>
    let weather: String?
    let tempBand: String?
    let solarTerm: String?
    let geoRegion: String
    let altitudeBand: String
    let geoCell: String?
    let locationSource: String
    let localeID: String

    /// 扁平标签集，用于 `onlyWhen` / `boost` 匹配。
    var activeTags: Set<String> {
        var tags: Set<String> = [
            "season:\(season)",
            "month:\(month)",
            "weekday:\(weekday)",
            "daypart:\(dayPart)",
            "geo:\(geoRegion)",
            "altitude:\(altitudeBand)",
            "location:\(locationSource)",
            "locale:\(localeID)",
        ]
        for f in festivals {
            tags.insert("festival:\(f)")
        }
        if let solarTerm {
            tags.insert("solar_term:\(solarTerm)")
        }
        if let weather {
            tags.insert("weather:\(weather)")
        }
        if let tempBand {
            tags.insert("temp:\(tempBand)")
        }
        if let geoCell {
            tags.insert("geo_cell:\(geoCell)")
        }
        return tags
    }

    /// 与情境相关的稳定指纹，用于 Widget 日种子。
    var selectionFingerprint: String {
        let parts = [
            season,
            String(month),
            solarTerm ?? "",
            festivals.sorted().joined(separator: ","),
            weather ?? "",
            tempBand ?? "",
            geoRegion,
            geoCell ?? "",
            altitudeBand,
            locationSource,
        ]
        return parts.joined(separator: "|")
    }
}
