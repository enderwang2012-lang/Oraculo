import Foundation

#if canImport(WidgetKit) && !APPLICATION_EXTENSION_API_ONLY
import WidgetKit
#endif

/// 主 App 写入共享展示后，通知 Widget 重新读盘。
enum WidgetTimelineRefresher {
    static func reloadAllIfPossible() {
        #if canImport(WidgetKit) && !APPLICATION_EXTENSION_API_ONLY
        WidgetCenter.shared.reloadAllTimelines()
        for kind in ["OraculoHomeWidget", "OraculoLockInline", "OraculoLockRectangular"] {
            WidgetCenter.shared.reloadTimelines(ofKind: kind)
        }
        #endif
    }
}
