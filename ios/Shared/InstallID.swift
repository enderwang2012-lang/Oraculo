import Foundation

/// 安装级唯一 ID，混入选句/选色种子，使"同日 + 同情境"的不同用户拿到不同结果。
///
/// - 存储：App Group UserDefaults（主 App 与 Widget 共用同一个值）。
/// - 生命周期：首次读取时生成；卸载重装会换。
/// - 失败兜底：App Group 不可用（极少见，主要是配置漏勾）时回落到一个进程级常量，
///   保证"同进程内调用一致"，不再尝试持久化。
enum InstallID {
    private static let fallbackKey = "fallback-install-id"
    private static var memoizedFallback: String?

    /// 当前安装的 UUID 字符串。
    static var value: String {
        if let defaults = UserDefaults(suiteName: AppConstants.appGroupID) {
            if let existing = defaults.string(forKey: AppConstants.sharedInstallIDKey),
               !existing.isEmpty {
                return existing
            }
            let fresh = UUID().uuidString
            defaults.set(fresh, forKey: AppConstants.sharedInstallIDKey)
            return fresh
        }
        if let cached = memoizedFallback { return cached }
        let fresh = UUID().uuidString
        memoizedFallback = fresh
        return fresh
    }
}
