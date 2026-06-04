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
        let cal = Calendar.current
        let m1 = nextMidnight(after: now)
        // Calendar.byAdding 处理 DST 切换；不要用 +86400 秒。
        let m2 = cal.date(byAdding: .day, value: 1, to: m1) ?? m1.addingTimeInterval(60 * 60 * 24)

        // 多 entry：今天 + 明日 0 点 + 后日 0 点。
        // 即使系统降级了刷新 budget，也至少能一路展示到第三天的 0 点，避免长时间停在过时一句。
        let entries = [
            makeEntry(for: now, persistTodaySharedDefaults: true),
            makeEntry(for: m1, persistTodaySharedDefaults: false),
            makeEntry(for: m2, persistTodaySharedDefaults: false),
        ]
        completion(Timeline(entries: entries, policy: .after(m2)))
    }

    private func makeEntry(for date: Date, persistTodaySharedDefaults: Bool = true) -> PhraseEntry {
        let colors = NipponColorStore.loadColors(from: .main)
        let dayKey = PhraseStore.dayKey(for: date)

        // 与摇一摇/主 App 共用 PhraseDispatchScorer + PhrasePicker 的情境加权（仅种子不同）。
        // 文档 docs/CONTEXTUAL_PHRASE_DISPATCH.md 的承诺在此兑现。
        let phrase = PhraseStore.shared.contextualPhrase(for: date)

        let colorIndex = PhraseStore.stableIndex(for: dayKey + "|color", count: max(colors.count, 1))
        let nippon = colors.isEmpty ? NipponColor.fallback : colors[colorIndex]

        // 主 App 的 DailyPhraseService.refreshSharedCache() 是 sharedTodayPhraseKey/sharedTodayPhraseIDKey 的权威写入方。
        // Widget 只回填颜色相关 key（主 App 暂不写颜色），避免与主 App 的写入相互覆盖。
        // 只为「今天」的 entry 写共享缓存；未来 entry 不能覆盖今天的色。
        if persistTodaySharedDefaults, let defaults = UserDefaults(suiteName: AppConstants.appGroupID) {
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
