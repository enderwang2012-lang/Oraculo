import SwiftUI
import WidgetKit

struct PhraseEntry: TimelineEntry {
    let date: Date
    let phraseText: String
    let phraseTextEn: String
    let dayKey: String
    let colorHex: String
    let usesLightText: Bool
    let colorFamily: String
    let colorTextMode: String?
}

struct PhraseTimelineProvider: TimelineProvider {
    /// 预生成未来若干天的 0 点 entry，降低 WidgetKit budget 耗尽后长期卡在旧句的概率。
    private static let futureMidnightEntryCount = 13

    func placeholder(in context: Context) -> PhraseEntry {
        sampleEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (PhraseEntry) -> Void) {
        PhraseStore.shared.reloadFromDisk()
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PhraseEntry>) -> Void) {
        PhraseStore.shared.reloadFromDisk()

        let now = Date()
        var entries: [PhraseEntry] = [makeEntry(for: now)]
        var cursor = now

        for _ in 0 ..< Self.futureMidnightEntryCount {
            let midnight = nextMidnight(after: cursor)
            entries.append(makeEntry(for: midnight))
            cursor = midnight
        }

        let reloadAfter = nextMidnight(after: cursor)
        completion(Timeline(entries: entries, policy: .after(reloadAfter)))
    }

    private func makeEntry(for date: Date) -> PhraseEntry {
        let dayKey = PhraseStore.dayKey(for: date)
        let dailyOracle = DailyOracleService()
        let isToday = dayKey == PhraseStore.dayKey(for: Date())

        // 仅「今天」读 App Group；未来 entry 一律按日种子推算，避免旧 sync 污染。
        if isToday, let snapshot = dailyOracle.loadDisplayedSnapshot(for: date) {
            return PhraseEntry(
                date: date,
                phraseText: snapshot.phraseText,
                phraseTextEn: snapshot.phraseTextEn,
                dayKey: snapshot.dayKey,
                colorHex: snapshot.colorHex,
                usesLightText: snapshot.usesLightText,
                colorFamily: snapshot.colorFamily,
                colorTextMode: snapshot.colorTextMode
            )
        }

        let colors = NipponColorStore.loadColors(from: .main)
        let phrase = PhraseStore.shared.contextualPhrase(for: date, source: .dailyAuto)
        let context = ContextSnapshotBuilder.snapshot(for: date)
        let nippon = DailyColorSelector.color(
            from: colors,
            dispatch: phrase.effectiveColorDispatch,
            dayKey: dayKey,
            installID: InstallID.value,
            contextTags: context.activeTags
        )

        let entry = PhraseEntry(
            date: date,
            phraseText: phrase.text,
            phraseTextEn: phrase.textEn,
            dayKey: dayKey,
            colorHex: nippon.hex,
            usesLightText: nippon.usesLightText,
            colorFamily: nippon.family,
            colorTextMode: nippon.textMode?.rawValue
        )

        if isToday {
            let moment = OracleMoment(phrase: phrase, nipponColor: nippon, dayKey: dayKey)
            SharedOracleMomentStore.shared.save(
                moment: moment,
                source: .dailyAuto,
                corpusVersion: PhraseStore.shared.activeCorpusVersion,
                recordExposure: !PhraseExposureHistory.shared.hasExposure(source: .dailyAuto, dayKey: dayKey),
                reloadWidgets: false
            )
        }

        return entry
    }

    private func sampleEntry() -> PhraseEntry {
        PhraseEntry(
            date: Date(),
            phraseText: "先缓一缓",
            phraseTextEn: "Pause, and soften",
            dayKey: PhraseStore.dayKey(for: Date()),
            colorHex: "DB4D6D",
            usesLightText: true,
            colorFamily: "red",
            colorTextMode: "softInk"
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
