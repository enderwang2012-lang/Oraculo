import SwiftUI
import UIKit

/// 固定品牌标记。优先读 Assets 中的 `WidgetMark`（用户提供）；缺失时用内置占位。
struct OraculoWidgetMark: View {
    @Environment(\.displayScale) private var displayScale

    var size: CGFloat = 12
    /// 锁屏小尺寸下满不透明，避免发灰。
    var emphasized: Bool = false

    var body: some View {
        Group {
            if let image = renderedImage {
                Image(uiImage: image)
                    .interpolation(.high)
                    .antialiased(true)
            } else {
                drawnPlaceholder
            }
        }
        .frame(width: size, height: size)
        .opacity(emphasized ? 1 : 0.85)
        .accessibilityHidden(true)
    }

    /// 按 Widget 实际显示倍率栅格化，避免系统二次放大导致糊边。
    private var renderedImage: UIImage? {
        guard let base = UIImage(named: "WidgetMark", in: .main, compatibleWith: nil),
              let cg = base.cgImage
        else { return nil }

        let pixel = max(1, floor(size * displayScale))
        let target = CGSize(width: pixel, height: pixel)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: target, format: format).image { ctx in
            ctx.cgContext.interpolationQuality = .high
            ctx.cgContext.draw(cg, in: CGRect(origin: .zero, size: target))
        }
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
