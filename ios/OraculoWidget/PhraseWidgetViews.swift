import SwiftUI
import WidgetKit

struct HomeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PhraseEntry

    private var primary: Color {
        entry.usesLightText ? .white.opacity(0.95) : Color(white: 0.12)
    }

    private var secondary: Color {
        entry.usesLightText ? .white.opacity(0.48) : Color(white: 0.12).opacity(0.42)
    }

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
                .foregroundStyle(primary)
                .multilineTextAlignment(.leading)
                .lineLimit(family == .systemSmall ? 4 : 2)
                .minimumScaleFactor(0.88)

            if entry.hasSubtitle {
                OraculoTypography.latinText(entry.phraseTextEn, size: subtitleSize)
                    .foregroundStyle(secondary)
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

    var body: some View {
        HStack(spacing: 4) {
            OraculoWidgetMark(size: 28, emphasized: true)
                .offset(y: -1)
            OraculoTypography.styledText(
                entry.phraseText,
                size: 13,
                chineseWeight: .semibold,
                latinWeight: .medium
            )
            .lineLimit(1)
        }
    }
}

struct LockRectangularView: View {
    let entry: PhraseEntry

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            OraculoWidgetMark(size: 56, emphasized: true)
                .offset(y: -6)
                .layoutPriority(1)

            VStack(alignment: .leading, spacing: 2) {
                OraculoTypography.styledText(
                    entry.phraseText,
                    size: 19,
                    chineseWeight: .semibold,
                    latinWeight: .medium
                )
                .lineLimit(2)
                .minimumScaleFactor(0.9)

                if entry.hasSubtitle {
                    OraculoTypography.latinText(entry.phraseTextEn, size: 12, weight: .regular)
                        .foregroundStyle(.secondary)
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
}
