import SwiftUI
import WidgetKit

struct PhraseEntry: TimelineEntry {
    let date: Date
    let phraseText: String
    let dayKey: String
    let colorHex: String
    let colorCname: String
    let colorName: String
    let usesLightText: Bool
}

struct PhraseTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PhraseEntry {
        sampleEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (PhraseEntry) -> Void) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PhraseEntry>) -> Void) {
        let now = Date()
        let entry = makeEntry(for: now)
        let nextRefresh = nextMidnight(after: now)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func makeEntry(for date: Date) -> PhraseEntry {
        let bundle = Bundle.main
        let phrases = PhraseStore.loadPhrases(from: bundle) ?? []
        let colors = NipponColorStore.loadColors(from: bundle)
        let dayKey = PhraseStore.dayKey(for: date)

        let phraseIndex = PhraseStore.stableIndex(for: dayKey, count: max(phrases.count, 1))
        let colorIndex = PhraseStore.stableIndex(for: dayKey + "|color", count: max(colors.count, 1))

        let phrase = phrases.isEmpty
            ? Phrase(id: "fallback", text: "先缓一缓", textEn: "Pause, and soften", layer: "anchor", emotionTheme: "light_comfort")
            : phrases[phraseIndex]
        let nippon = colors.isEmpty ? NipponColor(id: "011", name: "nakabeni", cname: "中紅", hex: "DB4D6D", foreground: "light") : colors[colorIndex]

        if let defaults = UserDefaults(suiteName: AppConstants.appGroupID) {
            defaults.set(phrase.text, forKey: AppConstants.sharedTodayPhraseKey)
            defaults.set(dayKey, forKey: AppConstants.sharedTodayDayKeyKey)
            defaults.set(nippon.hex, forKey: AppConstants.sharedTodayColorHexKey)
            defaults.set(nippon.cname, forKey: AppConstants.sharedTodayColorCnameKey)
            defaults.set(nippon.name, forKey: AppConstants.sharedTodayColorNameKey)
            defaults.set(nippon.foreground, forKey: AppConstants.sharedTodayColorForegroundKey)
        }

        return PhraseEntry(
            date: date,
            phraseText: phrase.text,
            dayKey: dayKey,
            colorHex: nippon.hex,
            colorCname: nippon.cname,
            colorName: nippon.name,
            usesLightText: nippon.usesLightText
        )
    }

    private func sampleEntry() -> PhraseEntry {
        PhraseEntry(
            date: Date(),
            phraseText: "先缓一缓",
            dayKey: PhraseStore.dayKey(for: Date()),
            colorHex: "DB4D6D",
            colorCname: "中紅",
            colorName: "nakabeni",
            usesLightText: true
        )
    }

    private func nextMidnight(after date: Date) -> Date {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        return cal.date(byAdding: .day, value: 1, to: start) ?? date.addingTimeInterval(86400)
    }
}

// MARK: - 主屏

struct OraculoHomeWidget: Widget {
    let kind = "OraculoHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PhraseTimelineProvider()) { entry in
            HomeWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(hex: entry.colorHex)
                }
        }
        .configurationDisplayName("Oraculo")
        .description("每日一句，每日一色。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 锁屏

struct OraculoLockInlineWidget: Widget {
    let kind = "OraculoLockInline"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PhraseTimelineProvider()) { entry in
            LockInlineView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Oraculo（锁屏条）")
        .description("锁屏一行：今日短签。")
        .supportedFamilies([.accessoryInline])
    }
}

struct OraculoLockRectangularWidget: Widget {
    let kind = "OraculoLockRectangular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PhraseTimelineProvider()) { entry in
            LockRectangularView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(hex: entry.colorHex).opacity(0.35)
                }
        }
        .configurationDisplayName("Oraculo（锁屏块）")
        .description("锁屏矩形：短签 + 色名。")
        .supportedFamilies([.accessoryRectangular])
    }
}
