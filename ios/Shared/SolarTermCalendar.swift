import Foundation

/// 当前日期所在的二十四节气（按年配置的起始日推算）。
final class SolarTermCalendar {
    static let shared = SolarTermCalendar()

    private struct Config: Decodable {
        struct Term: Decodable {
            let id: String
            let start: String
        }

        let years: [String: [Term]]
    }

    private let termsByYear: [Int: [(id: String, start: Date)]]
    private let calendar = Calendar.current

    private init() {
        termsByYear = Self.loadTerms()
    }

    private static func loadTerms() -> [Int: [(id: String, start: Date)]] {
        guard let url = Bundle.main.url(forResource: "solar_terms_cn", withExtension: "json")
            ?? Bundle.main.url(forResource: "solar_terms_cn", withExtension: "json", subdirectory: "Resources"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(Config.self, from: data)
        else {
            return [:]
        }

        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        var result: [Int: [(id: String, start: Date)]] = [:]

        for (yearKey, terms) in decoded.years {
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
        var shanghai = cal
        shanghai.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? cal.timeZone
        let year = shanghai.component(.year, from: date)
        let dayStart = shanghai.startOfDay(for: date)

        if let id = latestTermID(in: year, on: dayStart) {
            return id
        }
        return latestTermID(in: year - 1, on: dayStart)
    }

    private func latestTermID(in year: Int, on dayStart: Date) -> String? {
        guard let terms = termsByYear[year], !terms.isEmpty else { return nil }
        var active: String?
        for term in terms where dayStart >= term.start {
            active = term.id
        }
        return active
    }
}
