import Foundation

/// 情境下发元数据：通用库、季节/节日硬门槛、情境加权、色板情绪偏好。
struct PhraseDispatch: Codable, Equatable, Hashable {
    /// 通用库：任意季节均可进入候选池（仍受 `onlyWhen` 约束）。
    var universal: Bool
    /// 非空时须至少命中其一，否则权重为 0（硬排除）。例：`season:spring`。
    var onlyWhen: [String]
    /// 情境匹配时叠加权重（加权随机，非独占）。
    var boost: [PhraseTagBoost]
    /// 命中时乘以惩罚系数。
    var negative: [String]?
    /// 偏好的色情绪桶（warm/cool/light/dark），命中时色权重 ×2。空表示无偏好。
    var colorMoods: [String]?
    /// 禁忌的色情绪桶。命中时硬剔除——「我爱你」配灰黑、"冷静下来"配红的反讽场景。
    /// 实际剔除时如剩余池过小（< 30），算法会回落为不剔除只降权。
    var colorBan: [String]?

    static let fallback = PhraseDispatch(
        universal: true,
        onlyWhen: [],
        boost: [],
        negative: nil,
        colorMoods: nil,
        colorBan: nil
    )
}

struct PhraseTagBoost: Codable, Equatable, Hashable {
    var tag: String
    var weight: Double
}
