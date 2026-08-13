import SwiftUI

struct OraculoInteractionHint: View, Animatable {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var dissolveProgress: CGFloat

    private let foregroundStyle = Color.white.opacity(OraculoMotion.markIdleOpacityMax)
    private let entranceAmplitude: CGFloat = 3
    private let attentionLoopDuration: TimeInterval = 3.2

    var animatableData: CGFloat {
        get { dissolveProgress }
        set { dissolveProgress = newValue }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)) { timeline in
            let attentionOffset = attentionOffset(at: timeline.date)

            ZStack {
                Text("长按印记切换文字")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(foregroundStyle)
                    .opacity(textOpacity)
                    .offset(y: attentionOffset)

                Canvas { context, size in
                    guard dissolveProgress > 0 else { return }

                    let resolvedText = context.resolve(
                        Text("长按印记切换文字")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(foregroundStyle)
                    )
                    let textCenter = CGPoint(
                        x: size.width / 2,
                        y: size.height / 2 + attentionOffset
                    )

                    for index in 0 ..< 72 {
                        let start = CGFloat((index * 7) % 19) / 48
                        let localProgress = min(max((dissolveProgress - start) / (1 - start), 0), 1)
                        guard localProgress > 0, localProgress < 1 else { continue }

                        let column = CGFloat((index * 37) % 101) / 100
                        let row = CGFloat((index * 23) % 29) / 28
                        let direction: CGFloat = index.isMultiple(of: 2) ? -1 : 1
                        let drift = direction * CGFloat(6 + (index * 11) % 18)
                        let lift = CGFloat(7 + (index * 13) % 24)
                        let x = size.width * (0.15 + column * 0.70)
                        let y = size.height * (0.31 + row * 0.38) + attentionOffset
                        let fragmentSize = CGFloat(1 + (index * 5) % 3)
                        let fragmentRect = CGRect(
                            x: x,
                            y: y,
                            width: fragmentSize,
                            height: fragmentSize
                        )
                        let opacity = Double(sin(.pi * localProgress)) * 0.88

                        context.opacity = 1
                        context.drawLayer { layer in
                            layer.opacity = opacity
                            layer.translateBy(
                                x: drift * localProgress,
                                y: -lift * localProgress
                            )
                            layer.clip(to: Path(fragmentRect))
                            layer.draw(resolvedText, at: textCenter, anchor: .center)
                        }

                        let speckCenter = CGPoint(
                            x: x + drift * localProgress,
                            y: y - lift * localProgress
                        )
                        context.opacity = opacity * 0.72
                        context.fill(
                            Path(
                                ellipseIn: CGRect(
                                    x: speckCenter.x - fragmentSize / 2,
                                    y: speckCenter.y - fragmentSize / 2,
                                    width: fragmentSize,
                                    height: fragmentSize
                                )
                            ),
                            with: .color(foregroundStyle)
                        )
                    }
                }
                .allowsHitTesting(false)
            }
        }
        .frame(width: 160, height: 40)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("长按印记切换文字")
    }

    private var textOpacity: Double {
        Double(max(0, 1 - dissolveProgress * 1.18))
    }

    private func attentionOffset(at date: Date) -> CGFloat {
        guard !reduceMotion else { return 0 }
        let phase = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: attentionLoopDuration)
            / attentionLoopDuration
        return -entranceAmplitude * CGFloat(0.5 + 0.5 * sin(phase * 2 * .pi))
    }
}
