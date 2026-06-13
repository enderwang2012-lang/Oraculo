import SwiftUI
import WidgetKit

struct HomeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PhraseEntry

    private var phraseSize: CGFloat {
        family == .systemSmall ? 21 : 28
    }

    private var subtitleSize: CGFloat {
        family == .systemSmall ? 11 : 12
    }

    private var contentPadding: CGFloat {
        family == .systemSmall ? 14 : 16
    }

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 4 : 5) {
            OraculoTypography.phraseText(entry.phraseText, size: phraseSize)
                .foregroundStyle(entry.primaryTextColor)
                .multilineTextAlignment(.leading)
                .lineLimit(family == .systemSmall ? 4 : 2)
                .minimumScaleFactor(0.88)

            if entry.hasSubtitle {
                OraculoTypography.latinText(entry.phraseTextEn, size: subtitleSize)
                    .foregroundStyle(entry.secondaryTextColor)
                    .multilineTextAlignment(.leading)
                    .tracking(0.4)
                    .lineLimit(family == .systemSmall ? 2 : 1)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(contentPadding)
    }
}

struct LockInlineView: View {
    let entry: PhraseEntry
    private let lockTextColor = Color.white

    var body: some View {
        (Text(Image("WidgetMarkInline")) + Text(" ") + Text(entry.phraseText))
            .foregroundStyle(lockTextColor)
            .lineLimit(1)
    }
}

struct LockRectangularView: View {
    let entry: PhraseEntry
    private let lockTextColor = Color.white

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            OraculoWidgetMark(size: 56, emphasized: true)
                .offset(y: -6)
                .layoutPriority(1)
                .foregroundStyle(lockTextColor)

            VStack(alignment: .leading, spacing: 2) {
                OraculoTypography.styledText(
                    entry.phraseText,
                    size: 19,
                    chineseWeight: .semibold,
                    latinWeight: .medium
                )
                .foregroundStyle(lockTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.9)

                if entry.hasSubtitle {
                    OraculoTypography.latinText(entry.phraseTextEn, size: 12, weight: .regular)
                        .foregroundStyle(lockTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .init(horizontal: .leading, vertical: .center))
    }
}

extension PhraseEntry {
    var hasSubtitle: Bool {
        !phraseTextEn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var primaryTextColor: Color {
        textPalette.primary
    }

    var secondaryTextColor: Color {
        textPalette.secondary
    }

    private var textPalette: NipponTextPalette {
        NipponColor(
            id: "widget-entry",
            name: "",
            cname: "",
            hex: colorHex,
            foreground: usesLightText ? "light" : "dark",
            family: colorFamily,
            textMode: colorTextMode.flatMap(NipponTextMode.init(rawValue:))
        ).textPalette
    }
}
