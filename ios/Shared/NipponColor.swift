import SwiftUI

struct NipponColor: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let cname: String
    let hex: String
    /// `light` = 浅色字；`dark` = 深色字
    let foreground: String
    /// 情绪桶（4 桶：warm/cool/light/dark），由 `scripts/tag_color_moods.py` 生成。
    /// 旧色板 JSON 无此字段，默认空数组——选色算法对空数组按"无情绪信息"处理。
    let moods: [String]

    var swiftUIColor: Color { Color(hex: hex) }

    var usesLightText: Bool { foreground == "light" }

    init(
        id: String,
        name: String,
        cname: String,
        hex: String,
        foreground: String,
        moods: [String] = []
    ) {
        self.id = id
        self.name = name
        self.cname = cname
        self.hex = hex
        self.foreground = foreground
        self.moods = moods
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        cname = try c.decode(String.self, forKey: .cname)
        hex = try c.decode(String.self, forKey: .hex)
        foreground = try c.decode(String.self, forKey: .foreground)
        moods = try c.decodeIfPresent([String].self, forKey: .moods) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, cname, hex, foreground, moods
    }

    var primaryTextColor: Color {
        usesLightText ? Color.white.opacity(0.96) : Color(white: 0.12)
    }

    var secondaryTextColor: Color {
        usesLightText ? Color.white.opacity(0.52) : Color(white: 0.12).opacity(0.45)
    }

    var displayLabel: String { "\(cname) · \(name)" }

    /// 色板缺失时的统一兜底色（中紅 nakabeni），全工程唯一来源。
    static let fallback = NipponColor(
        id: "011",
        name: "nakabeni",
        cname: "中紅",
        hex: "DB4D6D",
        foreground: "light",
        moods: ["warm"]
    )
}
