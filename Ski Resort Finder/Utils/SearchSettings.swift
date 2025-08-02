import Foundation

/// Sucheinstellungen für Accommodations
class SearchSettings: ObservableObject {
    
    static let shared = SearchSettings()
    
    private init() {
        // Lade gespeicherte Einstellungen
        _searchRadius = Published(initialValue: UserDefaults.standard.double(forKey: searchRadiusKey))
        
        // Setze Default-Wert falls nicht gespeichert
        if searchRadius == 0 {
            searchRadius = 5.0 // 5km default
        }
    }
    
    private let searchRadiusKey = "accommodation_search_radius"
    
    /// Suchradius in Kilometern (1.0 - 20.0)
    @Published var searchRadius: Double {
        didSet {
            // Sichere Grenzen einhalten
            if searchRadius < 1.0 { searchRadius = 1.0 }
            if searchRadius > 20.0 { searchRadius = 20.0 }
            
            // Speichere Einstellung
            UserDefaults.standard.set(searchRadius, forKey: searchRadiusKey)
            print("🔍 Search radius updated to: \(searchRadius)km")
        }
    }
    
    /// Suchradius in Metern (für API-Aufrufe)
    var searchRadiusInMeters: Int {
        return Int(searchRadius * 1000)
    }
    
    /// Verfügbare Radius-Optionen
    static let availableRadii: [Double] = [1.0, 2.0, 3.0, 5.0, 8.0, 10.0, 15.0, 20.0]
    
    /// Lokalisierter Text für aktuellen Radius
    var radiusDisplayText: String {
        if searchRadius == 1.0 {
            return "search_radius_1km".localized
        } else {
            return String(format: "search_radius_km".localized, Int(searchRadius))
        }
    }
    
    /// Beschreibung der Radius-Auswirkung
    var radiusDescriptionText: String {
        switch searchRadius {
        case 1.0...2.0:
            return "radius_description_close".localized
        case 2.1...5.0:
            return "radius_description_moderate".localized  
        case 5.1...10.0:
            return "radius_description_wide".localized
        default:
            return "radius_description_very_wide".localized
        }
    }
}