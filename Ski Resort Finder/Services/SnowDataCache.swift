import Foundation
import CoreLocation

/// Persistenter Cache für historische Schneedaten zur Vermeidung redundanter API-Aufrufe
/// und zur Bereitstellung der Daten für das Objektive Bewertungssystem
class SnowDataCache: @unchecked Sendable {

    static let shared = SnowDataCache()
    
    private var cache: [String: HistoricalSnowData] = [:]
    private let weatherService = OpenMeteoService()
    
    // Cache-Konfiguration
    private let cacheValidityHours: Double = 24.0 // Cache ist 24 Stunden gültig
    private let maxCacheEntries = 100 // Maximum 100 Skigebiete im Cache
    
    // File system paths
    private let cacheDirectory: URL
    private let cacheFileName = "snow_data_cache.json"
    
    private init() {
        // Setup cache directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("SnowDataCache")
        
        // Create cache directory if it doesn't exist
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Load existing cache from disk
        loadCacheFromDisk()
        
        print("SnowDataCache initialized with \(cache.count) cached entries")
    }
    
    /// Holt historische Schneedaten für eine Koordinate (mit persistentem Cache)
    func getHistoricalSnowData(for coordinate: CLLocationCoordinate2D) async -> HistoricalSnowData? {
        let key = cacheKey(for: coordinate)
        
        // Prüfe Cache zuerst und ob Daten noch gültig sind
        if let cachedData = cache[key] {
            if isCacheValid(cachedData) {
                print("Using cached snow data for \(coordinate) (age: \(getCacheAge(cachedData))h)")
                return cachedData
            } else {
                print("Cache expired for \(coordinate), removing old data")
                cache.removeValue(forKey: key)
            }
        }
        
        // Lade neue Daten
        do {
            let snowData = try await weatherService.fetchHistoricalSnowData(for: coordinate)
            let cachedSnowData = HistoricalSnowData(
                coordinate: coordinate,
                yearlyData: snowData.yearlyData,
                averageSnowfall: snowData.averageSnowfall,
                averageSnowDays: snowData.averageSnowDays
            )
            
            cache[key] = cachedSnowData
            print("Loaded and cached snow data for \(coordinate)")
            
            // Save cache to disk in background
            Task.detached { [weak self] in
                await self?.saveCacheToDisk()
            }
            
            return cachedSnowData
        } catch {
            print("[ERROR] Failed to load snow data for \(coordinate): \(error)")
            print("KEINE FAKE-DATEN POLICY: Keine Schneedaten ohne gültige API - Hotel-Bewertungen ohne Schnee-Komponente")
            return nil // Kein Fallback auf fake Daten!
        }
    }
    
    /// Preloads snow data for a resort (called from ModernResortInfoCard)
    func preloadSnowData(for coordinate: CLLocationCoordinate2D) {
        Task {
            _ = await getHistoricalSnowData(for: coordinate)
        }
    }
    
    /// Batch-lädt Schneedaten für mehrere Koordinaten (für bessere Performance)
    func preloadSnowData(for coordinates: [CLLocationCoordinate2D]) {
        Task {
            print("Batch preloading snow data for \(coordinates.count) locations")
            
            for (index, coordinate) in coordinates.enumerated() {
                _ = await getHistoricalSnowData(for: coordinate)
                print("Preload progress: \(index + 1)/\(coordinates.count)")
                
                // Small delay between requests to avoid overwhelming the API
                if index < coordinates.count - 1 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                }
            }
            
            print("[OK] Batch preload completed for \(coordinates.count) locations")
        }
    }
    
    /// Prüft ob Daten für eine Koordinate bereits im Cache sind
    func hasCachedData(for coordinate: CLLocationCoordinate2D) -> Bool {
        let key = cacheKey(for: coordinate)
        if let cachedData = cache[key] {
            return isCacheValid(cachedData)
        }
        return false
    }
    
    /// Generiert Cache-Key für Koordinaten (auf 2 Dezimalstellen gerundet)
    private func cacheKey(for coordinate: CLLocationCoordinate2D) -> String {
        let lat = String(format: "%.2f", coordinate.latitude)
        let lon = String(format: "%.2f", coordinate.longitude)
        return "\(lat),\(lon)"
    }
    
    // MARK: - Cache Validation
    
    /// Prüft ob Cache-Eintrag noch gültig ist
    private func isCacheValid(_ data: HistoricalSnowData) -> Bool {
        let cacheAge = Date().timeIntervalSince(data.cacheTimestamp)
        let maxAge = cacheValidityHours * 3600 // Convert hours to seconds
        return cacheAge < maxAge
    }
    
    /// Berechnet das Alter des Cache-Eintrags in Stunden
    private func getCacheAge(_ data: HistoricalSnowData) -> Double {
        let cacheAge = Date().timeIntervalSince(data.cacheTimestamp)
        return cacheAge / 3600 // Convert seconds to hours
    }
    
    // MARK: - Cache Management
    
    /// Löscht veraltete Cache-Einträge
    func clearOldCache() {
        let initialCount = cache.count
        cache = cache.filter { _, data in isCacheValid(data) }
        let clearedCount = initialCount - cache.count
        
        if clearedCount > 0 {
            print("Cleared \(clearedCount) expired cache entries, \(cache.count) entries remaining")
            Task.detached { [weak self] in
                await self?.saveCacheToDisk()
            }
        }
    }
    
    /// Begrenzt die Cache-Größe auf das Maximum
    private func limitCacheSize() {
        if cache.count > maxCacheEntries {
            // Remove oldest entries
            let sortedEntries = cache.sorted { $0.value.cacheTimestamp < $1.value.cacheTimestamp }
            let entriesToRemove = sortedEntries.prefix(cache.count - maxCacheEntries)
            
            for (key, _) in entriesToRemove {
                cache.removeValue(forKey: key)
            }
            
            print("Cache size limited to \(cache.count) entries")
        }
    }
    
    /// Gibt Cache-Statistiken zurück
    func getCacheStats() -> (entries: Int, totalSizeMB: Double, oldestEntry: Date?, newestEntry: Date?) {
        guard !cache.isEmpty else {
            return (0, 0.0, nil, nil)
        }
        
        let timestamps = cache.values.map { $0.cacheTimestamp }
        let oldest = timestamps.min()
        let newest = timestamps.max()
        
        // Rough size estimate
        let avgEntrySize = 5000.0 // ~5KB per entry (estimated)
        let totalSizeMB = Double(cache.count) * avgEntrySize / (1024 * 1024)
        
        return (cache.count, totalSizeMB, oldest, newest)
    }
    
    // MARK: - Persistent Storage
    
    /// Lädt Cache von der Festplatte
    private func loadCacheFromDisk() {
        let cacheFileURL = cacheDirectory.appendingPathComponent(cacheFileName)
        
        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else {
            print("No existing cache file found")
            return
        }
        
        do {
            let data = try Data(contentsOf: cacheFileURL)
            let loadedCache = try JSONDecoder().decode([String: HistoricalSnowData].self, from: data)
            
            // Filter out expired entries while loading
            cache = loadedCache.filter { _, snowData in isCacheValid(snowData) }
            
            let expiredCount = loadedCache.count - cache.count
            print("Loaded \(cache.count) valid cache entries from disk")
            if expiredCount > 0 {
                print("Filtered out \(expiredCount) expired entries")
            }
        } catch {
            print("[ERROR] Failed to load cache from disk: \(error)")
            // Start with empty cache if loading fails
            cache = [:]
        }
    }
    
    /// Speichert Cache auf die Festplatte
    private func saveCacheToDisk() async {
        // Limit cache size before saving
        limitCacheSize()
        
        let cacheFileURL = cacheDirectory.appendingPathComponent(cacheFileName)
        
        do {
            let data = try JSONEncoder().encode(cache)
            try data.write(to: cacheFileURL)
            print("Cache saved to disk with \(cache.count) entries")
        } catch {
            print("[ERROR] Failed to save cache to disk: \(error)")
        }
    }
    
    /// Löscht kompletten Cache (sowohl Memory als auch Disk)
    func clearAllCache() {
        cache.removeAll()
        
        let cacheFileURL = cacheDirectory.appendingPathComponent(cacheFileName)
        try? FileManager.default.removeItem(at: cacheFileURL)
        
        print("All cache data cleared")
    }
}