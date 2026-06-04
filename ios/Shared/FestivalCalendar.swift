import Foundation

/// 从 `festivals_cn.json` 解析节日窗口（含 pre/post 延展）。
final class FestivalCalendar {
    static let shared = FestivalCalendar()

    private struct Config: Decodable {
        struct Festival: Decodable {
            let id: String
            let ranges: [RangeEntry]
            let preDays: Int?
            let postDays: Int?

            enum CodingKeys: String, CodingKey {
                case id, ranges
                case preDays = "pre_days"
                case postDays = "post_days"
            }
        }

        struct RangeEntry: Decodable {
            let start: String
            let end: String
        }

        let festivals: [Festival]
    }

    private let festivals: [Config.Festival]
    private let calendar = Calendar.current

    private init() {
        festivals = Self.loadFestivals()
    }

    private static func loadFestivals() -> [Config.Festival] {
        guard let url = Bundle.main.url(forResource: "festivals_cn", withExtension: "json")
            ?? Bundle.main.url(forResource: "festivals_cn", withExtension: "json", subdirectory: "Resources"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(Config.self, from: data)
        else {
            return []
        }
        return decoded.festivals
    }

    func activeFestivals(on date: Date, calendar cal: Calendar = .current) -> Set<String> {
        var result = Set<String>()
        let year = cal.component(.year, from: date)
        for fest in festivals {
            let pre = fest.preDays ?? 0
            let post = fest.postDays ?? 0
            for range in fest.ranges {
                guard let window = resolveWindow(range: range, year: year, calendar: cal) else { continue }
                let start = cal.date(byAdding: .day, value: -pre, to: window.start) ?? window.start
                let end = cal.date(byAdding: .day, value: post, to: window.end) ?? window.end
                if date >= start && date <= end {
                    result.insert(fest.id)
                }
            }
        }
        return result
    }

    private func resolveWindow(
        range: Config.RangeEntry,
        year: Int,
        calendar cal: Calendar
    ) -> (start: Date, end: Date)? {
        let startStr = expandDateToken(range.start, year: year)
        let endStr = expandDateToken(range.end, year: year)
        guard let start = parseYMD(startStr, calendar: cal),
              let end = parseYMD(endStr, calendar: cal)
        else { return nil }
        if end < start {
            // 跨年窗口（如元旦 12-31 → 01-02）
            if let endNext = parseYMD(expandDateToken(range.end, year: year + 1), calendar: cal) {
                return (start, endNext)
            }
        }
        return (start, end)
    }

    private func expandDateToken(_ token: String, year: Int) -> String {
        if token.contains("-") && token.count <= 5 {
            let parts = token.split(separator: "-")
            if parts.count == 2, parts[0].count <= 2 {
                return String(format: "%04d-%02d-%02d", year, Int(parts[0]) ?? 1, Int(parts[1]) ?? 1)
            }
        }
        return token
    }

    private func parseYMD(_ s: String, calendar cal: Calendar) -> Date? {
        let parts = s.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var c = DateComponents()
        c.year = parts[0]
        c.month = parts[1]
        c.day = parts[2]
        return cal.date(from: c)
    }
}
