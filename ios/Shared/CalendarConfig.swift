import Foundation

struct CalendarConfig: Codable, Equatable {
    let version: Int
    let timezone: String
    let festivals: [FestivalDefinition]
    let solarTerms: [String: [SolarTermDefinition]]

    enum CodingKeys: String, CodingKey {
        case version
        case timezone
        case festivals
        case solarTerms = "solar_terms"
    }

    init(
        version: Int,
        timezone: String = "Asia/Shanghai",
        festivals: [FestivalDefinition],
        solarTerms: [String: [SolarTermDefinition]]
    ) {
        self.version = version
        self.timezone = timezone
        self.festivals = festivals
        self.solarTerms = solarTerms
    }

    static func from(
        festivalsData: Data,
        solarTermsData: Data,
        version: Int
    ) throws -> CalendarConfig {
        let festivalFile = try JSONDecoder().decode(FestivalFile.self, from: festivalsData)
        let solarTermFile = try JSONDecoder().decode(SolarTermFile.self, from: solarTermsData)
        return CalendarConfig(
            version: version,
            festivals: festivalFile.festivals,
            solarTerms: solarTermFile.years
        )
    }

    static func decodeFestivalDefinitions(from data: Data) throws -> [FestivalDefinition] {
        try JSONDecoder().decode(FestivalFile.self, from: data).festivals
    }

    static func decodeSolarTerms(from data: Data) throws -> [String: [SolarTermDefinition]] {
        try JSONDecoder().decode(SolarTermFile.self, from: data).years
    }

    var isValid: Bool {
        guard timezone == ContextCalendar.timezoneIdentifier,
              Set(festivals.map(\.id)).count == festivals.count
        else { return false }
        for festival in festivals {
            guard !festival.id.isEmpty,
                  (festival.preDays ?? 0) >= 0, (festival.postDays ?? 0) >= 0,
                  festival.ranges.allSatisfy({
                      Self.isValidDateToken($0.start) && Self.isValidDateToken($0.end)
                  })
            else { return false }
            if let recurrence = festival.recurrence {
                guard recurrence.type == "nth_weekday_of_month",
                      (1...12).contains(recurrence.month),
                      (1...7).contains(recurrence.weekday),
                      (1...5).contains(recurrence.ordinal)
                else { return false }
            }
        }
        return solarTerms.allSatisfy { year, terms in
            Int(year) != nil && Set(terms.map(\.id)).count == terms.count
                && terms.allSatisfy { term in
                    term.start.hasPrefix("\(year)-") && Self.isValidDateToken(term.start)
                }
        }
    }

    static func isValidDateToken(_ token: String) -> Bool {
        let full = token.count == 5 ? "2000-\(token)" : token
        let parts = full.split(separator: "-").compactMap { Int($0) }
        guard full.count == 10, parts.count == 3 else { return false }
        let calendar = ContextCalendar.calendar()
        guard let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])) else {
            return false
        }
        let result = calendar.dateComponents([.year, .month, .day], from: date)
        return result.year == parts[0] && result.month == parts[1] && result.day == parts[2]
    }

    private struct FestivalFile: Decodable {
        let festivals: [FestivalDefinition]
    }

    private struct SolarTermFile: Decodable {
        let years: [String: [SolarTermDefinition]]
    }
}

struct FestivalDefinition: Codable, Equatable, Hashable {
    let id: String
    let name: String?
    let ranges: [FestivalDateRange]
    let recurrence: FestivalRecurrence?
    let preDays: Int?
    let postDays: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case ranges
        case recurrence
        case preDays = "pre_days"
        case postDays = "post_days"
    }

    init(
        id: String,
        name: String? = nil,
        ranges: [FestivalDateRange],
        recurrence: FestivalRecurrence?,
        preDays: Int?,
        postDays: Int?
    ) {
        self.id = id
        self.name = name
        self.ranges = ranges
        self.recurrence = recurrence
        self.preDays = preDays
        self.postDays = postDays
    }
}

struct FestivalDateRange: Codable, Equatable, Hashable {
    let start: String
    let end: String
}

struct FestivalRecurrence: Codable, Equatable, Hashable {
    let type: String
    let month: Int
    let weekday: Int
    let ordinal: Int
}

struct SolarTermDefinition: Codable, Equatable, Hashable {
    let id: String
    let name: String?
    let start: String

    init(id: String, name: String? = nil, start: String) {
        self.id = id
        self.name = name
        self.start = start
    }
}

enum ContextCalendar {
    static let timezoneIdentifier = "Asia/Shanghai"

    static func calendar(from input: Calendar = .current) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timezoneIdentifier) ?? input.timeZone
        return calendar
    }
}
