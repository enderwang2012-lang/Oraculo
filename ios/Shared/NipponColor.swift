import SwiftUI

struct NipponTextPalette: Equatable {
    let primaryHex: String
    let secondaryHex: String
    let tertiaryHex: String
    let primaryOpacity: Double
    let secondaryOpacity: Double
    let tertiaryOpacity: Double

    var primary: Color { Color(hex: primaryHex).opacity(primaryOpacity) }
    var secondary: Color { Color(hex: secondaryHex).opacity(secondaryOpacity) }
    var tertiary: Color { Color(hex: tertiaryHex).opacity(tertiaryOpacity) }
}

enum NipponTextMode: String, Decodable, Hashable {
    case ink
    case paper
    case softInk
}

struct NipponColor: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let cname: String
    let hex: String
    /// `light` = 浅色字；`dark` = 深色字
    let foreground: String
    /// 情绪桶（4 桶：warm/cool/light/dark），由 `scripts/tag_color_moods.py` 生成。
    /// 旧色板 JSON 无此字段，默认空数组——选色算法对空数组按"无情绪信息"处理。
    let moods: [String]
    /// 情境亲和扁平标签（如 `season:spring` `festival:spring_festival` `weather:snow`），
    /// 由 `scripts/tag_color_context.py` 生成。命中当前 ContextSnapshot 时该色加权——「颜色也应景」。
    /// 旧 JSON 无此字段，默认空数组（不影响选色）。
    let contextTags: [String]
    /// 细色族（red/orange/.../black），由 `scripts/tag_color_context.py` 按 HSL 归类。
    /// 语料 dispatch.colorFamilies 命中此族时加权。旧 JSON 无此字段默认空串。
    let family: String
    /// 字色模式：ink 深墨、paper 柔白、softInk 中亮高彩背景的柔墨。
    let textMode: NipponTextMode?

    var swiftUIColor: Color { Color(hex: hex) }

    var usesLightText: Bool { foreground == "light" }

    init(
        id: String,
        name: String,
        cname: String,
        hex: String,
        foreground: String,
        moods: [String] = [],
        contextTags: [String] = [],
        family: String = "",
        textMode: NipponTextMode? = nil
    ) {
        self.id = id
        self.name = name
        self.cname = cname
        self.hex = hex
        self.foreground = foreground
        self.moods = moods
        self.contextTags = contextTags
        self.family = family
        self.textMode = textMode
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        cname = try c.decode(String.self, forKey: .cname)
        hex = try c.decode(String.self, forKey: .hex)
        foreground = try c.decode(String.self, forKey: .foreground)
        moods = try c.decodeIfPresent([String].self, forKey: .moods) ?? []
        // context 以 {season:[],festival:[],weather:[]} 存储，扁平化成 "dim:value" 直接匹配 activeTags。
        if let ctx = try c.decodeIfPresent([String: [String]].self, forKey: .context) {
            contextTags = ctx.flatMap { dim, values in values.map { "\(dim):\($0)" } }.sorted()
        } else {
            contextTags = try c.decodeIfPresent([String].self, forKey: .contextTags) ?? []
        }
        family = try c.decodeIfPresent(String.self, forKey: .family) ?? ""
        textMode = try c.decodeIfPresent(NipponTextMode.self, forKey: .textMode)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, cname, hex, foreground, moods, context, contextTags, family, textMode
    }

    var primaryTextColor: Color {
        textPalette.primary
    }

    var secondaryTextColor: Color {
        textPalette.secondary
    }

    var tertiaryTextColor: Color {
        textPalette.tertiary
    }

    var textPalette: NipponTextPalette {
        switch resolvedTextMode {
        case .paper:
            return paperPalette
        case .softInk:
            return softInkPalette
        case .ink:
            return inkPalette
        }
    }

    /// 色板缺失时的统一兜底色（中紅 nakabeni），全工程唯一来源。
    static let fallback = NipponColor(
        id: "011",
        name: "nakabeni",
        cname: "中紅",
        hex: "DB4D6D",
        foreground: "light",
        moods: ["warm"],
        family: "red",
        textMode: .softInk
    )
}

private extension NipponColor {
    enum TextMode {
        case ink
        case paper
        case softInk
    }

    private var resolvedTextMode: TextMode {
        switch textMode {
        case .ink:
            return .ink
        case .paper:
            return .paper
        case .softInk:
            return .softInk
        case nil:
            return usesLightText ? .paper : .ink
        }
    }

    var inkPalette: NipponTextPalette {
        if family == "orange" || family == "yellow" || family == "brown" {
            return NipponTextPalette(
                primaryHex: "2F2118",
                secondaryHex: "5E422F",
                tertiaryHex: "6D4D38",
                primaryOpacity: 1,
                secondaryOpacity: 0.66,
                tertiaryOpacity: 0.54
            )
        }

        if family == "blue" || family == "green" {
            return NipponTextPalette(
                primaryHex: "202B2A",
                secondaryHex: "3B4F4C",
                tertiaryHex: "4F6460",
                primaryOpacity: 1,
                secondaryOpacity: 0.66,
                tertiaryOpacity: 0.54
            )
        }

        if family == "purple" {
            return NipponTextPalette(
                primaryHex: "282532",
                secondaryHex: "464052",
                tertiaryHex: "5B5369",
                primaryOpacity: 1,
                secondaryOpacity: 0.66,
                tertiaryOpacity: 0.54
            )
        }

        if family == "gray" || family == "pink" || family == "red" {
            return NipponTextPalette(
                primaryHex: "2E2926",
                secondaryHex: "4F3A3D",
                tertiaryHex: "5F474B",
                primaryOpacity: 1,
                secondaryOpacity: 0.68,
                tertiaryOpacity: 0.56
            )
        }

        return NipponTextPalette(
            primaryHex: "2A2724",
            secondaryHex: "514844",
            tertiaryHex: "655A55",
            primaryOpacity: 1,
            secondaryOpacity: 0.64,
            tertiaryOpacity: 0.52
        )
    }

    var paperPalette: NipponTextPalette {
        if family == "blue" || family == "purple" {
            return NipponTextPalette(
                primaryHex: "F7F4EF",
                secondaryHex: "F7F4EF",
                tertiaryHex: "F7F4EF",
                primaryOpacity: 0.96,
                secondaryOpacity: 0.72,
                tertiaryOpacity: 0.46
            )
        }

        if family == "green" || family == "yellow" {
            return NipponTextPalette(
                primaryHex: "F8F5EA",
                secondaryHex: "F8F5EA",
                tertiaryHex: "F8F5EA",
                primaryOpacity: 0.96,
                secondaryOpacity: 0.72,
                tertiaryOpacity: 0.44
            )
        }

        if family == "red" || family == "pink" || family == "orange" || family == "brown" {
            return NipponTextPalette(
                primaryHex: "FFF4EF",
                secondaryHex: "FFF4EF",
                tertiaryHex: "FFF4EF",
                primaryOpacity: 0.96,
                secondaryOpacity: 0.72,
                tertiaryOpacity: 0.45
            )
        }

        return NipponTextPalette(
            primaryHex: "F6F3EE",
            secondaryHex: "F6F3EE",
            tertiaryHex: "F6F3EE",
            primaryOpacity: 0.96,
            secondaryOpacity: 0.7,
            tertiaryOpacity: 0.44
        )
    }

    var softInkPalette: NipponTextPalette {
        if family == "orange" || family == "yellow" || family == "brown" {
            return NipponTextPalette(
                primaryHex: "2F2118",
                secondaryHex: "5E422F",
                tertiaryHex: "6D4D38",
                primaryOpacity: 0.94,
                secondaryOpacity: 0.76,
                tertiaryOpacity: 0.62
            )
        }

        if family == "blue" || family == "green" {
            return NipponTextPalette(
                primaryHex: "202B2A",
                secondaryHex: "3B4F4C",
                tertiaryHex: "4F6460",
                primaryOpacity: 0.94,
                secondaryOpacity: 0.76,
                tertiaryOpacity: 0.62
            )
        }

        if family == "purple" {
            return NipponTextPalette(
                primaryHex: "282532",
                secondaryHex: "464052",
                tertiaryHex: "5B5369",
                primaryOpacity: 0.94,
                secondaryOpacity: 0.76,
                tertiaryOpacity: 0.62
            )
        }

        if family == "gray" || family == "pink" || family == "red" {
            return NipponTextPalette(
                primaryHex: "2E2926",
                secondaryHex: "4F3A3D",
                tertiaryHex: "5F474B",
                primaryOpacity: 0.94,
                secondaryOpacity: 0.76,
                tertiaryOpacity: 0.62
            )
        }

        return NipponTextPalette(
            primaryHex: "2A2724",
            secondaryHex: "514844",
            tertiaryHex: "655A55",
            primaryOpacity: 0.94,
            secondaryOpacity: 0.74,
            tertiaryOpacity: 0.6
        )
    }
}

/// 跨进程、跨版本稳定的 FNV-1a 种子工具，避免使用会漂移的 `hashValue`。
enum StableSeed {
    static func index(for seed: String, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return Int(hash64(for: seed) % UInt64(count))
    }

    static func hash64(for string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        let prime: UInt64 = 0x100000001b3
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= prime
        }
        return hash
    }
}

/// App 与 Widget 共用的每日选色入口，确保种子、禁色、情绪和情境权重完全一致。
enum DailyColorSelector {
    static func color(
        from colors: [NipponColor],
        dispatch: PhraseDispatch?,
        dayKey: String,
        installID: String,
        contextTags: Set<String> = []
    ) -> NipponColor {
        guard !colors.isEmpty else { return NipponColor.fallback }
        let seed = "\(dayKey)|color|\(installID)"
        let pool = ColorMoodPicker.candidatePool(from: colors, dispatch: dispatch)
        guard !pool.isEmpty else {
            return colors[StableSeed.index(for: seed, count: colors.count)]
        }
        return ColorMoodPicker.pick(
            from: pool,
            dispatch: dispatch,
            seed: seed,
            contextTags: contextTags
        )
    }
}

/// 与 PhrasePicker 对称：从色板里按 colorMoods/colorBan 挑色。
enum ColorMoodPicker {
    /// 池低于此值时停止 ban，回落为只加权——避免长期看到同样几个色。
    static let minPoolSize = 30
    static let moodBoostMultiplier: Double = 2.0
    /// 情境亲和加权：命中当前 context 标签的色再乘此系数（与 mood 加权可叠乘）。
    static let contextBoostMultiplier: Double = 2.0
    /// 细色族加权：命中句 colorFamilies 的色再乘此系数（比 mood 更精确，故更强）。
    static let familyBoostMultiplier: Double = 3.0

    static func candidatePool(
        from colors: [NipponColor],
        dispatch: PhraseDispatch?
    ) -> [NipponColor] {
        guard let bans = dispatch?.colorBan, !bans.isEmpty else { return colors }
        let banSet = Set(bans)
        let filtered = colors.filter { color in
            color.moods.allSatisfy { !banSet.contains($0) }
        }
        return filtered.count >= minPoolSize ? filtered : colors
    }

    static func pick(
        from pool: [NipponColor],
        dispatch: PhraseDispatch?,
        seed: String,
        contextTags: Set<String> = []
    ) -> NipponColor {
        guard !pool.isEmpty else { return NipponColor.fallback }
        let moods = Set(dispatch?.colorMoods ?? [])
        let families = Set(dispatch?.colorFamilies ?? [])
        if moods.isEmpty && families.isEmpty && contextTags.isEmpty {
            // 无情绪偏好、无色族偏好、无情境信息：均匀切片，与原行为一致。
            return pool[StableSeed.index(for: seed, count: pool.count)]
        }

        let weights: [Double] = pool.map { color in
            var weight = 1.0
            if !moods.isEmpty, color.moods.contains(where: { moods.contains($0) }) {
                weight *= moodBoostMultiplier
            }
            if !families.isEmpty, families.contains(color.family) {
                weight *= familyBoostMultiplier
            }
            if !contextTags.isEmpty,
               color.contextTags.contains(where: { contextTags.contains($0) }) {
                weight *= contextBoostMultiplier
            }
            return weight
        }
        let total = weights.reduce(0, +)
        guard total > 0 else { return pool[0] }

        let unit = Double(StableSeed.hash64(for: seed) % 1_000_000) / 1_000_000.0
        var roll = unit * total
        for (color, weight) in zip(pool, weights) {
            roll -= weight
            if roll <= 0 { return color }
        }
        return pool.last ?? NipponColor.fallback
    }
}
