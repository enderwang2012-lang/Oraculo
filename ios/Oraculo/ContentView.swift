import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject var session: OracleSessionModel
    @ObservedObject private var locationProvider = LocationContextProvider.shared
    @StateObject private var charge = OraculoChargeController()
    @State private var isShowingLocationRationale = false
    @State private var isRequestingLocationAuthorization = false
    @State private var locationPermissionIssue: LocationPermissionIssue?

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
                        Label(locationControlTitle, systemImage: locationProvider.isEnabled ? "location.fill" : "location")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 44, height: 44)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(session.moment.nipponColor.tertiaryTextColor)
                    .opacity(locationProvider.isEnabled ? 0.5 : 1.0)
                    .disabled(isRequestingLocationAuthorization)
                    .accessibilityLabel(locationControlTitle)
                    .accessibilityHint(locationControlHint)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .preferredColorScheme(session.usesLightText ? .dark : .light)
        .task {
            // scenePhase.onChange 在冷启动首帧不一定触发；此处保证杀进程重进也会播放入场动画。
            session.refreshOnOpen()
        }
        .alert("开启位置情境？", isPresented: $isShowingLocationRationale) {
            Button("继续") {
                requestLocationContextAccess()
            }
            Button("暂不", role: .cancel) {}
        } message: {
            Text("Oraculo 会在你使用 App 时获取一次大致位置，并结合海拔与当地天气优化今日一句。位置情境可随时关闭，关闭时会清除缓存。")
        }
        .alert(item: $locationPermissionIssue) { issue in
            permissionAlert(for: issue)
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
        locationProvider.isEnabled ? "关闭位置情境" : "开启位置情境"
    }

    private var locationControlHint: String {
        if locationProvider.isEnabled {
            return "关闭后会停止使用位置并清除位置与天气缓存"
        }
        return "开启后会请求定位，用天气与海拔优化今日一句"
    }

    private func toggleLocationContext() {
        if locationProvider.isEnabled {
            locationProvider.disableLocationContext()
            return
        }

        switch locationProvider.activationAction() {
        case .requestPermission:
            isShowingLocationRationale = true
        case .enable:
            requestLocationContextAccess()
        case .showSettings:
            locationPermissionIssue = .denied
        case .showRestriction:
            locationPermissionIssue = .restricted
        }
    }

    private func requestLocationContextAccess() {
        guard !isRequestingLocationAuthorization else { return }
        isRequestingLocationAuthorization = true

        Task {
            let result = await locationProvider.enableLocationContext()
            isRequestingLocationAuthorization = false

            switch result {
            case .enabled:
                break
            case .denied:
                locationPermissionIssue = .denied
            case .restricted:
                locationPermissionIssue = .restricted
            }
        }
    }

    private func permissionAlert(for issue: LocationPermissionIssue) -> Alert {
        switch issue {
        case .denied:
            return Alert(
                title: Text("位置权限已关闭"),
                message: Text("Oraculo 无法使用位置情境。你可以前往系统设置，在“位置”中选择“使用 App 时”。"),
                primaryButton: .default(Text("前往设置")) {
                    openAppSettings()
                },
                secondaryButton: .cancel(Text("暂不"))
            )
        case .restricted:
            return Alert(
                title: Text("位置权限受限"),
                message: Text("当前设备不允许 Oraculo 使用位置，可能受到系统限制或家长控制。"),
                dismissButton: .default(Text("知道了"))
            )
        }
    }

    private func openAppSettings() {
        #if canImport(UIKit)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
        #endif
    }

    private enum LocationPermissionIssue: String, Identifiable {
        case denied
        case restricted

        var id: String { rawValue }
    }
}

#Preview {
    ContentView(session: OracleSessionModel())
}
