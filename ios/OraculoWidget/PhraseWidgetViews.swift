import SwiftUI
import WidgetKit

struct HomeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PhraseEntry

    private var primary: Color {
        entry.usesLightText ? .white.opacity(0.95) : Color(white: 0.12)
    }

    private var secondary: Color {
        entry.usesLightText ? .white.opacity(0.5) : Color(white: 0.12).opacity(0.45)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            OraculoTypography.metaText(entry.colorCname, size: 11)
                .foregroundStyle(secondary)
            Spacer(minLength: 0)
            OraculoTypography.phraseText(entry.phraseText, size: family == .systemSmall ? 17 : 22)
                .foregroundStyle(primary)
                .multilineTextAlignment(.leading)
                .lineLimit(family == .systemSmall ? 4 : 3)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            OraculoTypography.latinText(entry.colorName.uppercased(), size: 9, weight: .medium)
                .foregroundStyle(secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
    }
}

struct LockInlineView: View {
    let entry: PhraseEntry

    var body: some View {
        OraculoTypography.phraseText(entry.phraseText, size: 12)
            .lineLimit(1)
    }
}

struct LockRectangularView: View {
    let entry: PhraseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            OraculoTypography.metaText("\(entry.colorCname) · \(entry.colorHex)", size: 11)
            OraculoTypography.phraseText(entry.phraseText, size: 15)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
