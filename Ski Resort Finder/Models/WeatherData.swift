import Foundation
import CoreLocation

struct WeatherData: Codable {
    let main: MainWeather
    let weather: [Weather]
    let wind: Wind?
    let snow: Snow?
    let name: String
    let isRealData: Bool
    var historicalSnowData: HistoricalSnowData?
    
    enum CodingKeys: String, CodingKey {
        case main, weather, wind, snow, name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        main = try container.decode(MainWeather.self, forKey: .main)
        weather = try container.decode([Weather].self, forKey: .weather)
        wind = try container.decodeIfPresent(Wind.self, forKey: .wind)
        snow = try container.decodeIfPresent(Snow.self, forKey: .snow)
        name = try container.decode(String.self, forKey: .name)
        isRealData = true // API-Daten sind immer echte Daten
    }
    
    init(main: MainWeather, weather: [Weather], wind: Wind?, snow: Snow?, name: String, isRealData: Bool, historicalSnowData: HistoricalSnowData? = nil) {
        self.main = main
        self.weather = weather
        self.wind = wind
        self.snow = snow
        self.name = name
        self.isRealData = isRealData
        self.historicalSnowData = historicalSnowData
    }
    
    // Initializer für Open-Meteo Daten
    init(from openMeteoData: OpenMeteoWeatherData) {
        self.main = MainWeather(
            temp: openMeteoData.main.temp,
            feelsLike: openMeteoData.main.feelsLike,
            tempMin: openMeteoData.main.tempMin,
            tempMax: openMeteoData.main.tempMax,
            pressure: openMeteoData.main.pressure,
            humidity: openMeteoData.main.humidity
        )
        
        self.weather = openMeteoData.weather.map { weatherInfo in
            Weather(
                id: weatherInfo.id,
                main: weatherInfo.main,
                description: weatherInfo.description,
                icon: weatherInfo.icon
            )
        }
        
        self.wind = Wind(
            speed: openMeteoData.wind.speed,
            deg: openMeteoData.wind.deg
        )
        
        self.snow = openMeteoData.snow.map { snowData in
            Snow(
                oneHour: snowData.oneHour,
                threeHours: snowData.threeHours
            )
        }
        
        self.name = openMeteoData.name
        self.isRealData = openMeteoData.isRealData
        self.historicalSnowData = nil // Wird separat geladen
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(main, forKey: .main)
        try container.encode(weather, forKey: .weather)
        try container.encodeIfPresent(wind, forKey: .wind)
        try container.encodeIfPresent(snow, forKey: .snow)
        try container.encode(name, forKey: .name)
    }
    
    struct MainWeather: Codable {
        let temp: Double
        let feelsLike: Double
        let tempMin: Double
        let tempMax: Double
        let pressure: Int
        let humidity: Int
        
        enum CodingKeys: String, CodingKey {
            case temp, pressure, humidity
            case feelsLike = "feels_like"
            case tempMin = "temp_min"
            case tempMax = "temp_max"
        }
    }
    
    struct Weather: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
    
    struct Wind: Codable {
        let speed: Double
        let deg: Int?
    }
    
    struct Snow: Codable {
        let oneHour: Double?
        let threeHours: Double?
        
        enum CodingKeys: String, CodingKey {
            case oneHour = "1h"
            case threeHours = "3h"
        }
    }
}

struct SkiResortLocation: Codable {
    let name: String
    let country: String
    let region: String
    let lat: Double
    let lon: Double
    let elevation: Int
    let totalSlopes: Int
    let maxElevation: Int
    let minElevation: Int
}

// MARK: - Historical Snow Data Models
struct HistoricalSnowData: Codable {
    let latitude: Double
    let longitude: Double
    let yearlyData: [YearlySnowData]
    let averageSnowfall: Double
    let averageSnowDays: Int
    let cacheTimestamp: Date // Für Cache-Verwaltung
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(coordinate: CLLocationCoordinate2D, yearlyData: [YearlySnowData], averageSnowfall: Double, averageSnowDays: Int) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.yearlyData = yearlyData
        self.averageSnowfall = averageSnowfall
        self.averageSnowDays = averageSnowDays
        self.cacheTimestamp = Date()
    }
}

struct YearlySnowData: Codable {
    let year: Int
    let totalSnowfall: Double // in cm
    let averageSnowDepth: Double // in cm
    let snowDays: Int // Tage mit Schneefall > 0.1cm
    let peakSnowfall: Double // Höchster Schneefall an einem Tag
    let seasonStart: Date? // Beginn der Schneesaison
    let seasonEnd: Date? // Ende der Schneesaison
    
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