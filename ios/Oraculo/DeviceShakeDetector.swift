import SwiftUI
import UIKit

extension Notification.Name {
    static let oraculoDeviceDidShake = Notification.Name("oraculoDeviceDidShake")
}

/// 透明全屏 `UIView` 承接摇一摇（`background` 里的 VC 往往拿不到第一响应者）。
private final class ShakeDetectingView: UIView {
    override var canBecomeFirstResponder: Bool { true }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            DispatchQueue.main.async { [weak self] in
                _ = self?.becomeFirstResponder()
            }
        } else {
            resignFirstResponder()
        }
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .oraculoDeviceDidShake, object: nil)
            return
        }
        super.motionEnded(motion, with: event)
    }
}

private struct DeviceShakeDetectorRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> ShakeDetectingView {
        let view = ShakeDetectingView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: ShakeDetectingView, context: Context) {}
}

extension View {
    func onDeviceShake(perform action: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: .oraculoDeviceDidShake)) { _ in
            action()
        }
        .overlay {
            DeviceShakeDetectorRepresentable()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
        }
    }
}
