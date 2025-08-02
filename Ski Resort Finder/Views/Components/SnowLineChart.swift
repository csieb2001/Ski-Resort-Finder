import SwiftUI

struct SnowLineChart: View {
    let yearlyData: [YearlySnowData]
    
    private var sortedData: [YearlySnowData] {
        yearlyData.sorted(by: { $0.year < $1.year })
    }
    
    private var maxSnowfall: Double {
        sortedData.map { $0.totalSnowfall }.max() ?? 400
    }
    
    private var minSnowfall: Double {
        sortedData.map { $0.totalSnowfall }.min() ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Chart Title
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(DesignSystem.Colors.snowfall)
                    .font(DesignSystem.Typography.headline)
                
                Text("snowfall_trend".localized)
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                Text("10_years".localized)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(DesignSystem.Colors.glassSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: DesignSystem.CornerRadius.continuous))
            }
            
            if !sortedData.isEmpty {
                // Chart Container
                VStack(spacing: DesignSystem.Spacing.sm) {
                    // Chart Area
                    GeometryReader { geometry in
                        ZStack {
                            // Background Grid
                            chartGrid(in: geometry.size)
                            
                            // Snow Line
                            snowfallLine(in: geometry.size)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            DesignSystem.Colors.snowfall.opacity(0.8),
                                            DesignSystem.Colors.info.opacity(0.6)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                                )
                            
                            // Gradient Fill
                            snowfallFill(in: geometry.size)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            DesignSystem.Colors.snowfall.opacity(0.3),
                                            DesignSystem.Colors.snowfall.opacity(0.1),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            // Data Points
                            dataPoints(in: geometry.size)
                        }
                    }
                    .frame(height: 200)
                    
                    // X-Axis Labels
                    HStack {
                        ForEach(Array(sortedData.enumerated()), id: \.offset) { index, yearData in
                            VStack(spacing: DesignSystem.Spacing.xs) {
                                Text("\(yearData.year)")
                                    .font(DesignSystem.Typography.caption1)
                                    .fontWeight(.medium)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                
                                Text(String(format: "%.0f cm", yearData.totalSnowfall))
                                    .font(DesignSystem.Typography.caption2)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.top, DesignSystem.Spacing.sm)
                }
                
                // Y-Axis Info
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        HStack {
                            Circle()
                                .fill(DesignSystem.Colors.snowfall)
                                .frame(width: 8, height: 8)
                            Text("total_snowfall".localized)
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                        }
                        
                        HStack {
                            Text("range".localized)
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            Text("\(Int(minSnowfall)) - \(Int(maxSnowfall)) cm")
                                .font(DesignSystem.Typography.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                        }
                    }
                    
                    Spacer()
                    
                    // Trend Indicator
                    if sortedData.count >= 2 {
                        let trend = sortedData.last!.totalSnowfall - sortedData.first!.totalSnowfall
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: trend > 0 ? "arrow.up.right" : trend < 0 ? "arrow.down.right" : "arrow.right")
                                .foregroundColor(trend > 0 ? DesignSystem.Colors.success : trend < 0 ? DesignSystem.Colors.error : DesignSystem.Colors.warning)
                                .font(DesignSystem.Typography.caption1)
                            
                            Text(trend > 0 ? "increasing_trend".localized : trend < 0 ? "decreasing_trend".localized : "stable_trend".localized)
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(DesignSystem.Colors.glassSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: DesignSystem.CornerRadius.continuous))
                    }
                }
                .padding(.top, DesignSystem.Spacing.md)
                
            } else {
                Text("no_chart_data".localized)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(DesignSystem.Colors.glassSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .glassCard()
    }
    
    // MARK: - Chart Components
    
    private func chartGrid(in size: CGSize) -> some View {
        Path { path in
            let stepY = size.height / 4
            let stepX = size.width / max(1, CGFloat(sortedData.count - 1))
            
            // Horizontal grid lines
            for i in 0...4 {
                let y = CGFloat(i) * stepY
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            
            // Vertical grid lines
            for i in 0..<sortedData.count {
                let x = CGFloat(i) * stepX
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
        }
        .stroke(DesignSystem.Colors.glassStroke.opacity(0.3), style: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
    }
    
    private func snowfallLine(in size: CGSize) -> Path {
        Path { path in
            guard !sortedData.isEmpty else { return }
            
            let stepX = size.width / max(1, CGFloat(sortedData.count - 1))
            let range = maxSnowfall - minSnowfall
            
            // Calculate all points first for smooth curves
            var points: [CGPoint] = []
            for (index, yearData) in sortedData.enumerated() {
                let x = CGFloat(index) * stepX
                let normalizedValue = range > 0 ? (yearData.totalSnowfall - minSnowfall) / range : 0
                let y = size.height - (CGFloat(normalizedValue) * size.height)
                points.append(CGPoint(x: x, y: y))
            }
            
            // Create smooth curve using control points
            if points.count >= 2 {
                path.move(to: points[0])
                
                if points.count == 2 {
                    path.addLine(to: points[1])
                } else {
                    for i in 1..<points.count {
                        let currentPoint = points[i]
                        let previousPoint = points[i-1]
                        
                        // Calculate control points for smooth curves
                        let controlPointDistance: CGFloat = 20
                        let controlPoint1 = CGPoint(
                            x: previousPoint.x + controlPointDistance,
                            y: previousPoint.y
                        )
                        let controlPoint2 = CGPoint(
                            x: currentPoint.x - controlPointDistance, 
                            y: currentPoint.y
                        )
                        
                        path.addCurve(to: currentPoint, control1: controlPoint1, control2: controlPoint2)
                    }
                }
            }
        }
    }
    
    private func snowfallFill(in size: CGSize) -> Path {
        Path { path in
            guard !sortedData.isEmpty else { return }
            
            let stepX = size.width / max(1, CGFloat(sortedData.count - 1))
            let range = maxSnowfall - minSnowfall
            
            // Start from bottom left
            path.move(to: CGPoint(x: 0, y: size.height))
            
            // Draw line to first data point
            if let firstData = sortedData.first {
                let normalizedValue = range > 0 ? (firstData.totalSnowfall - minSnowfall) / range : 0
                let y = size.height - (CGFloat(normalizedValue) * size.height)
                path.addLine(to: CGPoint(x: 0, y: y))
            }
            
            // Calculate all points for smooth fill
            var points: [CGPoint] = []
            for (index, yearData) in sortedData.enumerated() {
                let x = CGFloat(index) * stepX
                let normalizedValue = range > 0 ? (yearData.totalSnowfall - minSnowfall) / range : 0
                let y = size.height - (CGFloat(normalizedValue) * size.height)
                points.append(CGPoint(x: x, y: y))
            }
            
            // Add smooth curve for fill
            if points.count >= 2 {
                if points.count == 2 {
                    path.addLine(to: points[1])
                } else {
                    for i in 1..<points.count {
                        let currentPoint = points[i]
                        let previousPoint = points[i-1]
                        
                        let controlPointDistance: CGFloat = 20
                        let controlPoint1 = CGPoint(
                            x: previousPoint.x + controlPointDistance,
                            y: previousPoint.y
                        )
                        let controlPoint2 = CGPoint(
                            x: currentPoint.x - controlPointDistance,
                            y: currentPoint.y
                        )
                        
                        path.addCurve(to: currentPoint, control1: controlPoint1, control2: controlPoint2)
                    }
                }
            }
            
            // Close the path to bottom right
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.closeSubpath()
        }
    }
    
    private func dataPoints(in size: CGSize) -> some View {
        ZStack {
            ForEach(Array(sortedData.enumerated()), id: \.offset) { index, yearData in
                let stepX = size.width / max(1, CGFloat(sortedData.count - 1))
                let range = maxSnowfall - minSnowfall
                let x = CGFloat(index) * stepX
                let normalizedValue = range > 0 ? (yearData.totalSnowfall - minSnowfall) / range : 0
                let y = size.height - (CGFloat(normalizedValue) * size.height)
                
                Circle()
                    .fill(DesignSystem.Colors.snowfall)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(DesignSystem.Colors.background, lineWidth: 2)
                    )
                    .position(x: x, y: y)
                    .shadow(color: DesignSystem.Colors.snowfall.opacity(0.5), radius: 4)
            }
        }
    }
}

#Preview {
    let sampleData = [
        YearlySnowData(
            year: 2020,
            totalSnowfall: 285.0,
            averageSnowDepth: 38.0,
            snowDays: 72,
            peakSnowfall: 22.0,
            seasonStart: Calendar.current.date(from: DateComponents(year: 2020, month: 12, day: 20)),
            seasonEnd: Calendar.current.date(from: DateComponents(year: 2021, month: 4, day: 8))
        ),
        YearlySnowData(
            year: 2021,
            totalSnowfall: 405.0,
            averageSnowDepth: 58.0,
            snowDays: 95,
            peakSnowfall: 40.0,
            seasonStart: Calendar.current.date(from: DateComponents(year: 2021, month: 11, day: 28)),
            seasonEnd: Calendar.current.date(from: DateComponents(year: 2022, month: 4, day: 12))
        ),
        YearlySnowData(
            year: 2022,
            totalSnowfall: 320.0,
            averageSnowDepth: 45.0,
            snowDays: 78,
            peakSnowfall: 25.0,
            seasonStart: Calendar.current.date(from: DateComponents(year: 2022, month: 12, day: 15)),
            seasonEnd: Calendar.current.date(from: DateComponents(year: 2023, month: 4, day: 10))
        ),
        YearlySnowData(
            year: 2023,
            totalSnowfall: 450.0,
            averageSnowDepth: 62.0,
            snowDays: 88,
            peakSnowfall: 35.0,
            seasonStart: Calendar.current.date(from: DateComponents(year: 2023, month: 12, day: 8)),
            seasonEnd: Calendar.current.date(from: DateComponents(year: 2024, month: 4, day: 8))
        ),
        YearlySnowData(
            year: 2024,
            totalSnowfall: 380.0,
            averageSnowDepth: 51.0,
            snowDays: 82,
            peakSnowfall: 28.0,
            seasonStart: Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 12)),
            seasonEnd: Calendar.current.date(from: DateComponents(year: 2025, month: 4, day: 5))
        )
    ]
    
    ZStack {
        MountainBackgroundView()
            .ignoresSafeArea()
        
        ScrollView {
            SnowLineChart(yearlyData: sampleData)
                .padding()
        }
    }
    .preferredColorScheme(.dark)
}