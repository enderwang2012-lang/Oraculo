import Foundation

/// 构建全维度情境快照（日历、节日、时段、天气缓存、地理、海拔）。
enum ContextSnapshotBuilder {
    static func snapshot(
        for date: Date = Date(),
        calendar: Calendar = .current,
        defaults: UserDefaults? = UserDefaults(suiteName: AppConstants.appGroupID)
    ) -> ContextSnapshot {
        let dayKey = PhraseStore.dayKey(for: date, calendar: calendar)
        let month = calendar.component(.month, from: date)
        let weekday = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)
        let season = meteorologicalSeason(month: month)
        let festivals = FestivalCalendar.shared.activeFestivals(on: date, calendar: calendar)
        let solarTerm = SolarTermCalendar.shared.activeTermID(on: date, calendar: calendar)
        let allowLocationContext = LocationContextSettings.isEnabled(in: defaults)
        let weatherCache = LocationContextSettings.visibleWeatherCache(in: defaults)
        let region = GeoContext.region(
            defaults: defaults,
            allowCachedLocationContext: allowLocationContext
        )
        let altitude = GeoContext.altitudeBand(
            for: region,
            defaults: defaults,
            allowCachedLocationContext: allowLocationContext
        )

        return ContextSnapshot(
            dayKey: dayKey,
            season: season,
            month: month,
            weekday: weekday,
            dayPart: dayPart(hour: hour),
            festivals: festivals,
            weather: weatherCache.weatherTag,
            tempBand: weatherCache.tempBand,
            solarTerm: solarTerm,
            geoRegion: region,
            altitudeBand: altitude,
            geoCell: GeoContext.geoCell(
                defaults: defaults,
                allowCachedLocationContext: allowLocationContext
            ),
            locationSource: GeoContext.locationSource(
                defaults: defaults,
                allowCachedLocationContext: allowLocationContext
            ),
            localeID: Locale.current.identifier
        )
    }

    /// 中国常用气象季：3–5 春，6–8 夏，9–11 秋，12–2 冬
    static func meteorologicalSeason(month: Int) -> String {
        switch month {
        case 3, 4, 5: return "spring"
        case 6, 7, 8: return "summer"
        case 9, 10, 11: return "autumn"
        default: return "winter"
        }
    }

    static func dayPart(hour: Int) -> String {
        switch hour {
        case 5 ..< 11: return "morning"
        case 11 ..< 14: return "noon"
        case 14 ..< 18: return "afternoon"
        case 18 ..< 22: return "evening"
        default: return "late_night"
        }
    }
}
