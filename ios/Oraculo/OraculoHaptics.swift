import CoreHaptics
import UIKit

enum OraculoHaptics {
    private static let success = UINotificationFeedbackGenerator()
    private static let softImpact = UIImpactFeedbackGenerator(style: .soft)

    private static var engine: CHHapticEngine?
    private static var chargePlayer: CHHapticPatternPlayer?
    private static var fallbackTask: Task<Void, Never>?

    private static var supportsCoreHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    /// 蓄力开始：连续低频渐强触感（比均匀卡点更自然）；不支持时退化为柔和脉冲。
    static func beginChargeProgress(duration: TimeInterval) {
        endChargeProgress()

        guard supportsCoreHaptics else {
            startFallbackChargePulse(duration: duration)
            return
        }

        do {
            if engine == nil {
                let created = try CHHapticEngine()
                created.isAutoShutdownEnabled = true
                created.resetHandler = { try? created.start() }
                engine = created
            }
            try engine?.start()

            let continuous = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.22),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.14),
                ],
                relativeTime: 0,
                duration: duration
            )

            let ramp = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    .init(relativeTime: 0, value: 0.1),
                    .init(relativeTime: duration * 0.3, value: 0.24),
                    .init(relativeTime: duration * 0.65, value: 0.42),
                    .init(relativeTime: duration, value: 0.58),
                ],
                relativeTime: 0
            )

            let pattern = try CHHapticPattern(events: [continuous], parameterCurves: [ramp])
            chargePlayer = try engine?.makePlayer(with: pattern)
            try chargePlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {
            startFallbackChargePulse(duration: duration)
        }
    }

    static func endChargeProgress() {
        try? chargePlayer?.stop(atTime: CHHapticTimeImmediate)
        chargePlayer = nil
        fallbackTask?.cancel()
        fallbackTask = nil
    }

    /// 蓄力成功：先停过程触感，再单次成功反馈。
    static func chargeCompleted() {
        endChargeProgress()
        success.prepare()
        success.notificationOccurred(.success)
    }

    /// 低频柔和脉冲 + 渐强强度（无 Core Haptics 时的退路）。
    private static func startFallbackChargePulse(duration: TimeInterval) {
        softImpact.prepare()
        fallbackTask = Task { @MainActor in
            let beats: [(TimeInterval, CGFloat)] = [
                (duration * 0.22, 0.28),
                (duration * 0.48, 0.38),
                (duration * 0.72, 0.5),
            ]
            let start = Date()

            for (target, intensity) in beats {
                let wait = target - Date().timeIntervalSince(start)
                if wait > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                }
                guard !Task.isCancelled else { return }
                softImpact.impactOccurred(intensity: intensity)
            }
        }
    }
}
