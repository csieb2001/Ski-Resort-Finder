import SwiftUI
import MapKit

struct ModernResortInfoCard: View {
    let resort: SkiResort
    let onTap: () -> Void
    @StateObject private var weatherService = OpenMeteoService()
    @State private var historicalSnowData: HistoricalSnowData?
    @State private var showSnowDetails = false
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            
            // Resort Card
            Button(action: {
                HapticFeedback.impact(.light)
                onTap()
            }) {
            VStack(spacing: 0) {
                // Header with resort info
                HStack(spacing: DesignSystem.Spacing.md) {
                    // Resort Icon
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.primary.opacity(0.15))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "mountain.2")
                            .font(DesignSystem.Typography.title2)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(resort.name)
                            .font(DesignSystem.Typography.title3)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .lineLimit(2)
                        
                        Text("\(resort.country.localizedCountryName()), \(resort.region)")
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Chevron indicator
                    Image(systemName: "chevron.right")
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
                .padding(DesignSystem.Spacing.md)
                
                // Statistics Grid
                HStack(spacing: DesignSystem.Spacing.md) {
                    // Slopes
                    ModernStatCard(
                        icon: "figure.skiing.downhill",
                        value: "\(resort.totalSlopes)",
                        unit: "km",
                        label: "slopes".localized,
                        color: DesignSystem.Colors.primary
                    )
                    
                    // Max Height
                    ModernStatCard(
                        icon: "mountain.2",
                        value: "\(resort.maxElevation)",
                        unit: "m",
                        label: "max_height".localized,
                        color: DesignSystem.Colors.success
                    )
                    
                    // Average Snow (3Y) - Display only
                    ModernStatCard(
                        icon: "cloud.snow.fill",
                        value: historicalSnowData?.averageSnowfall != nil ? String(format: "%.0f", historicalSnowData!.averageSnowfall) : "---",
                        unit: "cm",
                        label: "avg_snow_5y".localized,
                        color: DesignSystem.Colors.accent
                    )
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.sm)
                
                // Historic Snow Statistics Button - Larger, below the 3 elements
                Button(action: {
                    HapticFeedback.impact(.light)
                    showSnowDetails = true
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "chart.bar.fill")
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(DesignSystem.Colors.accent)
                        
                        Text("detailed_snow_statistics".localized)
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.accent)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(DesignSystem.Typography.caption1)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: DesignSystem.CornerRadius.continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: DesignSystem.CornerRadius.continuous)
                    .stroke(DesignSystem.Colors.separator.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(
                color: DesignSystem.Shadow.medium.color,
                radius: DesignSystem.Shadow.medium.radius,
                x: DesignSystem.Shadow.medium.x,
                y: DesignSystem.Shadow.medium.y
            )
            }
        }
        .onAppear {
            loadHistoricalSnowData()
        }
        .sheet(isPresented: $showSnowDetails) {
            if let snowData = historicalSnowData {
                HistoricalSnowView(historicalData: snowData)
            } else {
                // In case of error, show error view
                HistoricalSnowView(error: OpenMeteoError.networkError("Schneedaten konnten nicht geladen werden"))
            }
        }
    }
    
    private func loadHistoricalSnowData() {
        Task {
            do {
                let snowData = try await weatherService.fetchHistoricalSnowData(for: resort.coordinate)
                await MainActor.run {
                    self.historicalSnowData = snowData
                }
            } catch {
                print("Error loading historical snow data: \(error)")
            }
        }
    }
}

// MARK: - Modern Stat Card
struct ModernStatCard: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            // Value and unit
            HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.xxs) {
                Text(value)
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(unit)
                    .font(DesignSystem.Typography.caption1)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            // Label
            Text(label)
                .font(DesignSystem.Typography.caption2)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
    }
}

#Preview {
    VStack {
        ModernResortInfoCard(
            resort: SkiResort(
                name: "Sölden",
                country: "Österreich",
                region: "Tirol",
                totalSlopes: 144,
                maxElevation: 3340,
                minElevation: 1350,
                coordinate: CLLocationCoordinate2D(latitude: 46.9691, longitude: 11.0091),
                liftCount: 31
            )
        ) {
            print("Resort tapped")
        }
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}