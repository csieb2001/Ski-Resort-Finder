import SwiftUI

struct MountainBackgroundView: View {
    var body: some View {
        ZStack {
            // Rich gradient background for Liquid Glass
            LinearGradient(
                colors: [
                    Color(hex: "0B1A3B"),
                    Color(hex: "0E2246"),
                    Color(hex: "122952"),
                    Color(hex: "0D1E3E")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Warm ambient glow (top-left)
            RadialGradient(
                colors: [Color(hex: "4A90E2").opacity(0.2), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Second glow (bottom-right, warm)
            RadialGradient(
                colors: [Color(hex: "6366F1").opacity(0.1), Color.clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Mountain silhouettes
            GeometryReader { geometry in
                let w = geometry.size.width
                let h = geometry.size.height

                // Back mountains (subtle blue)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h * 0.55))
                    path.addCurve(to: CGPoint(x: w * 0.3, y: h * 0.38),
                                control1: CGPoint(x: w * 0.1, y: h * 0.45),
                                control2: CGPoint(x: w * 0.2, y: h * 0.32))
                    path.addCurve(to: CGPoint(x: w * 0.7, y: h * 0.28),
                                control1: CGPoint(x: w * 0.5, y: h * 0.18),
                                control2: CGPoint(x: w * 0.6, y: h * 0.22))
                    path.addCurve(to: CGPoint(x: w, y: h * 0.45),
                                control1: CGPoint(x: w * 0.8, y: h * 0.35),
                                control2: CGPoint(x: w * 0.9, y: h * 0.40))
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Front mountains
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h * 0.75))
                    path.addCurve(to: CGPoint(x: w * 0.4, y: h * 0.48),
                                control1: CGPoint(x: w * 0.15, y: h * 0.60),
                                control2: CGPoint(x: w * 0.3, y: h * 0.50))
                    path.addCurve(to: CGPoint(x: w * 0.8, y: h * 0.55),
                                control1: CGPoint(x: w * 0.6, y: h * 0.38),
                                control2: CGPoint(x: w * 0.7, y: h * 0.45))
                    path.addCurve(to: CGPoint(x: w, y: h * 0.65),
                                control1: CGPoint(x: w * 0.9, y: h * 0.60),
                                control2: CGPoint(x: w * 0.95, y: h * 0.62))
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.04), Color.white.opacity(0.01)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }

            // Subtle stars
            GeometryReader { geo in
                ForEach(0..<15, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.15...0.4)))
                        .frame(width: CGFloat.random(in: 1...2.5))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height * 0.5)
                        )
                }
            }
        }
    }
}

struct MountainBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        MountainBackgroundView()
            .preferredColorScheme(.dark)
    }
}
