import SwiftUI
import UIKit

/// 中文：宋体-简 Songti SC（衬线，对齐 nipponcolors 主标题气质）；英文与数字：Helvetica。
enum OraculoTypography {
    // MARK: - 单语族字体

    static func chineseFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name = songtiName(for: weight)
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight)
    }

    static func latinFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name = helveticaName(for: weight)
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight, design: .default)
    }

    /// 按字符切换宋体 / Helvetica，用于混排正文。
    static func styledText(
        _ string: String,
        size: CGFloat,
        chineseWeight: Font.Weight = .regular,
        latinWeight: Font.Weight = .regular
    ) -> Text {
        var composed = Text("")
        var run = ""
        var runIsLatin: Bool?

        func flush() {
            guard !run.isEmpty, let isLatin = runIsLatin else { return }
            let font = isLatin
                ? latinFont(size: size, weight: latinWeight)
                : chineseFont(size: size, weight: chineseWeight)
            composed = composed + Text(run).font(font)
            run = ""
        }

        for character in string {
            let isLatin = character.usesOraculoLatinFont
            if let current = runIsLatin, current != isLatin {
                flush()
            }
            runIsLatin = isLatin
            run.append(character)
        }
        flush()

        if runIsLatin == nil {
            return Text("")
        }
        return composed
    }

    static func phraseText(_ string: String, size: CGFloat) -> Text {
        styledText(string, size: size, chineseWeight: .regular, latinWeight: .light)
    }

    static func metaText(_ string: String, size: CGFloat) -> Text {
        styledText(string, size: size, chineseWeight: .regular, latinWeight: .regular)
    }

    /// 纯英文 / 数字（如色名罗马字、HEX）。
    static func latinText(_ string: String, size: CGFloat, weight: Font.Weight = .regular) -> Text {
        Text(string).font(latinFont(size: size, weight: weight))
    }

    // MARK: - Widget / 兼容

    @available(*, deprecated, message: "Use phraseText(_:size:)")
    static func phraseFont(size: CGFloat) -> Font {
        chineseFont(size: size, weight: .regular)
    }

    @available(*, deprecated, message: "Use metaText(_:size:)")
    static func metaFont(size: CGFloat) -> Font {
        chineseFont(size: size)
    }

    // MARK: - PostScript 名称

    private static func songtiName(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light: "STSongti-SC-Light"
        case .semibold, .bold, .heavy, .black: "STSongti-SC-Bold"
        case .medium: "STSongti-SC-Regular"
        default: "STSongti-SC-Regular"
        }
    }

    private static func helveticaName(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light: "Helvetica-Light"
        case .medium, .semibold, .bold, .heavy, .black: "Helvetica-Bold"
        default: "Helvetica"
        }
    }
}

private extension Character {
    /// 英文与数字走 Helvetica；其余（含中文、中文标点）走 Songti SC。
    var usesOraculoLatinFont: Bool {
        for scalar in unicodeScalars {
            guard scalar.isASCII else { return false }
            if CharacterSet.letters.contains(scalar) || CharacterSet.decimalDigits.contains(scalar) {
                return true
            }
        }
        return false
    }
}
