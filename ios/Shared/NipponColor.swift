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
}
