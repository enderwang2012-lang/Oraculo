import SwiftUI
import UIKit

/// 固定品牌标记。优先读 Assets 中的 `WidgetMark`（用户提供）；缺失时用内置占位。
struct OraculoWidgetMark: View {
    var size: CGFloat = 12
    /// 锁屏小尺寸下满不透明，避免发灰。
    var emphasized: Bool = false

    var body: some View {
        Group {
            if UIImage(named: "WidgetMark", in: .main, compatibleWith: nil) != nil {
                Image("WidgetMark")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
            } else {
                drawnPlaceholder
            }
        }
        .frame(width: size, height: size)
        .opacity(emphasized ? 1 : 0.92)
        .accessibilityHidden(true)
    }

    private var drawnPlaceholder: some View {
        ZStack {
            Circle()
                .strokeBorder(lineWidth: max(0.8, size * 0.1))
            Circle()
                .frame(width: size * 0.2, height: size * 0.2)
        }
    }
}
