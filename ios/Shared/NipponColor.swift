import SwiftUI

struct NipponColor: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let cname: String
    let hex: String
    /// `light` = 浅色字；`dark` = 深色字
    let foreground: String

    var swiftUIColor: Color { Color(hex: hex) }

    var usesLightText: Bool { foreground == "light" }

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
        foreground: "light"
    )
}
