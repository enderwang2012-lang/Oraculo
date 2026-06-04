import SwiftUI

/// 参考 nipponcolors.com：纯色铺满 + 底部极轻呼吸 + 色名淡入。
struct NipponAmbienceView: View {
    let color: Color
    let usesLightText: Bool

    @State private var washIn = false

    var body: some View {
        ZStack {
            color
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.1), value: color)

            BreathingBottomGlow(usesLightText: usesLightText)
                .animation(.easeInOut(duration: 2.0), value: usesLightText)

            LinearGradient(
                colors: [
                    (usesLightText ? Color.white : Color.black).opacity(washIn ? 0 : 0.14),
                    .clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                washIn = true
            }
        }
    }
}
