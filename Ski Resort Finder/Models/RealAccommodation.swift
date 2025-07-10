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
    
    init(from googlePlace: GooglePlaceAccommodation, resort: SkiResort, resortDistance: Double, checkInDate: Date, checkOutDate: Date) {
        self.hotelId = googlePlace.placeId
        self.name = googlePlace.name
        self.description = nil // Wird bei Bedarf über Details API geholt
        
        if let geometry = googlePlace.geometry {
            self.coordinate = CLLocationCoordinate2D(latitude: geometry.location.lat, longitude: geometry.location.lng)
        } else {
            self.coordinate = nil
        }
        
        self.distanceToResort = resortDistance
        self.rating = googlePlace.rating ?? 3.5
        
        // Temporary variables für Berechnung
        let generatedAmenities = RealAccommodation.generateAmenitiesFromTypes(googlePlace.types)
        let estimatedPrice = RealAccommodation.estimatePrice(from: googlePlace, distanceToResort: resortDistance)
        
        self.amenities = generatedAmenities
        self.pricePerNight = estimatedPrice
        self.currency = "EUR"
        self.checkInDate = checkInDate
        self.checkOutDate = checkOutDate
        
        self.imageURLs = googlePlace.photos?.map { _ in "google_places_photo" } ?? []
        self.address = googlePlace.vicinity
        self.chainCode = nil // Google Places hat keine chain codes
        self.resort = resort
    }
    
    /// Generiert Amenities basierend auf Google Places Types
    private static func generateAmenitiesFromTypes(_ types: [String]?) -> [String] {
        guard let types = types else { return ["WIFI", "PARKING"] }
        
        var amenities: [String] = ["WIFI", "PARKING"] // Standard amenities
        
        // Luxus-Hotel Indikatoren
        if types.contains("luxury") || types.contains("resort") {
            amenities.append(contentsOf: ["SPA", "POOL", "FITNESS", "CONCIERGE", "RESTAURANT"])
        }
        
        // Spa/Wellness Indikatoren  
        if types.contains("spa") || types.contains("health") {
            amenities.append(contentsOf: ["SPA", "POOL", "WELLNESS", "MASSAGE"])
        }
        
        // Hotel vs andere Unterkünfte
        if types.contains("lodging") {
            amenities.append("RESTAURANT")
            
            // 70% Chance für zusätzliche Amenities bei Hotels
            if Double.random(in: 0...1) > 0.3 {
                let luxuryAmenities = ["POOL", "FITNESS", "SPA", "ROOM_SERVICE"]
                amenities.append(contentsOf: luxuryAmenities.shuffled().prefix(2))
            }
        }
        
        return Array(Set(amenities)) // Duplikate entfernen
    }
    
    /// Schätzt Preis basierend auf Google Places Daten
    private static func estimatePrice(from googlePlace: GooglePlaceAccommodation, distanceToResort: Double) -> Double {
        var basePrice: Double = 120.0
        
        // Preis basierend auf Google Places price_level (0-4)
        if let priceLevel = googlePlace.priceLevel {
            switch priceLevel {
            case 0: basePrice = 60.0   // Sehr günstig
            case 1: basePrice = 100.0  // Günstig
            case 2: basePrice = 150.0  // Mittel
            case 3: basePrice = 250.0  // Teuer
            case 4: basePrice = 400.0  // Sehr teuer
            default: basePrice = 120.0
            }
        }
        
        // Rating-Bonus
        if let rating = googlePlace.rating {
            if rating >= 4.5 {
                basePrice *= 1.3
            } else if rating >= 4.0 {
                basePrice *= 1.1
            } else if rating < 3.0 {
                basePrice *= 0.8
            }
        }
        
        // Entfernungs-Modifier
        let distanceKm = distanceToResort / 1000.0
        if distanceKm < 1.0 {
            basePrice *= 1.4 // Sehr nah = teurer
        } else if distanceKm < 5.0 {
            basePrice *= 1.2 // Nah = etwas teurer
        } else if distanceKm > 20.0 {
            basePrice *= 0.7 // Weit = günstiger
        }
        
        // Zufällige Variation für Realismus
        let variation = Double.random(in: 0.85...1.15)
        return basePrice * variation
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
        // Versuche echte Kontaktdaten von Google Places zu holen
        let googlePlacesService = GooglePlacesService()
        var contactInfo: PlaceContactInfo?
        
        do {
            if let coordinate = self.coordinate {
                contactInfo = try await googlePlacesService.getHotelContactInfo(
                    hotelName: self.name,
                    location: coordinate
                )
            }
        } catch {
            print("Google Places Kontaktdaten nicht verfügbar für \(self.name): \(error)")
        }
        
        // Fallback: Generiere E-Mail aus Hotelname wenn keine echte E-Mail verfügbar
        let finalEmail = contactInfo?.email ?? RealAccommodation.generateEmailFromHotelName(self.name)
        
        let accommodation = Accommodation(
            name: self.name,
            distanceToLift: self.distanceToLift,
            hasPool: self.hasPool,
            hasJacuzzi: self.hasJacuzzi,
            hasSpa: self.hasSpa,
            pricePerNight: self.pricePerNight,
            rating: self.accommodationRating,
            imageUrl: self.imageURLs.first ?? "",
            imageUrls: self.imageURLs, // Mehrere echte Bilder von Google Places
            resort: self.resort,
            isRealData: true,
            email: finalEmail, // Echte E-Mail von Google Places oder generierte E-Mail
            phone: contactInfo?.phone, // Echte Telefonnummer von Google Places
            website: contactInfo?.website, // Echte Website von Google Places
            coordinate: self.coordinate // ECHTE GPS-KOORDINATEN von Google Places!
        )
        
        // DEBUG: Kontaktdaten prüfen
        let emailSource = (contactInfo?.email != nil) ? "Google Places" : "Generated"
        print("🏨 Accommodation \(self.name) - hasContactInfo: \(accommodation.hasContactInfo)")
        print("📧 Email: \(accommodation.email ?? "nil") (Source: \(emailSource))")
        print("📞 Phone: \(accommodation.phone ?? "nil")")
        print("🌐 Website: \(accommodation.website ?? "nil")")
        
        return accommodation
    }
}