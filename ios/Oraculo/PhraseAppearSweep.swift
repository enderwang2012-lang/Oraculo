import SwiftUI

/// 中文主句**出现**时横向扫字（横排活字，自左向右显现；消失仍用 opacity）。
struct PhraseAppearSweepModifier: AnimatableModifier {
    var reveal: CGFloat

    /// 扫字边缘羽化；略窄以减少尾部「糊着收完」的观感
    private let feather: CGFloat = 0.05

    var animatableData: CGFloat {
        get { reveal }
        set { reveal = newValue }
    }

    func body(content: Content) -> some View {
        if reveal >= 0.999 {
            content
        } else if reveal <= 0.001 {
            content.opacity(0)
        } else {
            content.mask {
                horizontalRevealMask
            }
        }
    }

    /// 自左向右扫入（与横排阅读方向一致）
    private var horizontalRevealMask: some View {
        GeometryReader { geo in
            let edge = min(max(reveal, 0), 1)
            let f = min(feather, edge, 1 - edge)
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: max(0, edge - f)),
                    .init(color: .clear, location: min(1, edge + f)),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

extension View {
    func phraseAppearSweep(reveal: CGFloat) -> some View {
        modifier(PhraseAppearSweepModifier(reveal: reveal))
    }
}
