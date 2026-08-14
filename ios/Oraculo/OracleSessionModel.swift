import SwiftUI



@MainActor

final class OracleSessionModel: ObservableObject {

    @Published private(set) var moment: OracleMoment

    @Published private(set) var momentShownAt: Date

    @Published private(set) var baseColor: NipponColor

    @Published private(set) var overlayColor: NipponColor?

    @Published private(set) var colorBlend: Double = 0

    /// 中文消失：opacity 渐隐（`h2-fadeOut` 1.5s ease-in）

    @Published var phraseFadeOpacity: Double = 1

    /// 中文出现：横向扫字（`h2-fadeIn` 2.5s ease-out，自左向右）

    @Published var phraseAppearReveal: CGFloat = 0

    /// 英文 paraphrase（对齐 `#colorRuby`）

    @Published var subtitleOpacity: Double = 0



    private let session = SessionOracleService()

    private let dailyOracle = DailyOracleService()

    private var isTransitioning = false

    private var hasPresentedOnce = false

    private var chargeRefreshTask: Task<Void, Never>?



    init() {

        let defaults = UserDefaults.standard
        let existingSharedMoment = SharedOracleMomentStore.shared.load()
        let shouldShowGreeting = AppLaunchPolicy.shouldShowFirstInstallGreeting(
            hasRecordedAppLaunch: defaults.bool(forKey: AppConstants.hasLaunchedAppKey),
            hasExistingInstallID: InstallID.hasPersistedValue,
            hasExistingSharedMoment: existingSharedMoment != nil
        )
        let baseline = dailyOracle.loadDisplayedMoment() ?? session.todayBaseline()
        let initialMoment = shouldShowGreeting
            ? OracleMoment(
                phrase: .firstInstallGreeting,
                nipponColor: baseline.nipponColor,
                dayKey: baseline.dayKey
            )
            : baseline

        moment = initialMoment

        momentShownAt = Date()

        baseColor = initialMoment.nipponColor

        dailyOracle.syncDisplayedMoment(
            initialMoment,
            source: shouldShowGreeting ? .fallback : .appInteraction,
            recordExposure: false
        )
        defaults.set(true, forKey: AppConstants.hasLaunchedAppKey)

    }



    /// 从后台回前台（含 Widget 点开）：采用 Widget 当前句，并重播同一句的入场动画。
    func refreshOnResumeFromBackground() {
        guard !isTransitioning else { return }

        if !hasPresentedOnce {
            refreshOnOpen()
            return
        }

        let widgetMoment = dailyOracle.loadDisplayedMoment()
        let widgetMomentDiffers = widgetMoment.map { $0 != moment } ?? false
        switch AppLaunchPolicy.resumeAction(widgetMomentDiffers: widgetMomentDiffers) {
        case .replayCurrent:
            break
        case .adoptWidgetMomentAndReplay:
            if let widgetMoment {
                restoreDisplayedMoment(widgetMoment)
            }
        }
        replayCurrentMomentAppearance()
    }

    func refreshOnOpen() {
        guard !isTransitioning else { return }

        if !hasPresentedOnce {

            hasPresentedOnce = true

            presentInitialOpen(to: moment)

            return

        }



        let next = session.randomMoment(excluding: moment)
        transition(to: next)

    }



    /// 长按蓄力：与再次进入前台相同的全套 crossfade（需已完成首屏呈现）。
    /// `onPhraseReplaced` 只在新文字真正替换到界面后调用。
    func refreshOnCharge(onPhraseReplaced: @escaping () -> Void = {}) {
        chargeRefreshTask?.cancel()

        if isTransitioning {
            chargeRefreshTask = Task { @MainActor in
                while isTransitioning, !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 50_000_000)
                }
                guard !Task.isCancelled else { return }
                performChargeRefresh(onPhraseReplaced: onPhraseReplaced)
            }
            return
        }

        performChargeRefresh(onPhraseReplaced: onPhraseReplaced)
    }

    private func performChargeRefresh(onPhraseReplaced: @escaping () -> Void) {
        guard let next = drawDistinctMoment() else { return }
        if !hasPresentedOnce {
            hasPresentedOnce = true
            presentInitialOpen(to: next)
            onPhraseReplaced()
            return
        }
        transition(to: next, onPhraseReplaced: onPhraseReplaced)
    }

    /// 抽与当前不同的句+色；语料未打进包时仅 fallback，返回 nil 避免空播动画。
    private func drawDistinctMoment() -> OracleMoment? {
        guard PhraseStore.shared.phraseCount > 1, NipponColorStore.shared.colorCount > 1 else {
            return nil
        }
        for _ in 0 ..< 8 {
            let candidate = session.randomMoment(excluding: moment)
            if candidate != moment { return candidate }
        }
        return session.randomMoment(excluding: nil)
    }



    private func presentInitialOpen(to next: OracleMoment) {

        isTransitioning = true

        overlayColor = next.nipponColor

        applyMoment(next)

        momentShownAt = Date()

        phraseFadeOpacity = 1

        phraseAppearReveal = 0



        withAnimation(OraculoMotion.backgroundAnimation) {

            colorBlend = 1

        }

        withAnimation(OraculoMotion.phraseAppearAnimation) {

            phraseAppearReveal = 1

        }

        withAnimation(OraculoMotion.subtitleFadeInAnimation) {

            subtitleOpacity = 1

        }



        DispatchQueue.main.asyncAfter(deadline: .now() + OraculoMotion.backgroundCrossfade) { [weak self] in

            guard let self else { return }

            self.baseColor = next.nipponColor

            self.overlayColor = nil

            self.colorBlend = 0

        }



        DispatchQueue.main.asyncAfter(deadline: .now() + OraculoMotion.transitionLock) { [weak self] in

            self?.isTransitioning = false

        }

    }



    private func transition(
        to next: OracleMoment,
        onPhraseReplaced: @escaping () -> Void = {}
    ) {
        guard next != moment else { return }
        isTransitioning = true
        overlayColor = next.nipponColor



        withAnimation(OraculoMotion.phraseFadeOutAnimation) {

            phraseFadeOpacity = 0

        }

        withAnimation(OraculoMotion.subtitleFadeOutAnimation) {

            subtitleOpacity = 0

        }

        withAnimation(OraculoMotion.backgroundAnimation) {

            colorBlend = 1

        }



        DispatchQueue.main.asyncAfter(deadline: .now() + OraculoMotion.phraseSwapDelay) { [weak self] in

            guard let self else { return }

            self.applyMoment(next)
            onPhraseReplaced()

            self.momentShownAt = Date()

            self.phraseFadeOpacity = 1

            self.phraseAppearReveal = 0

            withAnimation(OraculoMotion.phraseAppearAnimation) {

                self.phraseAppearReveal = 1

            }

            withAnimation(OraculoMotion.subtitleFadeInAnimation) {

                self.subtitleOpacity = 1

            }

        }



        DispatchQueue.main.asyncAfter(deadline: .now() + OraculoMotion.backgroundCrossfade) { [weak self] in

            guard let self else { return }

            self.baseColor = next.nipponColor

            self.overlayColor = nil

            self.colorBlend = 0

        }



        DispatchQueue.main.asyncAfter(deadline: .now() + OraculoMotion.transitionLock) { [weak self] in

            self?.isTransitioning = false

        }

    }



    private func applyMoment(_ next: OracleMoment) {
        moment = next
        dailyOracle.syncDisplayedMoment(next, recordExposure: true)
    }

    private func restoreDisplayedMoment(_ restored: OracleMoment) {
        moment = restored
        momentShownAt = Date()
        baseColor = restored.nipponColor
        overlayColor = nil
        colorBlend = 0
    }

    private func replayCurrentMomentAppearance() {
        ensureCurrentMomentFullyVisible()
        phraseAppearReveal = 0
        subtitleOpacity = 0
        momentShownAt = Date()

        withAnimation(OraculoMotion.phraseAppearAnimation) {
            phraseAppearReveal = 1
        }
        if !moment.phrase.textEn.isEmpty {
            withAnimation(OraculoMotion.subtitleFadeInAnimation) {
                subtitleOpacity = 1
            }
        }
    }

    /// 回前台首帧：确保离开前那句完整可见（避免上次动画半途被挂起）。
    private func ensureCurrentMomentFullyVisible() {
        baseColor = moment.nipponColor
        overlayColor = nil
        colorBlend = 0
        phraseFadeOpacity = 1
        phraseAppearReveal = 1
        subtitleOpacity = moment.phrase.textEn.isEmpty ? 0 : 1
    }

    /// 退到后台时再推一次 Widget，避免系统节流 reload 后锁屏仍停在旧句。
    func syncWidgetDisplay() {
        dailyOracle.syncDisplayedMoment(moment, recordExposure: false)
    }

    var usesLightText: Bool {

        let overlayActive = (overlayColor != nil) && colorBlend > 0.35

        if overlayActive, let overlayColor {

            return overlayColor.usesLightText

        }

        return moment.nipponColor.usesLightText

    }

}

