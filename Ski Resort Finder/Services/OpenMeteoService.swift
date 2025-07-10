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
        // Temporarily create instance of ERA5 service for testing
        let era5Service = ERA5SnowService()
        
        do {
            // Use ERA5 data if available
            return try await era5Service.fetchHistoricalSnowData(for: coordinate)
        } catch let error as ERA5Error {
            // Spezifische ERA5 Fehler weiterleiten
            throw OpenMeteoError.era5Error(error.localizedDescription)
        } catch {
            // Andere Fehler als Netzwerk-Fehler behandeln
            throw OpenMeteoError.networkError("ERA5 Daten konnten nicht geladen werden: \(error.localizedDescription)")
        }
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
    let snowfallSum: [Double]
    let snowDepthMean: [Double?]
    let temperature2mMean: [Double]
    
    enum CodingKeys: String, CodingKey {
        case time
        case snowfallSum = "snowfall_sum"
        case snowDepthMean = "snow_depth_mean"
        case temperature2mMean = "temperature_2m_mean"
    }
}

// MARK: - Error Handling

enum OpenMeteoError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError(String)
    case era5Error(String)
    
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
        }
    }
}