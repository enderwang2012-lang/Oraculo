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

    private var isTransitioning = false

    private var hasPresentedOnce = false



    init() {

        let baseline = session.todayBaseline()

        moment = baseline

        momentShownAt = Date()

        baseColor = baseline.nipponColor

    }



    func refreshOnOpen() {

        guard !isTransitioning else { return }

        let next = session.randomMoment(excluding: moment)



        if !hasPresentedOnce {

            hasPresentedOnce = true

            presentInitialOpen(to: next)

            return

        }



        transition(to: next)

    }



    /// 摇一摇：与再次进入前台相同的全套 crossfade（需已完成首屏呈现）。

    func refreshOnShake() {
        guard !isTransitioning else { return }
        guard let next = drawDistinctMoment() else { return }
        if !hasPresentedOnce {
            hasPresentedOnce = true
            presentInitialOpen(to: next)
            return
        }
        transition(to: next)
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

        moment = next

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



    private func transition(to next: OracleMoment) {
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

            self.moment = next

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



    var usesLightText: Bool {

        let overlayActive = (overlayColor != nil) && colorBlend > 0.35

        if overlayActive, let overlayColor {

            return overlayColor.usesLightText

        }

        return moment.nipponColor.usesLightText

    }

}

