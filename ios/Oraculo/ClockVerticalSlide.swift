import SwiftUI

/// 一段时钟文本：仅 **数字位** 各自上下滑动，标点/空格静止。
struct ClockVerticalSlideField: View {
    let text: String
    let size: CGFloat
    let duration: TimeInterval
    /// 列下标稳定 id 前缀（避免 `TimelineView` 每秒刷新丢状态）
    let scopeID: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                column(at: index, character: character)
            }
        }
    }

    @ViewBuilder
    private func column(at index: Int, character: Character) -> some View {
        let glyph = String(character)
        if character.isNumber {
            ClockVerticalSlideDigit(
                digit: glyph,
                size: size,
                duration: duration
            )
            .id("\(scopeID).\(index)")
        } else {
            OraculoTypography.latinText(glyph, size: size)
                .id("\(scopeID).\(index).sep")
        }
    }
}

/// 单个数字位：滚轮式 **单列位移**（旧字在上、新字在下，整列上移），避免双层 Text 叠印残影。
struct ClockVerticalSlideDigit: View {
    let digit: String
    let size: CGFloat
    let duration: TimeInterval

    @State private var settledDigit = ""
    @State private var departingDigit: String?
    @State private var departingOpacity: Double = 1
    @State private var scrollOffset: CGFloat = 0
    @State private var slideGeneration = 0

    private var lineHeight: CGFloat { size * 1.2 }
    private var columnWidth: CGFloat { size * 0.64 }

    var body: some View {
        VStack(spacing: 0) {
            if let departingDigit {
                digitRow(departingDigit)
                    .opacity(departingOpacity)
            }
            digitRow(settledDigit.isEmpty ? digit : settledDigit)
        }
        .offset(y: scrollOffset)
        .frame(width: columnWidth, height: lineHeight, alignment: .top)
        .clipped()
        .onAppear {
            settledDigit = digit
            scrollOffset = 0
        }
        .onChange(of: digit) { _, newValue in
            // 滚动中 `settledDigit` 已是新值，勿因 TimelineView 每秒刷新而提前收束
            if departingDigit != nil {
                guard newValue != settledDigit else { return }
                collapseToSettled(newValue)
                return
            }
            guard newValue != settledDigit else { return }
            runSlide(from: settledDigit, to: newValue)
        }
    }

    private func digitRow(_ string: String) -> some View {
        OraculoTypography.latinText(string, size: size)
            .monospacedDigit()
            .frame(width: columnWidth, height: lineHeight, alignment: .center)
    }

    private func runSlide(from oldValue: String, to newValue: String) {
        guard !oldValue.isEmpty else {
            settledDigit = newValue
            return
        }
        guard oldValue != newValue else { return }

        slideGeneration += 1
        let generation = slideGeneration

        departingDigit = oldValue
        settledDigit = newValue
        scrollOffset = 0
        departingOpacity = 1

        withAnimation(OraculoMotion.clockDigitDepartFadeAnimation(duration: duration)) {
            departingOpacity = 0
        }
        withAnimation(OraculoMotion.clockDigitSlideAnimation(duration: duration)) {
            scrollOffset = -lineHeight
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration + 0.05))
            guard generation == slideGeneration else { return }
            collapseToSettled(newValue)
        }
    }

    private func collapseToSettled(_ value: String) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            departingDigit = nil
            departingOpacity = 1
            scrollOffset = 0
            settledDigit = value
        }
    }
}
