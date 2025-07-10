import Foundation
import CoreLocation
import Combine

class APIService: ObservableObject {
    
    // MARK: - Weather API
    func fetchWeather(for coordinate: CLLocationCoordinate2D) async throws -> WeatherData {
        let apiKey = "demo_key" // Replace with actual OpenWeatherMap API key
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        do {
            let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
            return weatherData
        } catch {
            throw APIError.decodingError
        }
    }
    
    // MARK: - Overpass API (OpenStreetMap)
    func fetchNearbyAccommodations(around coordinate: CLLocationCoordinate2D, radius: Int = 10000) async throws -> [OverpassElement] {
        let query = """
        [out:json][timeout:25];
        (
          nwr["tourism"~"hotel|guest_house|hostel|apartment"](around:\(radius),\(coordinate.latitude),\(coordinate.longitude));
        );
        out geom;
        """
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://overpass-api.de/api/interpreter?data=\(encodedQuery)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        do {
            let overpassResponse = try JSONDecoder().decode(OverpassResponse.self, from: data)
            return overpassResponse.elements.filter { $0.isAccommodation && $0.lat != nil && $0.lon != nil }
        } catch {
            throw APIError.decodingError
        }
    }
    
    // MARK: - Ski Resorts from OpenStreetMap
    func fetchSkiResorts(in region: String? = nil) async throws -> [OverpassElement] {
        let query = """
        [out:json][timeout:25];
        (
          nwr["leisure"="ski_resort"];
          nwr["piste:type"];
        );
        out geom;
        """
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://overpass-api.de/api/interpreter?data=\(encodedQuery)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        do {
            let overpassResponse = try JSONDecoder().decode(OverpassResponse.self, from: data)
            return overpassResponse.elements.filter { $0.isSkiResort && $0.lat != nil && $0.lon != nil }
        } catch {
            throw APIError.decodingError
        }
    }
    
    // MARK: - Distance calculation
    func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let location2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return location1.distance(from: location2)
    }
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError(String)
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}