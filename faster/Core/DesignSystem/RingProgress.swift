import SwiftUI

struct RingProgress: View {
    var progress: Double
    var tint: Color = AppColor.accent
    var lineWidth: CGFloat = 14
    var showGlow: Bool = true

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.12), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    LinearGradient(
                        colors: [tint, tint.opacity(0.65)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: showGlow ? tint.opacity(0.38) : .clear, radius: 8)
                .animation(.spring(response: 0.65, dampingFraction: 0.82), value: clamped)
        }
    }
}
