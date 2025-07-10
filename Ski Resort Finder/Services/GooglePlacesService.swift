import Foundation
import CoreLocation

class GooglePlacesService: ObservableObject {
    // WICHTIG: Für Produktion bitte echten Google API Key verwenden
    // Kostenloses Kontingent: 1000 Requests/Monat für Places API
    // Google Places API Key - MUSS konfiguriert werden für echte Hotelbilder
    // Gehe zu: https://console.cloud.google.com/ → Places API aktivieren → API Key erstellen
    private let apiKey = "AIzaSyD_Ko7HnE76gH6cA7CJNUuKkGJEX55LN7U" // Echter Google Places API Key
    
    private let session = URLSession.shared
    
    // MARK: - Public Methods
    
    /// Sucht nach einem Hotel und gibt die erste Foto-Referenz zurück
    func getHotelPhotoURL(hotelName: String, location: CLLocationCoordinate2D) async throws -> URL? {
        // Schritt 1: Place Search um Place ID zu finden
        guard let placeId = try await searchPlace(query: hotelName, location: location) else {
            print("Kein Place gefunden für: \(hotelName)")
            return nil
        }
        
        // Schritt 2: Place Details um Foto-Referenz zu bekommen
        guard let photoReference = try await getPlacePhotos(placeId: placeId) else {
            print("Keine Fotos gefunden für Place ID: \(placeId)")
            return nil
        }
        
        // Schritt 3: Foto URL generieren
        return buildPhotoURL(photoReference: photoReference)
    }
    
    /// Holt Kontaktdaten für ein Hotel
    func getHotelContactInfo(hotelName: String, location: CLLocationCoordinate2D) async throws -> PlaceContactInfo? {
        // Schritt 1: Place Search um Place ID zu finden
        guard let placeId = try await searchPlace(query: hotelName, location: location) else {
            print("Kein Place gefunden für: \(hotelName)")
            return nil
        }
        
        // Schritt 2: Place Details um Kontaktdaten zu bekommen
        let contactInfo = try await getPlaceContactInfo(placeId: placeId)
        return contactInfo
    }
    
    // MARK: - Private Methods
    
    /// Sucht nach einem Ort und gibt die Place ID zurück
    private func searchPlace(query: String, location: CLLocationCoordinate2D) async throws -> String? {
        guard !apiKey.isEmpty && !apiKey.contains("YOUR_") && !apiKey.contains("DEMO") else {
            throw GooglePlacesError.apiKeyMissing
        }
        
        let radius = 10000 // 10km Radius
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlString = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=\(encodedQuery)&location=\(location.latitude),\(location.longitude)&radius=\(radius)&type=lodging&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw GooglePlacesError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GooglePlacesError.networkError
        }
        
        let searchResponse = try JSONDecoder().decode(PlaceSearchResponse.self, from: data)
        
        guard let firstResult = searchResponse.results.first else {
            throw GooglePlacesError.noResults
        }
        
        return firstResult.place_id
    }
    
    /// Holt Fotos für eine Place ID (nur erstes Foto für Kompatibilität)
    private func getPlacePhotos(placeId: String) async throws -> String? {
        let photos = try await getMultiplePlacePhotos(placeId: placeId, maxPhotos: 1)
        return photos.first
    }
    
    /// Holt mehrere Foto-URLs für eine Place ID
    func getMultiplePlacePhotos(placeId: String, maxPhotos: Int = 5) async throws -> [String] {
        let fields = "photos"
        let urlString = "https://maps.googleapis.com/maps/api/place/details/json?place_id=\(placeId)&fields=\(fields)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw GooglePlacesError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GooglePlacesError.networkError
        }
        
        let detailsResponse = try JSONDecoder().decode(PlaceDetailsResponse.self, from: data)
        
        guard let photos = detailsResponse.result?.photos else {
            return []
        }
        
        // Nehme bis zu maxPhotos Fotos und konvertiere zu URLs
        let photoReferences = Array(photos.prefix(maxPhotos))
        let photoUrls = photoReferences.compactMap { photo in
            buildPhotoURL(photoReference: photo.photo_reference)?.absoluteString
        }
        
        print("📸 Gefunden \(photoUrls.count) Fotos für Place ID: \(placeId)")
        return photoUrls
    }
    
    /// Holt Kontaktdaten für eine Place ID
    private func getPlaceContactInfo(placeId: String) async throws -> PlaceContactInfo {
        let fields = "formatted_phone_number,international_phone_number,website"
        let urlString = "https://maps.googleapis.com/maps/api/place/details/json?place_id=\(placeId)&fields=\(fields)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw GooglePlacesError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GooglePlacesError.networkError
        }
        
        let detailsResponse = try JSONDecoder().decode(PlaceDetailsResponse.self, from: data)
        
        let contactInfo = PlaceContactInfo(
            phone: detailsResponse.result?.formatted_phone_number ?? detailsResponse.result?.international_phone_number,
            website: detailsResponse.result?.website,
            email: nil // Google Places API hat keine E-Mail-Daten
        )
        
        print("📞 Kontaktdaten gefunden: phone=\(contactInfo.phone ?? "nil"), website=\(contactInfo.website ?? "nil"), email=\(contactInfo.email ?? "nil")")
        
        return contactInfo
    }
    
    /// Baut die finale Foto-URL
    private func buildPhotoURL(photoReference: String, maxWidth: Int = 400) -> URL? {
        let urlString = "https://maps.googleapis.com/maps/api/place/photo?photo_reference=\(photoReference)&maxwidth=\(maxWidth)&key=\(apiKey)"
        return URL(string: urlString)
    }
    
    // MARK: - Nearby Search for Accommodations
    
    /// Sucht nach Unterkünften in der Nähe eines Skigebiets
    func searchNearbyAccommodations(near coordinate: CLLocationCoordinate2D, radius: Int = 50000) async throws -> [GooglePlaceAccommodation] {
        guard !apiKey.isEmpty && !apiKey.contains("YOUR_") && !apiKey.contains("DEMO") else {
            throw GooglePlacesError.apiKeyMissing
        }
        
        var allAccommodations: [GooglePlaceAccommodation] = []
        var nextPageToken: String? = nil
        
        repeat {
            let accommodations = try await performNearbySearch(
                coordinate: coordinate,
                radius: radius,
                pageToken: nextPageToken
            )
            
            allAccommodations.append(contentsOf: accommodations.results)
            nextPageToken = accommodations.nextPageToken
            
            // Kurze Pause zwischen Requests (Google Places Anforderung)
            if nextPageToken != nil {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 Sekunden
            }
            
        } while nextPageToken != nil && allAccommodations.count < 60
        
        return allAccommodations
    }
    
    /// Führt eine einzelne Nearby Search durch
    private func performNearbySearch(coordinate: CLLocationCoordinate2D, radius: Int, pageToken: String?) async throws -> NearbySearchResponse {
        
        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json")!
        
        var queryItems = [
            URLQueryItem(name: "location", value: "\(coordinate.latitude),\(coordinate.longitude)"),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "type", value: "lodging"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        if let pageToken = pageToken {
            queryItems.append(URLQueryItem(name: "pagetoken", value: pageToken))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw GooglePlacesError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GooglePlacesError.networkError
        }
        
        let searchResponse = try JSONDecoder().decode(RawNearbySearchResponse.self, from: data)
        
        // Konvertiere zu unserem GooglePlaceAccommodation Format
        let accommodations = searchResponse.results.map { result in
            GooglePlaceAccommodation(
                placeId: result.place_id,
                name: result.name,
                rating: result.rating,
                userRatingsTotal: result.user_ratings_total,
                vicinity: result.vicinity,
                priceLevel: result.price_level,
                photos: result.photos,
                geometry: result.geometry,
                types: result.types,
                businessStatus: result.business_status
            )
        }
        
        return NearbySearchResponse(
            results: accommodations,
            status: searchResponse.status,
            nextPageToken: searchResponse.next_page_token
        )
    }
    
    /// Holt erweiterte Details für eine Unterkunft
    func getAccommodationDetails(placeId: String) async throws -> GooglePlaceDetails? {
        let fields = "name,rating,user_ratings_total,formatted_phone_number,international_phone_number,website,photos,formatted_address,price_level,opening_hours,reviews"
        let urlString = "https://maps.googleapis.com/maps/api/place/details/json?place_id=\(placeId)&fields=\(fields)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw GooglePlacesError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GooglePlacesError.networkError
        }
        
        let detailsResponse = try JSONDecoder().decode(GooglePlaceDetailsResponse.self, from: data)
        return detailsResponse.result
    }
}

// MARK: - Data Models

struct PlaceSearchResponse: Codable {
    let results: [PlaceResult]
    let status: String
}

struct PlaceResult: Codable {
    let place_id: String
    let name: String
    let formatted_address: String?
    let rating: Double?
    let geometry: PlaceGeometry?
}

struct PlaceGeometry: Codable {
    let location: PlaceLocation
}

struct PlaceLocation: Codable {
    let lat: Double
    let lng: Double
}

struct PlaceDetailsResponse: Codable {
    let result: PlaceDetails?
    let status: String
}

struct PlaceDetails: Codable {
    let photos: [PlacePhoto]?
    let formatted_phone_number: String?
    let international_phone_number: String?
    let website: String?
}

struct PlacePhoto: Codable {
    let photo_reference: String
    let height: Int
    let width: Int
}

// MARK: - Error Types

enum GooglePlacesError: Error, LocalizedError {
    case invalidURL
    case networkError
    case noResults
    case apiKeyMissing
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ungültige URL"
        case .networkError:
            return "Netzwerk-Fehler"
        case .noResults:
            return "Keine Ergebnisse gefunden"
        case .apiKeyMissing:
            return "Google API Key fehlt"
        }
    }
}

// MARK: - Contact Info Model

struct PlaceContactInfo: Codable {
    let phone: String?
    let website: String?
    let email: String?
    
    var hasContactInfo: Bool {
        return phone != nil || website != nil || email != nil
    }
}

// MARK: - New Data Models for Nearby Search

struct NearbySearchResponse: Codable {
    let results: [GooglePlaceAccommodation]
    let status: String
    let nextPageToken: String?
    
    enum CodingKeys: String, CodingKey {
        case results, status
        case nextPageToken = "next_page_token"
    }
}

struct RawNearbySearchResponse: Codable {
    let results: [RawGooglePlaceResult]
    let status: String
    let next_page_token: String?
}

struct RawGooglePlaceResult: Codable {
    let place_id: String
    let name: String
    let rating: Double?
    let user_ratings_total: Int?
    let vicinity: String?
    let price_level: Int?
    let photos: [PlacePhoto]?
    let geometry: PlaceGeometry?
    let types: [String]?
    let business_status: String?
}

struct GooglePlaceAccommodation: Codable, Identifiable {
    let placeId: String
    let name: String
    let rating: Double?
    let userRatingsTotal: Int?
    let vicinity: String?
    let priceLevel: Int?
    let photos: [PlacePhoto]?
    let geometry: PlaceGeometry?
    let types: [String]?
    let businessStatus: String?
    
    var id: String { placeId }
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name, rating, vicinity, photos, geometry, types
        case userRatingsTotal = "user_ratings_total"
        case priceLevel = "price_level"
        case businessStatus = "business_status"
    }
}

struct GooglePlaceDetailsResponse: Codable {
    let result: GooglePlaceDetails?
    let status: String
}

struct GooglePlaceDetails: Codable {
    let name: String?
    let rating: Double?
    let userRatingsTotal: Int?
    let formattedPhoneNumber: String?
    let internationalPhoneNumber: String?
    let website: String?
    let photos: [PlacePhoto]?
    let formattedAddress: String?
    let priceLevel: Int?
    let openingHours: OpeningHours?
    let reviews: [PlaceReview]?
    
    enum CodingKeys: String, CodingKey {
        case name, rating, website, photos
        case userRatingsTotal = "user_ratings_total"
        case formattedPhoneNumber = "formatted_phone_number"
        case internationalPhoneNumber = "international_phone_number"
        case formattedAddress = "formatted_address"
        case priceLevel = "price_level"
        case openingHours = "opening_hours"
        case reviews
    }
}

struct OpeningHours: Codable {
    let openNow: Bool?
    let weekdayText: [String]?
    
    enum CodingKeys: String, CodingKey {
        case openNow = "open_now"
        case weekdayText = "weekday_text"
    }
}

struct PlaceReview: Codable {
    let authorName: String?
    let rating: Int?
    let text: String?
    let time: Int?
    
    enum CodingKeys: String, CodingKey {
        case authorName = "author_name"
        case rating, text, time
    }
}

// MARK: - Enhanced Image Service Integration

extension UnsplashImageService {
    
    /// Lädt echtes Google Places Foto oder fällt auf Picsum zurück
    static func getHotelImageURLWithGoogle(
        for accommodationName: String, 
        location: CLLocationCoordinate2D,
        width: Int = 400, 
        height: Int = 300
    ) async -> URL? {
        
        let googleService = GooglePlacesService()
        
        // Versuche zuerst Google Places
        do {
            if let googleURL = try await googleService.getHotelPhotoURL(
                hotelName: accommodationName, 
                location: location
            ) {
                print("✅ Google Places Foto gefunden für: \(accommodationName)")
                return googleURL
            }
        } catch {
            print("⚠️ Google Places Fehler für \(accommodationName): \(error.localizedDescription)")
        }
        
        // Keine Fallbacks mehr - nur echte Google Places Fotos
        print("❌ Kein echtes Foto verfügbar für: \(accommodationName)")
        return nil
    }
}