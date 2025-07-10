import SwiftUI

struct MountainBackgroundView: View {
    var body: some View {
        ZStack {
            // Base gradient background
            DesignSystem.Colors.mountainGradient
                .ignoresSafeArea()
            
            // Animated mountain silhouettes
            GeometryReader { geometry in
                // Back mountains (lighter)
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    path.move(to: CGPoint(x: 0, y: height * 0.6))
                    path.addCurve(to: CGPoint(x: width * 0.3, y: height * 0.4),
                                control1: CGPoint(x: width * 0.1, y: height * 0.5),
                                control2: CGPoint(x: width * 0.2, y: height * 0.35))
                    path.addCurve(to: CGPoint(x: width * 0.7, y: height * 0.3),
                                control1: CGPoint(x: width * 0.5, y: height * 0.2),
                                control2: CGPoint(x: width * 0.6, y: height * 0.25))
                    path.addCurve(to: CGPoint(x: width, y: height * 0.5),
                                control1: CGPoint(x: width * 0.8, y: height * 0.4),
                                control2: CGPoint(x: width * 0.9, y: height * 0.45))
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Front mountains (darker)
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    path.move(to: CGPoint(x: 0, y: height * 0.8))
                    path.addCurve(to: CGPoint(x: width * 0.4, y: height * 0.5),
                                control1: CGPoint(x: width * 0.15, y: height * 0.65),
                                control2: CGPoint(x: width * 0.3, y: height * 0.55))
                    path.addCurve(to: CGPoint(x: width * 0.8, y: height * 0.6),
                                control1: CGPoint(x: width * 0.6, y: height * 0.4),
                                control2: CGPoint(x: width * 0.7, y: height * 0.5))
                    path.addCurve(to: CGPoint(x: width, y: height * 0.7),
                                control1: CGPoint(x: width * 0.9, y: height * 0.65),
                                control2: CGPoint(x: width * 0.95, y: height * 0.68))
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            
            // Subtle stars/snow effect
            ForEach(0..<20, id: \.self) { _ in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.1...0.3)))
                    .frame(width: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height * 0.6)
                    )
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