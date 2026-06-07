import SwiftUI
import WidgetKit

struct PhraseEntry: TimelineEntry {
    let date: Date
    let phraseText: String
    let phraseTextEn: String
    let dayKey: String
    let colorHex: String
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
        let dayKey = PhraseStore.dayKey(for: date)
        let dailyOracle = DailyOracleService()

        // 主 App 打开/摇一摇后会写入 App Group；今日 entry 优先与主屏同步。
        let isToday = dayKey == PhraseStore.dayKey(for: Date())
        if (persistTodaySharedDefaults || isToday),
           let snapshot = dailyOracle.loadDisplayedSnapshot(for: date) {
            return PhraseEntry(
                date: date,
                phraseText: snapshot.phraseText,
                phraseTextEn: snapshot.phraseTextEn,
                dayKey: snapshot.dayKey,
                colorHex: snapshot.colorHex,
                usesLightText: snapshot.usesLightText
            )
        }

        let colors = NipponColorStore.loadColors(from: .main)

        // 用户今日尚未打开 App：按情境推算今日一句（与旧逻辑一致）。
        let phrase = PhraseStore.shared.contextualPhrase(for: date)
        let colorSeed = "\(dayKey)|color|\(InstallID.value)"
        let nippon: NipponColor
        if colors.isEmpty {
            nippon = NipponColor.fallback
        } else {
            let colorDispatch = phrase.effectiveColorDispatch
            let pool = ColorMoodPicker.candidatePool(from: colors, dispatch: colorDispatch)
            nippon = ColorMoodPicker.pick(from: pool, dispatch: colorDispatch, seed: colorSeed)
        }

        return PhraseEntry(
            date: date,
            phraseText: phrase.text,
            phraseTextEn: phrase.textEn,
            dayKey: dayKey,
            colorHex: nippon.hex,
            usesLightText: nippon.usesLightText
        )
    }

    private func sampleEntry() -> PhraseEntry {
        PhraseEntry(
            date: Date(),
            phraseText: "先缓一缓",
            phraseTextEn: "Pause, and soften",
            dayKey: PhraseStore.dayKey(for: Date()),
            colorHex: "DB4D6D",
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
        .description("锁屏矩形：图标 + 中英文短签。")
        .supportedFamilies([.accessoryRectangular])
    }
}
