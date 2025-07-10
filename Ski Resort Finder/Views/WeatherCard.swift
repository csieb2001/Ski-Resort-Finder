import SwiftUI
import Foundation

struct WeatherCard: View {
    let weather: WeatherData
    let openMeteoData: OpenMeteoWeatherData?
    let onTap: () -> Void
    @ObservedObject private var localization = LocalizationService.shared
    
    init(weather: WeatherData, openMeteoData: OpenMeteoWeatherData? = nil, onTap: @escaping () -> Void = {}) {
        self.weather = weather
        self.openMeteoData = openMeteoData
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact(.light)
            onTap()
        }) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // Header with weather icon and title
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.accent.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "cloud.sun.fill")
                            .font(DesignSystem.Typography.title3)
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("current_weather".localized)
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        if !weather.isRealData {
                            Text("demo".localized)
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(DesignSystem.Colors.warning)
                                .fontWeight(.semibold)
                                .padding(.horizontal, DesignSystem.Spacing.xs)
                                .padding(.vertical, DesignSystem.Spacing.xxs)
                                .background(DesignSystem.Colors.warning.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs, style: DesignSystem.CornerRadius.continuous))
                        }
                    }
                    
                    Spacer()
                    
                    // Chevron Icon für Detail-Ansicht
                    Image(systemName: "chevron.right")
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            
                // Main temperature and weather info
                HStack(alignment: .top, spacing: DesignSystem.Spacing.lg) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("\(Int(weather.main.temp))°C")
                            .font(DesignSystem.Typography.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text(weather.weather.first?.description.mappedWeatherDescription() ?? "")
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .lineLimit(2)
                        
                        // Feels like temperature
                        Text(String(format: "feels_like".localized, Int(weather.main.feelsLike)))
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                    
                    Spacer()
                
                    // Weather details in modern cards
                    VStack(alignment: .trailing, spacing: DesignSystem.Spacing.sm) {
                        // Snow information (important for skiers)
                        if let snow = weather.snow {
                            if let oneHour = snow.oneHour, oneHour > 0 {
                                WeatherInfoChip(
                                    icon: "cloud.snow.fill",
                                    text: "\(String(format: "%.1f", oneHour)) \("new_snow_mm".localized)",
                                    color: DesignSystem.Colors.accent
                                )
                            }
                            if let threeHours = snow.threeHours, threeHours > 0 {
                                WeatherInfoChip(
                                    icon: "snowflake",
                                    text: "\(String(format: "%.1f", threeHours)) \("snow_3h_mm".localized)",
                                    color: DesignSystem.Colors.accent
                                )
                            }
                        }
                        
                        // Wind (important for lift operations)
                        if let wind = weather.wind {
                            let windSpeedKmh = wind.speed * 3.6 // m/s to km/h
                            let windStrength = windSpeedKmh > 50 ? "wind_strong".localized : windSpeedKmh > 25 ? "wind_moderate".localized : "wind_weak".localized
                            let windColor = windSpeedKmh > 50 ? DesignSystem.Colors.error : windSpeedKmh > 25 ? DesignSystem.Colors.warning : DesignSystem.Colors.success
                            
                            WeatherInfoChip(
                                icon: "wind",
                                text: "\(String(format: "%.0f", windSpeedKmh)) km/h (\(windStrength))",
                                color: windColor
                            )
                        }
                        
                        // Humidity
                        WeatherInfoChip(
                            icon: "humidity.fill",
                            text: "\(weather.main.humidity)%",
                            color: DesignSystem.Colors.accent
                        )
                    }
                }
                
                // Temperature range at bottom
                HStack {
                    Spacer()
                    Text(String(format: "min_max_temp".localized, Int(weather.main.tempMin), Int(weather.main.tempMax)))
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.accent.opacity(0.08),
                        DesignSystem.Colors.accent.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: DesignSystem.CornerRadius.continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: DesignSystem.CornerRadius.continuous)
                    .stroke(DesignSystem.Colors.accent.opacity(0.2), lineWidth: 1)
            )
            .shadow(
                color: DesignSystem.Shadow.medium.color,
                radius: DesignSystem.Shadow.medium.radius,
                x: DesignSystem.Shadow.medium.x,
                y: DesignSystem.Shadow.medium.y
            )
        }
            }
}

// MARK: - Weather Info Chip
struct WeatherInfoChip: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(color)
            
            Text(text)
                .font(DesignSystem.Typography.caption1)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.primaryText)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: DesignSystem.CornerRadius.continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: DesignSystem.CornerRadius.continuous)
                .stroke(color.opacity(0.3), lineWidth: 0.5)
        )
    }
}