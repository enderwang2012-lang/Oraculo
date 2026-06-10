import SwiftUI

@MainActor
final class OraculoChargeController: ObservableObject {
    /// 蓄力亮度 0…1，驱动 LOGO 透明度/缩放/光晕
    @Published private(set) var glowAmount: CGFloat = 0
    @Published private(set) var isFingerDown = false
    @Published private(set) var rippleExpansion: CGFloat = 0
    /// 蓄力完成后的涟漪 + 消逝；此期间松手不打断
    @Published private(set) var isCompletionActive = false
    /// 正在渐暗消逝（含提前松手）
    @Published private(set) var isSettling = false
    /// 本次消逝起点蓄力（用于从当前亮度渐暗到静息）
    @Published private(set) var settleFromGlow: CGFloat = 0
    @Published private(set) var settleDuration: TimeInterval = 0

    private var chargeTask: Task<Void, Never>?
    private var rippleTask: Task<Void, Never>?
    private var settleTask: Task<Void, Never>?
    private var releasedBeforeComplete = false

    var isCharging: Bool { chargeTask != nil }

    func handleFingerDown(onComplete: @escaping () -> Void) {
        guard !isCompletionActive, !isSettling else { return }

        isFingerDown = true
        releasedBeforeComplete = false

        guard chargeTask == nil else { return }
        startChargeTask(onComplete: onComplete)
    }

    func handleFingerUp() {
        let wasCharging = chargeTask != nil

        if isCompletionActive || isSettling {
            isFingerDown = false
            return
        }

        releasedBeforeComplete = true
        isFingerDown = false

        guard wasCharging else { return }
        stopChargeAndSettle()
    }

    private func startChargeTask(onComplete: @escaping () -> Void) {
        rippleTask?.cancel()
        rippleTask = nil
        settleTask?.cancel()
        settleTask = nil
        rippleExpansion = 0
        glowAmount = 0
        isCompletionActive = false
        isSettling = false
        settleFromGlow = 0
        releasedBeforeComplete = false

        let duration = OraculoMotion.chargeDuration
        OraculoHaptics.beginChargeProgress(duration: duration)

        chargeTask = Task { @MainActor in
            let started = Date()

            while !Task.isCancelled {
                guard isFingerDown, !releasedBeforeComplete else { return }

                let elapsed = Date().timeIntervalSince(started)
                let fraction = min(1, elapsed / duration)
                glowAmount = fraction

                if fraction >= 1 {
                    guard isFingerDown, !releasedBeforeComplete, !Task.isCancelled else { return }
                    finish(onComplete: onComplete)
                    return
                }

                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func stopChargeAndSettle() {
        chargeTask?.cancel()
        chargeTask = nil
        OraculoHaptics.endChargeProgress()

        let currentGlow = glowAmount
        guard currentGlow > 0.001 else { return }

        beginSettle(from: currentGlow, afterCompletion: false)
    }

    private func finish(onComplete: @escaping () -> Void) {
        guard isFingerDown, !releasedBeforeComplete else { return }

        chargeTask = nil
        glowAmount = 1
        isCompletionActive = true

        OraculoHaptics.chargeCompleted()
        onComplete()
        playCompletionRipple()
    }

    private func playCompletionRipple() {
        rippleExpansion = 0

        withAnimation(OraculoMotion.chargeRippleAnimation) {
            rippleExpansion = 1
        }

        let rippleDuration = OraculoMotion.chargeRippleDuration
        let settleLead = rippleDuration * OraculoMotion.chargeRippleSettleOverlap

        rippleTask?.cancel()
        rippleTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(settleLead * 1_000_000_000))
            guard !Task.isCancelled else { return }

            beginSettle(from: 1, afterCompletion: true)

            let rippleTail = rippleDuration - settleLead
            try? await Task.sleep(nanoseconds: UInt64(rippleTail * 1_000_000_000))
            guard !Task.isCancelled else { return }

            rippleExpansion = 0
            rippleTask = nil
        }
    }

    private func beginSettle(from startGlow: CGFloat, afterCompletion: Bool) {
        settleTask?.cancel()

        settleFromGlow = startGlow
        settleDuration = OraculoMotion.chargeSettleDuration(for: startGlow)
        isSettling = true

        settleTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else { return }

            withAnimation(OraculoMotion.chargeReleaseAnimation(duration: settleDuration)) {
                glowAmount = 0
            }

            try? await Task.sleep(nanoseconds: UInt64(settleDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }

            isSettling = false
            settleFromGlow = 0
            settleDuration = 0
            if afterCompletion {
                isCompletionActive = false
            }
            settleTask = nil
        }
    }
}
