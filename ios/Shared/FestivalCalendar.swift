import Foundation

/// 从 `festivals_cn.json` 解析节日窗口（含 pre/post 延展）。
final class FestivalCalendar {
    static let shared = FestivalCalendar()

    private struct Config: Decodable {
        struct Festival: Decodable {
            let id: String
            let ranges: [RangeEntry]
            let recurrence: Recurrence?
            let preDays: Int?
            let postDays: Int?

            enum CodingKeys: String, CodingKey {
                case id, ranges, recurrence
                case preDays = "pre_days"
                case postDays = "post_days"
            }
        }

        struct RangeEntry: Decodable {
            let start: String
            let end: String
        }

        struct Recurrence: Decodable {
            let type: String
            let month: Int
            let weekday: Int
            let ordinal: Int
        }

        let festivals: [Festival]
    }

    private let festivals: [Config.Festival]
    private let calendar = Calendar.current

    private init() {
        festivals = Self.loadFestivals()
    }

    init(data: Data) throws {
        festivals = try JSONDecoder().decode(Config.self, from: data).festivals
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
        let targetDay = cal.startOfDay(for: date)
        let year = cal.component(.year, from: date)
        for fest in festivals {
            let pre = fest.preDays ?? 0
            let post = fest.postDays ?? 0
            if let recurrence = fest.recurrence,
               let recurringDay = resolveRecurringDate(
                   recurrence: recurrence,
                   year: year,
                   calendar: cal
               ) {
                let start = cal.date(byAdding: .day, value: -pre, to: recurringDay) ?? recurringDay
                let endExclusive = cal.date(byAdding: .day, value: post + 1, to: recurringDay) ?? recurringDay
                if targetDay >= start && targetDay < endExclusive {
                    result.insert(fest.id)
                }
            }
            for range in fest.ranges {
                // 同时检查相邻 anchor year：
                // - year - 1：1 月日期可命中上一年 12 月开始的跨年窗口；
                // - year + 1：12 月日期可命中下一年 1 月节日的 preDays。
                for anchorYear in (year - 1) ... (year + 1) {
                    guard let window = resolveWindow(
                        range: range,
                        year: anchorYear,
                        calendar: cal
                    ) else { continue }
                    let windowStart = cal.startOfDay(for: window.start)
                    let windowEnd = cal.startOfDay(for: window.end)
                    let start = cal.date(
                        byAdding: .day,
                        value: -pre,
                        to: windowStart
                    ) ?? windowStart
                    let endExclusive = cal.date(
                        byAdding: .day,
                        value: post + 1,
                        to: windowEnd
                    ) ?? windowEnd
                    if targetDay >= start && targetDay < endExclusive {
                        result.insert(fest.id)
                        break
                    }
                }
            }
        }
        return result
    }

    private func resolveRecurringDate(
        recurrence: Config.Recurrence,
        year: Int,
        calendar cal: Calendar
    ) -> Date? {
        guard recurrence.type == "nth_weekday_of_month",
              (1...12).contains(recurrence.month),
              (1...7).contains(recurrence.weekday),
              recurrence.ordinal > 0,
              let first = cal.date(from: DateComponents(year: year, month: recurrence.month, day: 1))
        else { return nil }
        let firstWeekday = cal.component(.weekday, from: first)
        let offset = (recurrence.weekday - firstWeekday + 7) % 7
        let day = 1 + offset + (recurrence.ordinal - 1) * 7
        guard let candidate = cal.date(byAdding: .day, value: day - 1, to: first),
              cal.component(.month, from: candidate) == recurrence.month
        else { return nil }
        return candidate
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
