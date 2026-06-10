import SwiftUI
import UIKit

/// UIKit 长按手势（minimumPressDuration = 0）承接底部 LOGO 触控。
private final class OraculoChargePressView: UIView {
    weak var coordinator: OraculoChargePressDetector.Coordinator?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
        isUserInteractionEnabled = true
        isExclusiveTouch = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}

private struct OraculoChargePressDetector: UIViewRepresentable {
    let controller: OraculoChargeController
    let onCharged: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller, onCharged: onCharged)
    }

    func makeUIView(context: Context) -> OraculoChargePressView {
        let view = OraculoChargePressView()
        view.coordinator = context.coordinator

        let recognizer = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePress(_:))
        )
        recognizer.minimumPressDuration = 0
        view.addGestureRecognizer(recognizer)
        context.coordinator.recognizer = recognizer
        return view
    }

    func updateUIView(_ uiView: OraculoChargePressView, context: Context) {
        // 仅同步回调；勿在 update 里增删手势，否则蓄力每帧刷新会拆掉进行中的按压。
        uiView.coordinator = context.coordinator
        context.coordinator.onCharged = onCharged
    }

    @MainActor
    final class Coordinator: NSObject {
        let controller: OraculoChargeController
        var onCharged: () -> Void
        weak var recognizer: UILongPressGestureRecognizer?

        init(controller: OraculoChargeController, onCharged: @escaping () -> Void) {
            self.controller = controller
            self.onCharged = onCharged
        }

        @objc func handlePress(_ recognizer: UILongPressGestureRecognizer) {
            let state = recognizer.state
            Task { @MainActor in
                switch state {
                case .began:
                    controller.handleFingerDown(onComplete: onCharged)
                case .ended, .cancelled, .failed:
                    controller.handleFingerUp()
                default:
                    break
                }
            }
        }
    }
}

/// 独立触控层，避免 `allowsHitTesting(false)` 波及整棵修饰符链。
struct OraculoChargeFooter: View {
    @ObservedObject var controller: OraculoChargeController
    var foregroundStyle: Color
    var onCharged: () -> Void

    var body: some View {
        ZStack {
            OraculoChargeMark(
                glowAmount: controller.glowAmount,
                isCharging: controller.isCharging,
                rippleExpansion: controller.rippleExpansion,
                isSettling: controller.isSettling,
                settleFromGlow: controller.settleFromGlow,
                settleDuration: controller.settleDuration,
                foregroundStyle: foregroundStyle
            )
            .allowsHitTesting(false)

            OraculoChargePressDetector(controller: controller, onCharged: onCharged)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .contentShape(Rectangle())
    }
}
