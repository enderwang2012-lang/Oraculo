import SwiftUI

/// 动效对齐 [nipponcolors.com](https://nipponcolors.com/) `/css/style.css`。
///
/// - `#bgWrap`: `background-color 2s ease-in`
/// - `#colorTitle`: 站点 `fadeOut` 1.5s ease-in / `fadeIn` 2.5s ease-out；App：消失 **opacity**，出现 **横向扫字**（横排自左向右）
/// - `#colorRuby`: `fadeOut` 1.5s linear，**keyframes 在 66% 已到 opacity 0**（英文先消失）→ `fadeIn` 2.5s ease-in，**前 25% 仍透明**（英文后出现）
enum OraculoMotion {
    /// 背景色切换（与文案淡出同时开始；略长于站点 2s，更从容）
    static let backgroundCrossfade: TimeInterval = 3.0

    /// 主文案淡出（`h2-fadeOut` 1.5s ease-in，opacity 渐隐）
    static let phraseFadeOut: TimeInterval = 1.5

    /// 主文案出现扫字（3s ease-out，比站点略慢、更从容）
    static let phraseFadeIn: TimeInterval = 3.0

    /// 比标准 ease-out 更早到位，减少末段拖沓；仍保持前段快露出
    static let phraseAppearEaseOut = (x1: 0.22, y1: 1.0, x2: 0.36, y2: 1.0)

    /// 英文 paraphrase（对齐 `#colorRuby`）
    static let subtitleFadeOut: TimeInterval = 1.5
    /// `ruby-fadeOut`：66% 关键帧已到透明 ≈ 0.99s，观感快于中文
    static let subtitleFadeOutReachZero: TimeInterval = subtitleFadeOut * 0.66
    static let subtitleFadeIn: TimeInterval = 2.5
    static let subtitleFadeInHoldFraction: Double = 0.25

    /// 淡出结束再换字，无额外停顿（等同网站的 `animationend`）
    static var phraseSwapDelay: TimeInterval { phraseFadeOut }

    /// 从后台回前台：先展示离开前的当前句，停留后再自动换句（非冷启动）。
    static let resumeDwellBeforeRefresh: TimeInterval = 0.65

    /// 整段切换结束前忽略新的 `refreshOnOpen`
    static var transitionLock: TimeInterval { phraseFadeOut + phraseFadeIn }

    static var backgroundAnimation: Animation {
        .timingCurve(0.42, 0, 1, 1, duration: backgroundCrossfade)
    }

    static var phraseFadeOutAnimation: Animation {
        .timingCurve(0.42, 0, 1, 1, duration: phraseFadeOut)
    }

    static var phraseAppearAnimation: Animation {
        let c = phraseAppearEaseOut
        return .timingCurve(c.x1, c.y1, c.x2, c.y2, duration: phraseFadeIn)
    }

    @available(*, deprecated, renamed: "phraseAppearAnimation")
    static var phraseFadeInAnimation: Animation { phraseAppearAnimation }

    /// `ruby-fadeIn`：前 25% 保持透明，再 ease-in 升至 1
    static var subtitleFadeInAnimation: Animation {
        .easeIn(duration: subtitleFadeIn).delay(subtitleFadeIn * subtitleFadeInHoldFraction)
    }

    /// `ruby-fadeOut`：linear，约在总时长 66% 处已到 0（英文先淡出）
    static var subtitleFadeOutAnimation: Animation {
        .linear(duration: subtitleFadeOutReachZero)
    }

    @available(*, deprecated, renamed: "subtitleFadeInAnimation")
    static var metaFadeInAnimation: Animation { subtitleFadeInAnimation }

    @available(*, deprecated, renamed: "subtitleFadeOutAnimation")
    static var metaFadeOutAnimation: Animation { subtitleFadeOutAnimation }

    // MARK: - 实时时钟

    /// 秒位每 5s 才跳一格（00/05/…/55）
    static let clockSecondStep = 5
    /// 各 digit 上下滑动统一时长（秒位 5s 间隔内可走完）
    static let clockSecondTransition: TimeInterval = 3.0
    static let clockMinuteTransition: TimeInterval = 3.0
    static let clockDateTransition: TimeInterval = 3.0

    /// 滚轮式单列位移：前段快（旧字离场）、末段缓出（新字落定）
    static func clockDigitSlideAnimation(duration: TimeInterval) -> Animation {
        .timingCurve(0.48, 0, 0.18, 1, duration: duration)
    }

    /// 离场旧字淡出（略短于位移，减轻叠印感）
    static let clockDigitDepartFadeRatio: TimeInterval = 0.52

    static func clockDigitDepartFadeAnimation(duration: TimeInterval) -> Animation {
        .easeIn(duration: duration * clockDigitDepartFadeRatio)
    }

    // MARK: - 底部呼吸光（`BreathingBottomGlow`）

    /// 静息呼吸周期；吸约占 38%，呼更长
    static let bottomBreathPeriod: TimeInterval = 5.2
    static let bottomBreathOpacityMin: Double = 0.010
    static let bottomBreathOpacityMax: Double = 0.030
}
