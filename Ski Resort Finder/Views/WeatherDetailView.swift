import SwiftUI
import CoreLocation

struct WeatherDetailView: View {
    let weather: WeatherData
    let openMeteoData: OpenMeteoWeatherData?
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localization = LocalizationService.shared
    
    init(weather: WeatherData, openMeteoData: OpenMeteoWeatherData? = nil) {
        self.weather = weather
        self.openMeteoData = openMeteoData
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Current Weather Header
                    CurrentWeatherHeader(weather: weather)
                    
                    // Snow Information - Priority for Ski Resort
                    if hasSnowData {
                        SnowConditionsCard(weather: weather, hourlyData: openMeteoData?.hourly)
                    }
                    
                    // 24h Precipitation Forecast
                    if let hourlyData = openMeteoData?.hourly {
                        PrecipitationForecastCard(hourlyData: hourlyData)
                    }
                    
                    // Detailed Weather Conditions
                    DetailedConditionsCard(weather: weather, currentData: openMeteoData?.current)
                    
                    // 7-Day Forecast
                    if let dailyData = openMeteoData?.daily {
                        WeeklyForecastCard(dailyData: dailyData)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("detailed_weather".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close".localized) { dismiss() }
                }
            }
        }
    }
    
    private var hasSnowData: Bool {
        if let snow = weather.snow {
            return (snow.oneHour ?? 0) > 0 || (snow.threeHours ?? 0) > 0
        }
        if let hourly = openMeteoData?.hourly {
            return hourly.snowfall.prefix(24).contains { $0 > 0 }
        }
        return false
    }
}

// MARK: - Current Weather Header

struct CurrentWeatherHeader: View {
    let weather: WeatherData
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(Int(weather.main.temp))°C")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(weather.weather.first?.description.capitalized ?? "")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("feels_like".localized(with: Int(weather.main.feelsLike)))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Weather Icon
                VStack {
                    Image(systemName: weather.weather.first?.icon ?? "cloud.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .symbolEffect(.bounce.byLayer, options: .repeating)
                    
                    if !weather.isRealData {
                        Text("demo".localized)
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            
            // Temperature Range
            HStack {
                Text("min_max_temp".localized(with: Int(weather.main.tempMin), Int(weather.main.tempMax)))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(15)
    }
}

// MARK: - Snow Conditions Card

struct SnowConditionsCard: View {
    let weather: WeatherData
    let hourlyData: OpenMeteoHourlyWeather?
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "snowflake")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("snow_conditions".localized)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                
                // Current Snow Fall
                if let snow = weather.snow, let oneHour = snow.oneHour, oneHour > 0 {
                    SnowStatCard(
                        icon: "cloud.snow.fill",
                        title: "current_snowfall".localized,
                        value: "\(String(format: "%.1f", oneHour)) mm/h",
                        color: .blue
                    )
                }
                
                if let snow = weather.snow, let threeHours = snow.threeHours, threeHours > 0 {
                    SnowStatCard(
                        icon: "snowflake",
                        title: "snow_3h".localized,
                        value: "\(String(format: "%.1f", threeHours)) mm",
                        color: .cyan
                    )
                }
                
                // 24h Snow Forecast
                if let hourly = hourlyData {
                    let next24hSnow = Array(hourly.snowfall.prefix(24)).reduce(0, +)
                    if next24hSnow > 0 {
                        SnowStatCard(
                            icon: "cloud.snow",
                            title: "snow_24h_forecast".localized,
                            value: "\(String(format: "%.1f", next24hSnow)) mm",
                            color: .indigo
                        )
                    }
                    
                    // Snow Probability
                    if let precipitation = hourly.precipitationProbability {
                        let avgProbability = Array(precipitation.prefix(12)).reduce(0, +) / 12
                        SnowStatCard(
                            icon: "percent",
                            title: "snow_probability".localized,
                            value: "\(avgProbability)%",
                            color: .purple
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(15)
    }
}

// MARK: - Precipitation Forecast Card

struct PrecipitationForecastCard: View {
    let hourlyData: OpenMeteoHourlyWeather
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("precipitation_24h".localized)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<min(24, hourlyData.time.count), id: \.self) { index in
                        PrecipitationBar(
                            hour: formatHour(hourlyData.time[index]),
                            precipitation: hourlyData.precipitation[index],
                            snowfall: hourlyData.snowfall[index],
                            temperature: hourlyData.temperature2m[index]
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(15)
    }
    
    private func formatHour(_ timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        
        if let date = formatter.date(from: timeString) {
            let hourFormatter = DateFormatter()
            hourFormatter.dateFormat = "HH"
            return hourFormatter.string(from: date)
        }
        return timeString.suffix(5).prefix(2).description
    }
}

// MARK: - Detailed Conditions Card

struct DetailedConditionsCard: View {
    let weather: WeatherData
    let currentData: OpenMeteoCurrentWeather?
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("detailed_conditions".localized)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                
                // Wind
                if let wind = weather.wind {
                    let windSpeedKmh = wind.speed * 3.6
                    let windStrength = windSpeedKmh > 50 ? "wind_strong".localized : windSpeedKmh > 25 ? "wind_moderate".localized : "wind_weak".localized
                    
                    DetailConditionCard(
                        icon: "wind",
                        title: "wind_speed".localized,
                        value: "\(String(format: "%.0f", windSpeedKmh)) km/h",
                        subtitle: windStrength,
                        color: windSpeedKmh > 50 ? .red : windSpeedKmh > 25 ? .orange : .gray
                    )
                }
                
                // Humidity
                DetailConditionCard(
                    icon: "humidity.fill",
                    title: "humidity".localized,
                    value: "\(weather.main.humidity)%",
                    subtitle: weather.main.humidity > 80 ? "high".localized : weather.main.humidity < 40 ? "low".localized : "normal".localized,
                    color: .cyan
                )
                
                // Pressure
                DetailConditionCard(
                    icon: "barometer",
                    title: "pressure".localized,
                    value: "\(weather.main.pressure) hPa",
                    subtitle: weather.main.pressure > 1020 ? "high".localized : weather.main.pressure < 1000 ? "low".localized : "normal".localized,
                    color: .indigo
                )
                
                // Precipitation
                if let currentPrecipitation = currentData?.precipitation, currentPrecipitation > 0 {
                    DetailConditionCard(
                        icon: "drop.fill",
                        title: "precipitation".localized,
                        value: "\(String(format: "%.1f", currentPrecipitation)) mm",
                        subtitle: "current".localized,
                        color: .blue
                    )
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(15)
    }
}

// MARK: - Weekly Forecast Card

struct WeeklyForecastCard: View {
    let dailyData: OpenMeteoDailyWeather
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("weekly_forecast".localized)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(0..<min(7, dailyData.time.count), id: \.self) { index in
                    DailyForecastRow(
                        date: dailyData.time[index],
                        minTemp: dailyData.temperature2mMin[index],
                        maxTemp: dailyData.temperature2mMax[index],
                        precipitation: dailyData.precipitationSum[index],
                        snowfall: dailyData.snowfallSum[index],
                        weatherCode: dailyData.weatherCode[index]
                    )
                    
                    if index < min(6, dailyData.time.count - 1) {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(15)
    }
}

// MARK: - Helper Components

struct SnowStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DetailConditionCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct PrecipitationBar: View {
    let hour: String
    let precipitation: Double
    let snowfall: Double
    let temperature: Double
    
    var body: some View {
        VStack(spacing: 4) {
            Text(hour)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .bottom) {
                // Background
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 20, height: 60)
                
                // Precipitation bar
                if precipitation > 0 {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 20, height: max(2, min(60, precipitation * 6)))
                }
                
                // Snow overlay
                if snowfall > 0 {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 20, height: max(2, min(60, snowfall * 8)))
                        .overlay(
                            Rectangle()
                                .stroke(Color.blue, lineWidth: 1)
                        )
                }
            }
            .cornerRadius(4)
            
            Text("\(Int(temperature))°")
                .font(.caption2)
                .foregroundColor(temperature < 0 ? .blue : .primary)
        }
    }
}

struct DailyForecastRow: View {
    let date: String
    let minTemp: Double
    let maxTemp: Double
    let precipitation: Double
    let snowfall: Double
    let weatherCode: Int
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        HStack {
            // Date
            VStack(alignment: .leading) {
                Text(formatDate(date))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(formatWeekday(date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            // Weather Icon
            Image(systemName: OpenMeteoService.weatherIcon(for: weatherCode))
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Spacer()
            
            // Precipitation
            if precipitation > 0 || snowfall > 0 {
                VStack(alignment: .trailing) {
                    if snowfall > 0 {
                        Text("\(String(format: "%.1f", snowfall))mm")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    if precipitation > 0 {
                        Text("\(String(format: "%.1f", precipitation))mm")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 50, alignment: .trailing)
            } else {
                Spacer()
                    .frame(width: 50)
            }
            
            // Temperature
            VStack(alignment: .trailing) {
                Text("\(Int(maxTemp))°")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(Int(minTemp))°")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 40, alignment: .trailing)
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "dd.MM"
            return outputFormatter.string(from: date)
        }
        return dateString
    }
    
    private func formatWeekday(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "EEE"
            outputFormatter.locale = Locale(identifier: localization.currentLanguage.code)
            return outputFormatter.string(from: date)
        }
        return ""
    }
}

#Preview {
    let sampleWeather = WeatherData(
        main: WeatherData.MainWeather(temp: -2, feelsLike: -5, tempMin: -8, tempMax: 3, pressure: 1013, humidity: 78),
        weather: [WeatherData.Weather(id: 71, main: "Snow", description: "Schneefall", icon: "cloud.snow.fill")],
        wind: WeatherData.Wind(speed: 8.5, deg: 230),
        snow: WeatherData.Snow(oneHour: 2.5, threeHours: 6.8),
        name: "St. Anton am Arlberg",
        isRealData: false
    )
    
    WeatherDetailView(weather: sampleWeather)
}