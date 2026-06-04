import Foundation

/// App 内当前展示的一帧：短句 + 配色（可与小组件「今日」不同）。
struct OracleMoment: Equatable {
    let phrase: Phrase
    let nipponColor: NipponColor
    /// 底部日期仍用当日历日，与午夜「今日」对齐。
    let dayKey: String
}
