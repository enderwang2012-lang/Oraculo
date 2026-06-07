import SwiftUI

struct ContentView: View {
    @ObservedObject var session: OracleSessionModel

    /// 主句锚点：约在屏高 38% 处（方案 A）
    private let phraseVerticalRatio: CGFloat = 0.38
    private let phraseFontSize: CGFloat = 40
    private let subtitleFontSize: CGFloat = 15
    /// 时钟距安全区底缘的内边距（抬高，避免贴底）
    private let clockBottomPadding: CGFloat = 44

    var body: some View {
        GeometryReader { geo in
            ZStack {
                NipponCrossfadeBackground(
                    base: session.baseColor,
                    overlay: session.overlayColor,
                    blend: session.colorBlend,
                    usesLightText: session.usesLightText
                )

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: phraseTopInset(in: geo))

                    VStack(spacing: 12) {
                        OraculoTypography.phraseText(session.moment.phrase.text, size: phraseFontSize)
                            .multilineTextAlignment(.center)
                            .lineSpacing(14)
                            .tracking(1)
                            .foregroundStyle(session.moment.nipponColor.primaryTextColor)
                            .minimumScaleFactor(0.72)
                            .opacity(session.phraseFadeOpacity)
                            .phraseAppearSweep(reveal: session.phraseAppearReveal)
                            .accessibilityAddTraits(.isHeader)

                        if !session.moment.phrase.textEn.isEmpty {
                            OraculoTypography.latinText(session.moment.phrase.textEn, size: subtitleFontSize)
                                .multilineTextAlignment(.center)
                                .tracking(0.6)
                                .foregroundStyle(session.moment.nipponColor.secondaryTextColor)
                                .opacity(session.subtitleOpacity)
                        }
                    }
                    .padding(.horizontal, 40)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(phraseAccessibilityLabel)

                    Spacer(minLength: 0)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                LiveClockView(foregroundStyle: clockForegroundStyle)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .animation(.easeInOut(duration: OraculoMotion.backgroundCrossfade), value: session.usesLightText)
                    .padding(.horizontal, 28)
                    .padding(.bottom, clockBottomPadding)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(session.usesLightText ? .dark : .light)
        .task {
            // scenePhase.onChange 在冷启动首帧不一定触发；此处保证杀进程重进也会播放入场动画。
            session.refreshOnOpen()
        }
        .onDeviceShake {
            session.refreshOnShake()
        }
        .accessibilityHint("摇一摇可换一句、换一色")
    }

    private func phraseTopInset(in geo: GeometryProxy) -> CGFloat {
        let safeTop = geo.safeAreaInsets.top
        let anchor = geo.size.height * phraseVerticalRatio
        return max(safeTop + 20, anchor)
    }

    private var clockForegroundStyle: Color {
        session.usesLightText ? Color.white.opacity(0.52) : Color(white: 0.12).opacity(0.45)
    }

    private var phraseAccessibilityLabel: String {
        let zh = session.moment.phrase.text
        let en = session.moment.phrase.textEn
        if en.isEmpty { return zh }
        return "\(zh)，\(en)"
    }
}

#Preview {
    ContentView(session: OracleSessionModel())
}
