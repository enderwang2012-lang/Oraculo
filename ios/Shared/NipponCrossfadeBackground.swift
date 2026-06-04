import SwiftUI

/// 双色叠化背景，模拟 nipponcolors.com 切换色时的缓缓渐变；底部极轻呼吸光替代全屏明暗。
struct NipponCrossfadeBackground: View {
    let base: NipponColor
    let overlay: NipponColor?
    /// 0 = 仅底层；1 = 完全叠化到上层。
    let blend: Double
    let usesLightText: Bool

    var body: some View {
        ZStack {
            base.swiftUIColor
                .ignoresSafeArea()

            if let overlay, blend > 0.001 {
                overlay.swiftUIColor
                    .opacity(blend)
                    .ignoresSafeArea()
            }

            BreathingBottomGlow(usesLightText: usesLightText)
                .animation(.easeInOut(duration: 2.0), value: usesLightText)
        }
    }
}
