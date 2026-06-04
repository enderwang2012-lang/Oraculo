import SwiftUI

/// 底部实时时钟：`yyyy.MM.dd HH:mm:ss`。
///
/// - 数字跳变：按**单 digit** 上下滑动（如 30→35 仅个位 0→5 动）。
/// - **秒**：每 5s 一格（00、05、…、55）。
struct LiveClockView: View {
    var foregroundStyle: Color

    private let fontSize: CGFloat = 16
    private let colonOpacity: Double = 0.54

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            clockRow(for: context.date)
                .foregroundStyle(foregroundStyle)
        }
    }

    @ViewBuilder
    private func clockRow(for date: Date) -> some View {
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        let hour = parts.hour ?? 0
        let minute = parts.minute ?? 0
        let second = parts.second ?? 0

        let datePart = String(format: "%04d.%02d.%02d ", year, month, day)
        let hourText = String(format: "%02d", hour)
        let minuteText = String(format: "%02d", minute)
        let displaySecond = quantizedSecond(second)
        let secondText = String(format: "%02d", displaySecond)

        HStack(alignment: .firstTextBaseline, spacing: 0) {
            ClockVerticalSlideField(
                text: datePart,
                size: fontSize,
                duration: OraculoMotion.clockDateTransition,
                scopeID: "oraculo.clock.date"
            )

            ClockVerticalSlideField(
                text: hourText,
                size: fontSize,
                duration: OraculoMotion.clockDateTransition,
                scopeID: "oraculo.clock.hour"
            )

            OraculoTypography.latinText(":", size: fontSize)
                .opacity(colonOpacity)

            ClockVerticalSlideField(
                text: minuteText,
                size: fontSize,
                duration: OraculoMotion.clockMinuteTransition,
                scopeID: "oraculo.clock.minute"
            )

            OraculoTypography.latinText(":", size: fontSize)
                .opacity(colonOpacity)

            ClockVerticalSlideField(
                text: secondText,
                size: fontSize,
                duration: OraculoMotion.clockSecondTransition,
                scopeID: "oraculo.clock.second"
            )
        }
        .tracking(2.5)
        .accessibilityLabel(accessibilityLabel(for: date))
    }

    private func quantizedSecond(_ second: Int) -> Int {
        (second / OraculoMotion.clockSecondStep) * OraculoMotion.clockSecondStep
    }

    private func accessibilityLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm:ss"
        return formatter.string(from: date)
    }
}
