import SwiftUI

/// 底部品牌标记：静息仅透明度吸短呼长；点按/蓄力缩放提亮；蓄力完成涟漪外扩后渐暗复位。
struct OraculoChargeMark: View {
    var glowAmount: CGFloat
    var isCharging: Bool
    var rippleExpansion: CGFloat
    var isSettling: Bool
    var settleFromGlow: CGFloat
    var settleDuration: TimeInterval
    var foregroundStyle: Color
    var size: CGFloat = 128

    private var clampedGlow: CGFloat { min(max(glowAmount, 0), 1) }
    private var isLit: Bool { clampedGlow > 0.001 }
    private var showChargeGlow: Bool { isLit || rippleExpansion > 0.001 }
    private var usesIdleBreath: Bool {
        !isLit && !isSettling && rippleExpansion < 0.001
    }

    private var markSize: CGFloat { size * 0.85 }

    private var haloFade: Double {
        guard rippleExpansion > 0 else { return 1 }
        return max(0, 1 - Double(rippleExpansion) * 0.9)
    }

    private func markScale() -> CGFloat {
        let span = OraculoMotion.chargeScaleMax - OraculoMotion.chargeScaleMin

        if isSettling {
            let startGlow = min(max(settleFromGlow, 0.001), 1)
            let startScale = OraculoMotion.chargeScaleMin + startGlow * span
            let t = clampedGlow / startGlow
            return 1 + t * (startScale - 1)
        }
        if isLit || isCharging {
            return OraculoMotion.chargeScaleMin + clampedGlow * span
        }
        return 1
    }

    private func markOpacity(idleBreath: Double) -> Double {
        if isSettling {
            let floor = OraculoMotion.markIdleOpacityMin
            let startGlow = min(max(settleFromGlow, 0.001), 1)
            let startOpacity = OraculoMotion.chargeOpacityMin
                + Double(startGlow) * (OraculoMotion.chargeOpacityMax - OraculoMotion.chargeOpacityMin)
            let t = Double(clampedGlow / startGlow)
            return floor + t * (startOpacity - floor)
        }
        if isLit {
            return OraculoMotion.chargeOpacityMin
                + Double(clampedGlow) * (OraculoMotion.chargeOpacityMax - OraculoMotion.chargeOpacityMin)
        }
        return OraculoMotion.markIdleOpacityMin
            + (OraculoMotion.markIdleOpacityMax - OraculoMotion.markIdleOpacityMin) * idleBreath
    }

    private var innerHaloScale: CGFloat { 1.25 + clampedGlow * 1.35 }

    private var innerHaloOpacity: Double {
        (0.14 + Double(clampedGlow) * 0.42) * haloFade
    }

    private var outerHaloScale: CGFloat { 1.7 + clampedGlow * 4.2 }

    private var outerHaloOpacity: Double {
        Double(clampedGlow) * 0.38 * haloFade
    }

    private var farHaloScale: CGFloat { 2.4 + clampedGlow * 6.2 }

    private var farHaloOpacity: Double {
        Double(clampedGlow) * 0.28 * haloFade
    }

    private var ultraHaloScale: CGFloat { 3.2 + clampedGlow * 8.5 }

    private var ultraHaloOpacity: Double {
        Double(clampedGlow) * 0.16 * haloFade
    }

    private var haloBlur: CGFloat { size * 0.34 }
    private var outerHaloBlur: CGFloat { size * 0.62 }
    private var farHaloBlur: CGFloat { size * 0.9 }
    private var ultraHaloBlur: CGFloat { size * 1.18 }

    var body: some View {
        Group {
            if usesIdleBreath {
                TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { context in
                    markStack(idleBreath: OraculoMotion.markBreathingStrength(at: context.date))
                }
            } else {
                markStack(idleBreath: 0.5)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func markStack(idleBreath: Double) -> some View {
        ZStack {
            if showChargeGlow {
                chargeGlowLayers
            }

            if rippleExpansion > 0.001 {
                rippleLayers
            }

            OraculoMark(size: markSize)
                .opacity(markOpacity(idleBreath: idleBreath))
                .scaleEffect(markScale())
        }
        .animation(OraculoMotion.chargePressAnimation, value: isCharging)
        .animation(
            isSettling ? OraculoMotion.chargeReleaseAnimation(duration: settleDuration) : nil,
            value: clampedGlow
        )
        .animation(OraculoMotion.chargeRippleAnimation, value: rippleExpansion)
    }

    @ViewBuilder
    private var chargeGlowLayers: some View {
        Circle()
            .fill(foregroundStyle)
            .frame(width: size, height: size)
            .blur(radius: ultraHaloBlur)
            .scaleEffect(ultraHaloScale)
            .opacity(ultraHaloOpacity)

        Circle()
            .fill(foregroundStyle)
            .frame(width: size, height: size)
            .blur(radius: farHaloBlur)
            .scaleEffect(farHaloScale)
            .opacity(farHaloOpacity)

        Circle()
            .fill(foregroundStyle)
            .frame(width: size, height: size)
            .blur(radius: outerHaloBlur)
            .scaleEffect(outerHaloScale)
            .opacity(outerHaloOpacity)

        Circle()
            .fill(foregroundStyle)
            .frame(width: size, height: size)
            .blur(radius: haloBlur)
            .scaleEffect(innerHaloScale)
            .opacity(innerHaloOpacity)
    }

    @ViewBuilder
    private var rippleLayers: some View {
        let fade = 1 - Double(rippleExpansion)

        Circle()
            .fill(foregroundStyle)
            .frame(width: size, height: size)
            .blur(radius: size * 0.28)
            .scaleEffect(1.1 + rippleExpansion * 3.4)
            .opacity(0.42 * fade)

        Circle()
            .stroke(
                foregroundStyle.opacity(0.62 * fade),
                lineWidth: max(0.8, 2.8 * fade)
            )
            .frame(width: size, height: size)
            .scaleEffect(1.25 + rippleExpansion * 4.8)
    }
}
