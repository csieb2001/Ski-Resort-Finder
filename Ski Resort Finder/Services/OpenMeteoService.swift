import Foundation
import CoreLocation
import Combine

class OpenMeteoService: ObservableObject {
    
    private let baseURL = "https://api.open-meteo.com/v1"
    
    // MARK: - Weather Forecast
    func fetchWeather(for coordinate: CLLocationCoordinate2D) async throws -> OpenMeteoWeatherData {
        
        var components = URLComponents(string: "\(baseURL)/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,wind_direction_10m"),
            URLQueryItem(name: "hourly", value: "temperature_2m,precipitation_probability,precipitation,snowfall,weather_code,wind_speed_10m"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,precipitation_sum,snowfall_sum,weather_code"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7")
        ]
        
        guard let url = components.url else {
            throw OpenMeteoError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenMeteoError.invalidResponse
        }
        
        do {
            let weatherData = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            return OpenMeteoWeatherData(from: weatherData, coordinate: coordinate)
        } catch {
            print("Open-Meteo Decoding Error: \(error)")
            throw OpenMeteoError.decodingError
        }
    }
    
    // MARK: - Historical Snow Data (Will use ERA5 in future)
    func fetchHistoricalSnowData(for coordinate: CLLocationCoordinate2D) async throws -> HistoricalSnowData {
        print("🌨️ OpenMeteo: Loading historical snow data for \(coordinate.latitude), \(coordinate.longitude)")
        
        let currentYear = Calendar.current.component(.year, from: Date())
        let years = Array((currentYear-9)...currentYear) // Letzten 10 Jahre
        var yearlyData: [YearlySnowData] = []
        
        for year in years {
            do {
                let snowData = try await fetchSnowDataForYear(coordinate: coordinate, year: year)
                yearlyData.append(snowData)
                print("✅ OpenMeteo: Jahr \(year) erfolgreich geladen - \(String(format: "%.1f", snowData.totalSnowfall))cm")
            } catch {
                print("❌ OpenMeteo: Fehler für Jahr \(year): \(error)")
                // Bei der KEINE FAKE-DATEN POLICY: Jahr überspringen
            }
        }
        
        guard !yearlyData.isEmpty else {
            throw OpenMeteoError.noDataAvailable("Keine historischen Schneedaten verfügbar")
        }
        
        return HistoricalSnowData(
            coordinate: coordinate,
            yearlyData: yearlyData,
            averageSnowfall: yearlyData.map { $0.totalSnowfall }.reduce(0, +) / Double(yearlyData.count),
            averageSnowDays: Int(yearlyData.map { Double($0.snowDays) }.reduce(0, +) / Double(yearlyData.count))
        )
    }
    
    private func fetchSnowDataForYear(coordinate: CLLocationCoordinate2D, year: Int) async throws -> YearlySnowData {
        // OpenMeteo Archive API für historische Daten
        var components = URLComponents(string: "https://archive-api.open-meteo.com/v1/archive")!
        
        // Zeitraum: Wintersaison (November bis April)
        let startDate = "\(year-1)-11-01"
        let endDate = "\(year)-04-30"
        
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "start_date", value: startDate),
            URLQueryItem(name: "end_date", value: endDate),
            URLQueryItem(name: "daily", value: "snowfall_sum,temperature_2m_mean"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        
        guard let url = components.url else {
            throw OpenMeteoError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenMeteoError.networkError("HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        
        // Parse OpenMeteo Archive Response
        let archiveResponse = try JSONDecoder().decode(OpenMeteoArchiveResponse.self, from: data)
        
        // Berechne Schnee-Statistiken
        var totalSnowfall: Double = 0
        var snowDays = 0
        var peakSnowfall: Double = 0
        var firstSnowDate: Date?
        var lastSnowDate: Date?
        
        if let snowfallData = archiveResponse.daily.snowfall_sum {
            let timeData = archiveResponse.daily.time
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            for (index, snowfall) in snowfallData.enumerated() {
                if let snow = snowfall, snow > 0.1 { // Mindestens 0.1mm als Schneetag
                    totalSnowfall += snow
                    snowDays += 1
                    peakSnowfall = max(peakSnowfall, snow)
                    
                    // Datum bestimmen
                    if index < timeData.count,
                       let date = dateFormatter.date(from: timeData[index]) {
                        if firstSnowDate == nil {
                            firstSnowDate = date
                        }
                        lastSnowDate = date
                    }
                }
            }
        }
        
        return YearlySnowData(
            year: year,
            totalSnowfall: totalSnowfall,
            averageSnowDepth: 0, // OpenMeteo Archive hat keine Schnee-Tiefe
            snowDays: snowDays,
            peakSnowfall: peakSnowfall,
            seasonStart: firstSnowDate,
            seasonEnd: lastSnowDate
        )
    }
    
    
    // MARK: - Weather Code Translation
    static func weatherDescription(for code: Int) -> String {
        switch code {
        case 0: return "Klarer Himmel"
        case 1: return "Überwiegend klar"
        case 2: return "Teilweise bewölkt"
        case 3: return "Bewölkt"
        case 45, 48: return "Nebel"
        case 51, 53, 55: return "Nieselregen"
        case 56, 57: return "Gefrierender Nieselregen"
        case 61, 63, 65: return "Regen"
        case 66, 67: return "Gefrierender Regen"
        case 71, 73, 75: return "Schneefall"
        case 77: return "Schneekörner"
        case 80, 81, 82: return "Regenschauer"
        case 85, 86: return "Schneeschauer"
        case 95, 96, 99: return "Gewitter"
        default: return "Unbekannt"
        }
    }
    
    static func weatherIcon(for code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1: return "sun.max.circle.fill"
        case 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55: return "cloud.drizzle.fill"
        case 56, 57: return "cloud.sleet.fill"
        case 61, 63, 65: return "cloud.rain.fill"
        case 66, 67: return "cloud.sleet.fill"
        case 71, 73, 75, 77: return "cloud.snow.fill"
        case 80, 81, 82: return "cloud.heavyrain.fill"
        case 85, 86: return "cloud.snow.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Data Models

struct OpenMeteoResponse: Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let current: OpenMeteoCurrentWeather
    let hourly: OpenMeteoHourlyWeather?
    let daily: OpenMeteoDailyWeather?
}

struct OpenMeteoCurrentWeather: Codable {
    let time: String
    let temperature2m: Double
    let relativeHumidity2m: Int
    let apparentTemperature: Double
    let precipitation: Double
    let weatherCode: Int
    let windSpeed10m: Double
    let windDirection10m: Double
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case relativeHumidity2m = "relative_humidity_2m"
        case apparentTemperature = "apparent_temperature"
        case precipitation
        case weatherCode = "weather_code"
        case windSpeed10m = "wind_speed_10m"
        case windDirection10m = "wind_direction_10m"
    }
}

struct OpenMeteoHourlyWeather: Codable {
    let time: [String]
    let temperature2m: [Double]
    let precipitationProbability: [Int]?
    let precipitation: [Double]
    let snowfall: [Double]
    let weatherCode: [Int]
    let windSpeed10m: [Double]
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case precipitationProbability = "precipitation_probability"
        case precipitation
        case snowfall
        case weatherCode = "weather_code"
        case windSpeed10m = "wind_speed_10m"
    }
}

struct OpenMeteoDailyWeather: Codable {
    let time: [String]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let precipitationSum: [Double]
    let snowfallSum: [Double]
    let weatherCode: [Int]
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case precipitationSum = "precipitation_sum"
        case snowfallSum = "snowfall_sum"
        case weatherCode = "weather_code"
    }
}

// MARK: - Unified Weather Data (compatible with existing UI)

struct OpenMeteoWeatherData {
    let coordinate: CLLocationCoordinate2D
    let current: OpenMeteoCurrentWeather
    let hourly: OpenMeteoHourlyWeather?
    let daily: OpenMeteoDailyWeather?
    let isRealData: Bool = true
    
    // Computed properties for compatibility with existing WeatherCard
    var main: WeatherData.MainWeather {
        return WeatherData.MainWeather(
            temp: current.temperature2m,
            feelsLike: current.apparentTemperature,
            tempMin: daily?.temperature2mMin.first ?? current.temperature2m,
            tempMax: daily?.temperature2mMax.first ?? current.temperature2m,
            pressure: 1013, // Not available in Open-Meteo free tier
            humidity: current.relativeHumidity2m
        )
    }
    
    var weather: [WeatherData.Weather] {
        return [WeatherData.Weather(
            id: current.weatherCode,
            main: OpenMeteoService.weatherDescription(for: current.weatherCode),
            description: OpenMeteoService.weatherDescription(for: current.weatherCode),
            icon: OpenMeteoService.weatherIcon(for: current.weatherCode)
        )]
    }
    
    var wind: WeatherData.Wind {
        return WeatherData.Wind(
            speed: current.windSpeed10m,
            deg: Int(current.windDirection10m)
        )
    }
    
    var snow: WeatherData.Snow? {
        if let hourly = hourly {
            let totalSnowfall = hourly.snowfall.prefix(24).reduce(0, +) // Next 24h
            return totalSnowfall > 0 ? WeatherData.Snow(
                oneHour: hourly.snowfall.first,
                threeHours: Array(hourly.snowfall.prefix(3)).reduce(0, +)
            ) : nil
        }
        return nil
    }
    
    var name: String {
        return "Ski Resort Weather"
    }
    
    init(from response: OpenMeteoResponse, coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self.current = response.current
        self.hourly = response.hourly
        self.daily = response.daily
    }
}


// MARK: - Historical Data Models

struct HistoricalSnowData {
    let coordinate: CLLocationCoordinate2D
    let yearlyData: [YearlySnowData]
    let averageSnowfall: Double
    let averageSnowDays: Int
}

struct YearlySnowData {
    let year: Int
    let totalSnowfall: Double // in cm
    let averageSnowDepth: Double // in cm
    let snowDays: Int // Tage mit Schneefall > 0.1cm
    let peakSnowfall: Double // Höchster Schneefall an einem Tag
    let seasonStart: Date?
    let seasonEnd: Date?
    
    var seasonLength: Int? {
        guard let start = seasonStart, let end = seasonEnd else { return nil }
        return Calendar.current.dateComponents([.day], from: start, to: end).day
    }
    
    var formattedSeason: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"
        
        guard let start = seasonStart, let end = seasonEnd else {
            return "Keine Daten"
        }
        
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

struct OpenMeteoArchiveResponse: Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let daily: OpenMeteoArchiveDaily
}

struct OpenMeteoArchiveDaily: Codable {
    let time: [String]
    let snowfall_sum: [Double?]?
    let temperature_2m_mean: [Double?]?
    
    // Kein CodingKeys nötig - verwende direkte JSON-Keys
}

// MARK: - Error Handling

enum OpenMeteoError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError(String)
    case era5Error(String)
    case noDataAvailable(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ungültige Open-Meteo URL"
        case .invalidResponse:
            return "Ungültige Antwort von Open-Meteo"
        case .decodingError:
            return "Fehler beim Dekodieren der Wetterdaten"
        case .networkError(let message):
            return "Netzwerk-Fehler: \(message)"
        case .era5Error(let message):
            return "ERA5 Fehler: \(message)"
        case .noDataAvailable(let message):
            return "Keine Daten verfügbar: \(message)"
        }
    }
}