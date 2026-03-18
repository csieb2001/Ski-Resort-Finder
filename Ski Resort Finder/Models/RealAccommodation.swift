import Foundation
import CoreLocation

struct RealAccommodation: Identifiable, Equatable {
    let id = UUID()
    let hotelId: String
    let name: String
    let description: String?
    let coordinate: CLLocationCoordinate2D?
    let distanceToResort: Double // in meters
    let rating: Double? // Hotel rating (1-5 stars)
    let amenities: [String]
    let pricePerNight: Double
    let currency: String
    let checkInDate: Date
    let checkOutDate: Date
    let imageURLs: [String]
    let address: String?
    let chainCode: String?
    let resort: SkiResort
    let isRealData: Bool = true
    
    // Computed properties for compatibility with existing UI
    var hasPool: Bool {
        amenities.contains { amenity in
            amenity.lowercased().contains("pool") || 
            amenity.lowercased().contains("swimming") ||
            amenity.lowercased().contains("swimmingpool")
        }
    }
    
    var hasJacuzzi: Bool {
        amenities.contains { amenity in
            amenity.lowercased().contains("jacuzzi") || 
            amenity.lowercased().contains("hot tub") ||
            amenity.lowercased().contains("whirlpool")
        }
    }
    
    var hasSpa: Bool {
        amenities.contains { amenity in
            amenity.lowercased().contains("spa") || 
            amenity.lowercased().contains("wellness") ||
            amenity.lowercased().contains("massage")
        }
    }
    
    var distanceToLift: Int {
        return Int(distanceToResort)
    }
    
    var accommodationRating: Double {
        return rating ?? 3.5
    }
    
    static func == (lhs: RealAccommodation, rhs: RealAccommodation) -> Bool {
        return lhs.id == rhs.id &&
               lhs.hotelId == rhs.hotelId &&
               lhs.resort == rhs.resort
    }
    
    /// Generiert eine E-Mail-Adresse aus dem Hotelnamen
    private static func generateEmailFromHotelName(_ hotelName: String) -> String {
        // Hotelname bereinigen und in Domain-Format umwandeln
        var domain = hotelName.lowercased()
        
        // Häufige Hotel-Präfixe entfernen
        let prefixes = ["hotel", "resort", "lodge", "inn", "guesthouse", "pension", "gasthof", "gasthaus"]
        for prefix in prefixes {
            if domain.hasPrefix(prefix + " ") {
                domain = String(domain.dropFirst(prefix.count + 1))
                break
            }
        }
        
        // Sonderzeichen und Leerzeichen entfernen/ersetzen
        domain = domain.replacingOccurrences(of: " ", with: "")
        domain = domain.replacingOccurrences(of: "-", with: "")
        domain = domain.replacingOccurrences(of: "'", with: "")
        domain = domain.replacingOccurrences(of: "&", with: "and")
        domain = domain.replacingOccurrences(of: "ä", with: "ae")
        domain = domain.replacingOccurrences(of: "ö", with: "oe")
        domain = domain.replacingOccurrences(of: "ü", with: "ue")
        domain = domain.replacingOccurrences(of: "ß", with: "ss")
        
        // Nur Buchstaben und Zahlen behalten
        domain = domain.filter { $0.isLetter || $0.isNumber }
        
        // Fallback wenn Domain zu kurz oder leer
        if domain.count < 3 {
            domain = "hotel" + String(hotelName.hashValue).replacingOccurrences(of: "-", with: "")
        }
        
        // Domain auf vernünftige Länge begrenzen
        if domain.count > 20 {
            domain = String(domain.prefix(20))
        }
        
        return "info@\(domain).de"
    }
}

// Extension to convert RealAccommodation to legacy Accommodation for UI compatibility
extension RealAccommodation {
    func toLegacyAccommodation() async -> Accommodation {
        let finalEmail = RealAccommodation.generateEmailFromHotelName(self.name)

        return Accommodation(
            name: self.name,
            distanceToLift: self.distanceToLift,
            hasPool: self.hasPool,
            hasJacuzzi: self.hasJacuzzi,
            hasSpa: self.hasSpa,
            pricePerNight: self.pricePerNight,
            rating: self.accommodationRating,
            imageUrl: self.imageURLs.first ?? "",
            imageUrls: self.imageURLs,
            resort: self.resort,
            isRealData: true,
            email: finalEmail,
            coordinate: self.coordinate
        )
    }
}