import Foundation
import CoreLocation

struct Accommodation: Identifiable, Equatable {
    let id: UUID
    let name: String
    let distanceToLift: Int
    let hasPool: Bool
    let hasJacuzzi: Bool
    let hasSpa: Bool
    let hasSauna: Bool
    let pricePerNight: Double
    let rating: Double
    let imageUrl: String
    let imageUrls: [String] // Mehrere Bilder pro Unterkunft
    let resort: SkiResort
    let isRealData: Bool // Kennzeichnung ob echte oder Beispieldaten
    let email: String?
    let phone: String?
    let website: String?
    let coordinate: CLLocationCoordinate2D? // Echte GPS-Koordinaten von Google Places
    
    init(name: String, distanceToLift: Int, hasPool: Bool, hasJacuzzi: Bool, hasSpa: Bool, hasSauna: Bool = false, pricePerNight: Double, rating: Double, imageUrl: String, imageUrls: [String] = [], resort: SkiResort, isRealData: Bool = true, email: String? = nil, phone: String? = nil, website: String? = nil, coordinate: CLLocationCoordinate2D? = nil) {
        // Generate stable ID based on name and resort
        self.id = UUID(uuidString: Accommodation.generateStableUUID(name: name, resortId: resort.id.uuidString)) ?? UUID()
        self.name = name
        self.distanceToLift = distanceToLift
        self.hasPool = hasPool
        self.hasJacuzzi = hasJacuzzi
        self.hasSpa = hasSpa
        self.hasSauna = hasSauna
        self.pricePerNight = pricePerNight
        self.rating = rating
        self.imageUrl = imageUrl
        self.imageUrls = imageUrls.isEmpty ? [imageUrl] : imageUrls
        self.resort = resort
        self.isRealData = isRealData
        self.email = email
        self.phone = phone
        self.website = website
        self.coordinate = coordinate
    }
    
    // Initializer that preserves existing ID (for updates)
    init(id: UUID, name: String, distanceToLift: Int, hasPool: Bool, hasJacuzzi: Bool, hasSpa: Bool, hasSauna: Bool = false, pricePerNight: Double, rating: Double, imageUrl: String, imageUrls: [String] = [], resort: SkiResort, isRealData: Bool = true, email: String? = nil, phone: String? = nil, website: String? = nil, coordinate: CLLocationCoordinate2D? = nil) {
        self.id = id
        self.name = name
        self.distanceToLift = distanceToLift
        self.hasPool = hasPool
        self.hasJacuzzi = hasJacuzzi
        self.hasSpa = hasSpa
        self.hasSauna = hasSauna
        self.pricePerNight = pricePerNight
        self.rating = rating
        self.imageUrl = imageUrl
        self.imageUrls = imageUrls.isEmpty ? [imageUrl] : imageUrls
        self.resort = resort
        self.isRealData = isRealData
        self.email = email
        self.phone = phone
        self.website = website
        self.coordinate = coordinate
    }
    
    // Generate a stable UUID based on accommodation name and resort ID
    private static func generateStableUUID(name: String, resortId: String) -> String {
        let combined = "\(name)_\(resortId)"
        let hash = combined.hashValue
        
        // Convert hash to a 32-character hex string
        let hashString = String(format: "%08x", abs(hash))
        let paddedHash = hashString.padding(toLength: 32, withPad: "0", startingAt: 0)
        
        // Format as UUID: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
        let formatted = "\(paddedHash.prefix(8))-\(paddedHash.dropFirst(8).prefix(4))-\(paddedHash.dropFirst(12).prefix(4))-\(paddedHash.dropFirst(16).prefix(4))-\(paddedHash.dropFirst(20).prefix(12))"
        return formatted
    }
    
    static func == (lhs: Accommodation, rhs: Accommodation) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.resort == rhs.resort
    }
    
    // MARK: - Contact Information Helpers
    
    /// Prüft ob die Unterkunft mindestens eine Kontaktmöglichkeit hat
    var hasContactInfo: Bool {
        return email != nil || phone != nil || website != nil
    }
    
    
    
    /// Bevorzugte Kontaktmethode basierend auf verfügbaren Informationen
    var preferredContactMethod: ContactMethod? {
        if let email = email, !email.isEmpty {
            return .email(email)
        }
        if let phone = phone, !phone.isEmpty {
            return .phone(phone)
        }
        if let website = website, !website.isEmpty {
            return .website(website)
        }
        return nil
    }
    
    /// Alle verfügbaren Kontaktmethoden
    var availableContactMethods: [ContactMethod] {
        var methods: [ContactMethod] = []
        
        // E-Mail
        if let email = email, !email.isEmpty {
            methods.append(.email(email))
        }
        
        if let phone = phone, !phone.isEmpty {
            methods.append(.phone(phone))
        }
        if let website = website, !website.isEmpty {
            methods.append(.website(website))
        }
        
        return methods
    }
    
    // MARK: - Price Categories
    
    /// Preiskategorie basierend auf Preis pro Nacht
    enum PriceCategory: String, CaseIterable {
        case budget = "$"
        case mid = "$$"
        case luxury = "$$$"
        
        var displayName: String {
            switch self {
            case .budget: return "Budget"
            case .mid: return "Mittel"
            case .luxury: return "Luxus"
            }
        }
        
        var color: String {
            switch self {
            case .budget: return "green"
            case .mid: return "orange"
            case .luxury: return "red"
            }
        }
    }
    
    /// Berechnet die Preiskategorie basierend auf dem Preis pro Nacht
    var priceCategory: PriceCategory {
        switch pricePerNight {
        case 0...150:
            return .budget
        case 151...300:
            return .mid
        default:
            return .luxury
        }
    }
    
    // MARK: - Spa & Wellness Features
    
    /// Prüft ob die Unterkunft über mindestens eine Spa/Wellness-Ausstattung verfügt
    var hasSpaFeatures: Bool {
        return hasPool || hasJacuzzi || hasSpa || hasSauna
    }
    
    /// Prüft ob die Unterkunft den ausgewählten Spa-Filtern entspricht
    func matchesSpaFilters(_ filters: Set<SpaFilterOption>) -> Bool {
        // Wenn keine Filter ausgewählt, alle anzeigen
        if filters.isEmpty {
            return true
        }
        
        // Wenn "Keine Spa-Ausstattung" ausgewählt
        if filters.contains(.noSpaFeatures) {
            return !hasSpaFeatures
        }
        
        // Prüfe ob alle ausgewählten Features vorhanden sind
        for filter in filters {
            switch filter {
            case .pool:
                if !hasPool { return false }
            case .jacuzzi:
                if !hasJacuzzi { return false }
            case .spa:
                if !hasSpa { return false }
            case .sauna:
                if !hasSauna { return false }
            case .noSpaFeatures:
                // Bereits oben behandelt
                break
            }
        }
        
        return true
    }
}

// MARK: - Contact Method Enum

enum ContactMethod: Identifiable {
    case email(String)
    case phone(String)
    case website(String)
    
    var id: String {
        switch self {
        case .email(let email): return "email_\(email)"
        case .phone(let phone): return "phone_\(phone)"
        case .website(let website): return "website_\(website)"
        }
    }
    
    var displayName: String {
        switch self {
        case .email: return "E-Mail"
        case .phone: return "Anrufen"
        case .website: return "Website"
        }
    }
    
    var iconName: String {
        switch self {
        case .email: return "envelope.fill"
        case .phone: return "phone.fill"
        case .website: return "globe"
        }
    }
    
    var value: String {
        switch self {
        case .email(let email): return email
        case .phone(let phone): return phone
        case .website(let website): return website
        }
    }
}