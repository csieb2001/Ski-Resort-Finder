import Foundation
import CoreLocation

/// Cache für historische Schneedaten zur Vermeidung redundanter API-Aufrufe
/// und zur Bereitstellung der Daten für das Objektive Bewertungssystem
class SnowDataCache {
    
    static let shared = SnowDataCache()
    private init() {}
    
    private var cache: [String: HistoricalSnowData] = [:]
    private let weatherService = OpenMeteoService()
    
    /// Holt historische Schneedaten für eine Koordinate (mit Cache)
    func getHistoricalSnowData(for coordinate: CLLocationCoordinate2D) async -> HistoricalSnowData? {
        let key = cacheKey(for: coordinate)
        
        // Prüfe Cache zuerst
        if let cachedData = cache[key] {
            print("📦 Using cached snow data for \(coordinate)")
            return cachedData
        }
        
        // Lade neue Daten
        do {
            let snowData = try await weatherService.fetchHistoricalSnowData(for: coordinate)
            cache[key] = snowData
            print("🌨️ Loaded and cached snow data for \(coordinate)")
            return snowData
        } catch {
            print("❌ Failed to load snow data for \(coordinate): \(error)")
            print("📝 KEINE FAKE-DATEN POLICY: Keine Schneedaten ohne gültige API - Hotel-Bewertungen ohne Schnee-Komponente")
            return nil // Kein Fallback auf fake Daten!
        }
    }
    
    /// Preloads snow data for a resort (called from ModernResortInfoCard)
    func preloadSnowData(for coordinate: CLLocationCoordinate2D) {
        Task {
            _ = await getHistoricalSnowData(for: coordinate)
        }
    }
    
    /// Generiert Cache-Key für Koordinaten (auf 2 Dezimalstellen gerundet)
    private func cacheKey(for coordinate: CLLocationCoordinate2D) -> String {
        let lat = String(format: "%.2f", coordinate.latitude)
        let lon = String(format: "%.2f", coordinate.longitude)
        return "\(lat),\(lon)"
    }
    
    /// Löscht veraltete Cache-Einträge (Daten älter als 24 Stunden)
    func clearOldCache() {
        // Für zukünftige Implementierung mit Timestamp
        // Aktuell: Cache bleibt für die Session bestehen
    }
}