import SwiftUI
import UIKit

/// 主 App 品牌标记（与 Widget `WidgetMark` 同源资源）。
struct OraculoMark: View {
    var size: CGFloat = 20

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
