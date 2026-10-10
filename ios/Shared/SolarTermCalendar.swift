import Foundation

/// 当前日期所在的二十四节气（按年配置的起始日推算）。
final class SolarTermCalendar {
    static let shared = SolarTermCalendar()

    private var mutableTermsByYear: [Int: [(id: String, start: Date)]]

    private init() {
        let terms = Self.loadTerms(config: CalendarConfigStore.shared.config)
        mutableTermsByYear = terms
    }

    init(config: CalendarConfig) {
        let terms = Self.loadTerms(config: config)
        mutableTermsByYear = terms
    }

    init(data: Data) throws {
        let terms = try CalendarConfig.decodeSolarTerms(from: data)
        let config = CalendarConfig(version: 0, festivals: [], solarTerms: terms)
        let parsed = Self.loadTerms(config: config)
        mutableTermsByYear = parsed
    }

    func reloadFromStore() {
        mutableTermsByYear = Self.loadTerms(config: CalendarConfigStore.shared.config)
    }

    private static func loadTerms(config: CalendarConfig) -> [Int: [(id: String, start: Date)]] {
        let cal = ContextCalendar.calendar()
        var result: [Int: [(id: String, start: Date)]] = [:]

        for (yearKey, terms) in config.solarTerms {
            guard let year = Int(yearKey) else { continue }
            var parsed: [(id: String, start: Date)] = []
            for term in terms {
                guard let date = parseYMD(term.start, calendar: cal) else { continue }
                parsed.append((term.id, date))
            }
            parsed.sort { $0.start < $1.start }
            if !parsed.isEmpty {
                result[year] = parsed
            }
        }
        return result
    }

    private static func parseYMD(_ s: String, calendar: Calendar) -> Date? {
        let parts = s.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var c = DateComponents()
        c.year = parts[0]
        c.month = parts[1]
        c.day = parts[2]
        return calendar.date(from: c)
    }

    /// 当日节气 ID，例如 `qingming`；无配置年份时返回 `nil`。
    func activeTermID(on date: Date, calendar cal: Calendar = .current) -> String? {
        let shanghai = ContextCalendar.calendar(from: cal)
        let year = shanghai.component(.year, from: date)
        let dayStart = shanghai.startOfDay(for: date)

        if let id = latestTermID(in: year, on: dayStart, termsByYear: mutableTermsByYear) {
            return id
        }
        // Only early January can belong to the previous year's winter solstice.
        guard shanghai.component(.month, from: date) == 1,
              shanghai.component(.day, from: date) <= 6
        else { return nil }
        return latestTermID(in: year - 1, on: dayStart, termsByYear: mutableTermsByYear)
    }

    private func latestTermID(
        in year: Int,
        on dayStart: Date,
        termsByYear: [Int: [(id: String, start: Date)]]
    ) -> String? {
        guard let terms = termsByYear[year], !terms.isEmpty else { return nil }
        var active: String?
        for term in terms where dayStart >= term.start {
            active = term.id
        }
        return active
    }
}
