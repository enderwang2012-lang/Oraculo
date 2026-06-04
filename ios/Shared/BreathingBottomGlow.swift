import SwiftUI

/// 底部极轻径向「呼吸」：约 5.2s 一轮，吸短呼长；透明度极低，贴近「看不见但感觉得到」。
struct BreathingBottomGlow: View {
    let usesLightText: Bool

    /// 一轮呼吸周期（秒），对齐放松静息
    private let period: TimeInterval = 5.2
    /// 吸气占周期比例（余下为呼气，略长更自然）
    private let inhaleFraction: Double = 0.38
    private let opacityMin: Double = 0.010
    private let opacityMax: Double = 0.030
    private let glowRadiusFactor: CGFloat = 0.44

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { context in
            GeometryReader { geo in
                let strength = breathingStrength(at: context.date)
                let opacity = opacityMin + (opacityMax - opacityMin) * strength
                let glow = usesLightText ? Color.white : Color.black
                let endRadius = max(geo.size.width, geo.size.height) * glowRadiusFactor

                RadialGradient(
                    stops: [
                        .init(color: glow.opacity(opacity), location: 0),
                        .init(color: glow.opacity(opacity * 0.42), location: 0.38),
                        .init(color: .clear, location: 1),
                    ],
                    center: UnitPoint(x: 0.5, y: 1.0),
                    startRadius: 0,
                    endRadius: endRadius
                )
                .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }

    /// 0…1，吸短呼长的平滑起伏（`TimelineView` 保证换色时相位不重置）
    private func breathingStrength(at date: Date) -> Double {
        let t = date.timeIntervalSince1970.truncatingRemainder(dividingBy: period) / period
        if t < inhaleFraction {
            let u = t / inhaleFraction
            return 0.5 - 0.5 * cos(.pi * u)
        }
        let u = (t - inhaleFraction) / (1 - inhaleFraction)
        return 0.5 + 0.5 * cos(.pi * u)
    }
}
