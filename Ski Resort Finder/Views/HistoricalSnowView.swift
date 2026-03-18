import SwiftUI
import CoreLocation

struct HistoricalSnowView: View {
    let historicalData: HistoricalSnowData?
    let error: Error?
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localization = LocalizationService.shared
    @StateObject private var weatherService = OpenMeteoService()
    @State private var isRetrying = false
    
    init(historicalData: HistoricalSnowData) {
        self.historicalData = historicalData
        self.error = nil
    }
    
    init(error: Error) {
        self.historicalData = nil
        self.error = error
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Mountain background
                MountainBackgroundView()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        
                        if let error = error {
                            // Error View
                            SnowDataErrorView(error: error) {
                                retryDataLoad()
                            }
                        } else if let historicalData = historicalData {
                            // Success View
                            // Zusammenfassung
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("snow_statistics_10y".localized)
                                    .font(DesignSystem.Typography.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                
                                HStack(spacing: DesignSystem.Spacing.md) {
                                    HistoricalSnowStatCard(
                                        title: "avg_snowfall".localized,
                                        value: String(format: "%.0f cm", historicalData.averageSnowfall),
                                        color: DesignSystem.Colors.snowfall
                                    )
                                    
                                    HistoricalSnowStatCard(
                                        title: "avg_snow_days".localized,
                                        value: "\(historicalData.averageSnowDays) \("days".localized)",
                                        color: DesignSystem.Colors.info
                                    )
                                }
                            }
                            .padding(DesignSystem.Spacing.lg)
                            .glassCard()
                        
                            // Schnee Trend Chart
                            SnowLineChart(yearlyData: historicalData.yearlyData)
                            
                            // Schneetage Trend Chart
                            SnowDaysChart(yearlyData: historicalData.yearlyData)
                        
                            // Jährliche Daten
                            Text("yearly_snow_values".localized)
                                .font(DesignSystem.Typography.headline)
                                .fontWeight(.bold)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                        
                            ForEach(historicalData.yearlyData.sorted(by: { $0.year > $1.year }), id: \.year) { yearData in
                                YearlySnowCard(yearData: yearData)
                            }
                            
                            // Schnee-Vergleich Chart
                            SnowComparisonChart(yearlyData: historicalData.yearlyData)
                        }
                        
                        Spacer()
                    }
                    .padding(DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("historical_snow_data".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close".localized) { dismiss() }
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
    }
    
    private func retryDataLoad() {
        guard !isRetrying else { return }
        isRetrying = true
        
        // TODO: Implement retry logic with coordinate
        // This would require passing the coordinate to this view
        // For now, we just dismiss and let the parent handle retry
        dismiss()
    }
}

struct HistoricalSnowStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            Text(value)
                .font(DesignSystem.Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .secondaryCard()
    }
}

struct YearlySnowCard: View {
    let yearData: YearlySnowData
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Jahr Header
            HStack {
                Text("winter_season".localized(with: yearData.year, yearData.year + 1))
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                Spacer()
                if yearData.totalSnowfall > 0 {
                    Image(systemName: "snowflake")
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(.blue)
                }
            }
            
            // Saison-Info
            if let seasonLength = yearData.seasonLength {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(DesignSystem.Colors.info)
                    Text("season".localized(with: yearData.formattedSeason))
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    Text("season_length_days".localized(with: seasonLength))
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            // Schnee-Statistiken
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                
                SnowStatItem(
                    icon: "cloud.snow.fill", 
                    title: "total_snowfall".localized,
                    value: String(format: "%.0f cm", yearData.totalSnowfall),
                    color: DesignSystem.Colors.snowfall
                )
                
                SnowStatItem(
                    icon: "thermometer.snowflake",
                    title: "snow_days".localized,
                    value: "\(yearData.snowDays)",
                    color: DesignSystem.Colors.info
                )
                
                SnowStatItem(
                    icon: "mountain.2.fill",
                    title: "avg_snow_depth".localized,
                    value: String(format: "%.0f cm", yearData.averageSnowDepth),
                    color: DesignSystem.Colors.elevation
                )
                
                SnowStatItem(
                    icon: "snowflake",
                    title: "max_daily_snow".localized,
                    value: String(format: "%.0f cm", yearData.peakSnowfall),
                    color: DesignSystem.Colors.accent
                )
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .primaryCard()
    }
}

struct SnowStatItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(DesignSystem.Typography.caption1)
                Spacer()
            }
            
            Text(title)
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .lineLimit(1)
            
            Text(value)
                .font(DesignSystem.Typography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.sm)
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: DesignSystem.CornerRadius.continuous))
    }
}

struct SnowComparisonChart: View {
    let yearlyData: [YearlySnowData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("snowfall_comparison".localized)
                .font(DesignSystem.Typography.headline)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            if !yearlyData.isEmpty {
                let maxSnowfall = yearlyData.map { $0.totalSnowfall }.max() ?? 1
                
                VStack(spacing: 8) {
                    ForEach(yearlyData.sorted(by: { $0.year > $1.year }), id: \.year) { yearData in
                        HStack {
                            Text("\(yearData.year)")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                .frame(width: 40, alignment: .leading)
                            
                            GeometryReader { geometry in
                                HStack(spacing: 0) {
                                    Rectangle()
                                        .fill(LinearGradient(
                                            colors: [DesignSystem.Colors.snowfall.opacity(0.7), DesignSystem.Colors.snowfall],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                        .frame(width: max(1, CGFloat(yearData.totalSnowfall / maxSnowfall) * geometry.size.width))
                                    
                                    Spacer(minLength: 0)
                                }
                            }
                            .frame(height: 20)
                            .background(DesignSystem.Colors.glassSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs, style: DesignSystem.CornerRadius.continuous))
                            
                            Text(String(format: "%.0f cm", yearData.totalSnowfall))
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                .frame(width: 50, alignment: .trailing)
                        }
                    }
                }
            } else {
                Text("no_comparison_data".localized)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .primaryCard()
    }
}

#Preview {
    let sampleData = HistoricalSnowData(
        coordinate: CLLocationCoordinate2D(latitude: 47.1296, longitude: 10.2686),
        yearlyData: [
            YearlySnowData(
                year: 2024,
                totalSnowfall: 420,
                averageSnowDepth: 85,
                snowDays: 92,
                peakSnowfall: 35,
                seasonStart: Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 15)),
                seasonEnd: Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 20))
            ),
            YearlySnowData(
                year: 2023,
                totalSnowfall: 380,
                averageSnowDepth: 75,
                snowDays: 88,
                peakSnowfall: 42,
                seasonStart: Calendar.current.date(from: DateComponents(year: 2023, month: 12, day: 8)),
                seasonEnd: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 25))
            ),
            YearlySnowData(
                year: 2022,
                totalSnowfall: 510,
                averageSnowDepth: 95,
                snowDays: 105,
                peakSnowfall: 55,
                seasonStart: Calendar.current.date(from: DateComponents(year: 2022, month: 11, day: 28)),
                seasonEnd: Calendar.current.date(from: DateComponents(year: 2023, month: 4, day: 2))
            ),
            YearlySnowData(
                year: 2021,
                totalSnowfall: 340,
                averageSnowDepth: 68,
                snowDays: 78,
                peakSnowfall: 28,
                seasonStart: Calendar.current.date(from: DateComponents(year: 2021, month: 12, day: 18)),
                seasonEnd: Calendar.current.date(from: DateComponents(year: 2022, month: 3, day: 15))
            ),
            YearlySnowData(
                year: 2020,
                totalSnowfall: 290,
                averageSnowDepth: 52,
                snowDays: 65,
                peakSnowfall: 22,
                seasonStart: Calendar.current.date(from: DateComponents(year: 2020, month: 12, day: 22)),
                seasonEnd: Calendar.current.date(from: DateComponents(year: 2021, month: 3, day: 28))
            ),
            YearlySnowData(
                year: 2019,
                totalSnowfall: 465,
                averageSnowDepth: 88,
                snowDays: 98,
                peakSnowfall: 48,
                seasonStart: Calendar.current.date(from: DateComponents(year: 2019, month: 12, day: 5)),
                seasonEnd: Calendar.current.date(from: DateComponents(year: 2020, month: 4, day: 8))
            ),
            YearlySnowData(
                year: 2018,
                totalSnowfall: 385,
                averageSnowDepth: 72,
                snowDays: 89,
                peakSnowfall: 38,
                seasonStart: Calendar.current.date(from: DateComponents(year: 2018, month: 12, day: 12)),
                seasonEnd: Calendar.current.date(from: DateComponents(year: 2019, month: 3, day: 28))
            ),
            YearlySnowData(
                year: 2017,
                totalSnowfall: 320,
                averageSnowDepth: 58,
                snowDays: 76,
                peakSnowfall: 32,
                seasonStart: Calendar.current.date(from: DateComponents(year: 2017, month: 12, day: 20)),
                seasonEnd: Calendar.current.date(from: DateComponents(year: 2018, month: 3, day: 18))
            ),
            YearlySnowData(
                year: 2016,
                totalSnowfall: 410,
                averageSnowDepth: 78,
                snowDays: 94,
                peakSnowfall: 45,
                seasonStart: Calendar.current.date(from: DateComponents(year: 2016, month: 12, day: 10)),
                seasonEnd: Calendar.current.date(from: DateComponents(year: 2017, month: 3, day: 30))
            ),
            YearlySnowData(
                year: 2015,
                totalSnowfall: 275,
                averageSnowDepth: 48,
                snowDays: 62,
                peakSnowfall: 28,
                seasonStart: Calendar.current.date(from: DateComponents(year: 2015, month: 12, day: 25)),
                seasonEnd: Calendar.current.date(from: DateComponents(year: 2016, month: 3, day: 12))
            )
        ],
        averageSnowfall: 378,
        averageSnowDays: 84
    )
    
    HistoricalSnowView(historicalData: sampleData)
}