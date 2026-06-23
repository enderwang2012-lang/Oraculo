import SwiftUI

struct ContentView: View {
    @ObservedObject var session: OracleSessionModel
    @StateObject private var charge = OraculoChargeController()
    @State private var locationContextEnabled = LocationContextProvider.isLocationContextEnabled

    /// 主句锚点：约在屏高 38% 处（方案 A）
    private let phraseVerticalRatio: CGFloat = 0.38
    private let phraseFontSize: CGFloat = 40
    private let subtitleFontSize: CGFloat = 15
    /// 时钟距安全区底缘的内边距（抬高，避免贴底）
    private let clockBottomPadding: CGFloat = 44
    /// LOGO 与时钟：紧凑底栏组合（印记下沉、时钟贴其下）
    private let footerMarkClockSpacing: CGFloat = 10
    /// 仅收紧视觉间距，蓄力光晕仍向上溢出
    private let footerMarkDownshift: CGFloat = 18

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
                VStack(spacing: footerMarkClockSpacing) {
                    OraculoChargeFooter(
                        controller: charge,
                        foregroundStyle: clockForegroundStyle,
                        onCharged: { session.refreshOnCharge() }
                    )
                    .frame(width: 128, height: 96, alignment: .bottom)
                    .offset(y: footerMarkDownshift)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("换一句")
                    .accessibilityHint("长按 LOGO 蓄力可换一句、换一色")

                    LiveClockView(foregroundStyle: clockForegroundStyle)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .animation(.easeInOut(duration: OraculoMotion.backgroundCrossfade), value: session.usesLightText)
                .padding(.horizontal, 28)
                .padding(.bottom, clockBottomPadding)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        toggleLocationContext()
                    } label: {
                        Label(locationControlTitle, systemImage: locationContextEnabled ? "location.fill" : "location")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 44, height: 44)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(session.moment.nipponColor.tertiaryTextColor)
                    .accessibilityLabel(locationControlTitle)
                    .accessibilityHint("启用后会请求定位，用天气与海拔优化今日一句")
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(session.usesLightText ? .dark : .light)
        .task {
            // scenePhase.onChange 在冷启动首帧不一定触发；此处保证杀进程重进也会播放入场动画。
            session.refreshOnOpen()
        }
    }

    private func phraseTopInset(in geo: GeometryProxy) -> CGFloat {
        let safeTop = geo.safeAreaInsets.top
        let anchor = geo.size.height * phraseVerticalRatio
        return max(safeTop + 20, anchor)
    }

    private var clockForegroundStyle: Color {
        session.moment.nipponColor.tertiaryTextColor
    }

    private var phraseAccessibilityLabel: String {
        let zh = session.moment.phrase.text
        let en = session.moment.phrase.textEn
        if en.isEmpty { return zh }
        return "\(zh)，\(en)"
    }

    private var locationControlTitle: String {
        locationContextEnabled ? "关闭位置情境" : "开启位置情境"
    }

    private func toggleLocationContext() {
        locationContextEnabled.toggle()
        LocationContextProvider.shared.setLocationContextEnabled(locationContextEnabled)
        if locationContextEnabled {
            Task {
                await OpenMeteoWeatherService.refreshSharedCacheIfPossible(force: true)
            }
        }
    }
}

#Preview {
    ContentView(session: OracleSessionModel())
}
