import Foundation
import CoreLocation
import SwiftUI

@MainActor class AccommodationDatabase: ObservableObject {
    static let shared = AccommodationDatabase()

    @Published var accommodations: [String: [CachedAccommodation]] = [:] // Key: resort.id
    @Published var lastUpdateDates: [String: Date] = [:]
    @Published var loadingStatus: AccommodationLoadingStatus = .idle
    @Published var statistics: AccommodationStatistics = AccommodationStatistics()
    
    private let overpassService = OverpassService.shared
    private let screenshotService = WebsiteScreenshotService.shared
    // Using SimpleEmailService for basic email functionality
    private let updateInterval: TimeInterval = 30 * 24 * 60 * 60 // 30 days (1 month)
    private let userDefaults = UserDefaults.standard
    private let accommodationsKey = "cached_accommodations"
    private let lastUpdateKey = "accommodations_last_update"
    
    // Cancellation support
    private var loadingTask: Task<Void, Never>?
    private var isCancelled: Bool = false
    
    private init() {
        loadFromDisk()
        
        // Stelle sicher, dass totalResorts immer korrekt gesetzt ist
        if statistics.totalResorts == 0 {
            statistics.totalResorts = SkiResortDatabase.shared.allSkiResorts.count
        }
        
        // Bereinige eventuelle Duplikate aus früheren Versionen
        removeDuplicatesFromExistingData()
        
        // Bereinige Duplikate zwischen verschiedenen Resort-IDs (nach UUID-Fix)
        consolidateDuplicateResorts()
        
        startBackgroundUpdates()
    }
    
    // MARK: - Public Methods
    
    /// Gibt alle Unterkünfte für ein bestimmtes Skigebiet zurück
    func getAccommodations(for resort: SkiResort) -> [CachedAccommodation] {
        return accommodations[resort.id.uuidString] ?? []
    }
    
    /// Lädt alle Unterkünfte für alle Skigebiete im Hintergrund
    func loadAllAccommodations() {
        // Stoppe vorherigen Task falls vorhanden
        loadingTask?.cancel()
        isCancelled = false
        
        loadingTask = Task {
            await loadAccommodationsForAllResorts()
        }
    }
    
    /// Lädt Unterkünfte für ein spezifisches Skigebiet
    func loadAccommodationsForSingleResort(_ resort: SkiResort, progressCallback: (([CachedAccommodation]) -> Void)? = nil, completion: (() -> Void)? = nil) {
        // Stoppe vorherigen Task falls vorhanden
        loadingTask?.cancel()
        isCancelled = false
        
        loadingTask = Task {
            await loadSingleResortAccommodations(resort, progressCallback: progressCallback)
            
            // Notify completion on main thread
            await MainActor.run {
                completion?()
            }
        }
    }
    
    /// Lädt Unterkünfte für eine Liste von ausgewählten Skigebieten
    func loadAccommodationsForSelectedResorts(_ resorts: [SkiResort]) {
        // Stoppe vorherigen Task falls vorhanden
        loadingTask?.cancel()
        isCancelled = false
        
        loadingTask = Task {
            await loadSelectedResortsAccommodations(resorts)
        }
    }
    
    /// Stoppt den aktuellen Ladevorgang
    func stopLoading() {
        isCancelled = true
        loadingTask?.cancel()
        loadingTask = nil
        
        Task { @MainActor in
            loadingStatus = .idle
            statistics.currentResort = ""
            print("User stopped accommodation loading")
        }
    }
    
    /// Erzwingt eine Aktualisierung für ein bestimmtes Skigebiet
    func forceUpdate(for resort: SkiResort) {
        Task {
            await loadAccommodationsForResort(resort, forceUpdate: true)
        }
    }
    
    /// Löscht alle Daten aus der Datenbank
    func clearAllData() {
        // Stoppe laufende Tasks
        stopLoading()
        
        // Lösche alle Daten
        accommodations.removeAll()
        lastUpdateDates.removeAll()
        statistics = AccommodationStatistics()
        statistics.totalResorts = SkiResortDatabase.shared.allSkiResorts.count
        
        // Lösche persistent gespeicherte Daten
        userDefaults.removeObject(forKey: accommodationsKey)
        userDefaults.removeObject(forKey: lastUpdateKey)
        
        print("AccommodationDatabase: All data cleared")
    }
    
    /// Prüft ob eine Aktualisierung für ein Skigebiet benötigt wird
    func needsUpdate(for resort: SkiResort) -> Bool {
        guard let lastUpdate = lastUpdateDates[resort.id.uuidString] else { return true }
        return Date().timeIntervalSince(lastUpdate) > updateInterval
    }
    
    // MARK: - Email Discovery
    
    /// Startet E-Mail-Entdeckung für eine Liste von Unterkünften mit Progress-Anzeige
    private func startEmailDiscoveryForAccommodations(_ cachedAccommodations: [CachedAccommodation]) async {
        print("Starting email discovery for \(cachedAccommodations.count) accommodations...")
        
        // Filtere Unterkünfte, die keine E-Mail haben und konvertiere zu Accommodation-Objekten
        var accommodationsNeedingEmails: [Accommodation] = []
        var accommodationMapping: [String: CachedAccommodation] = [:]
        
        for cachedAccommodation in cachedAccommodations {
            // Prüfe auf Cancellation
            if isCancelled {
                print("Email discovery cancelled")
                return
            }
            
            // Finde das SkiResort für diese CachedAccommodation
            guard let resort = SkiResortDatabase.shared.allSkiResorts.first(where: { $0.id == cachedAccommodation.resortId }) else {
                print("[ERROR] Could not find resort for accommodation \(cachedAccommodation.name)")
                continue
            }
            
            // Konvertiere zu Accommodation für E-Mail-Suche
            let regularAccommodation = await cachedAccommodation.toAccommodation(resort: resort)
            
            // Überspringe, wenn bereits eine E-Mail verfügbar ist
            if let existingEmail = regularAccommodation.email, !existingEmail.isEmpty {
                print("[OK] Email already available for \(cachedAccommodation.name): \(existingEmail)")
                continue
            }
            
            accommodationsNeedingEmails.append(regularAccommodation)
            accommodationMapping[regularAccommodation.name] = cachedAccommodation
        }
        
        // Wenn keine E-Mails benötigt werden, beende
        guard !accommodationsNeedingEmails.isEmpty else {
            print("[OK] All accommodations already have emails")
            return
        }
        
        // Starte Batch-E-Mail-Suche mit Progress-Anzeige über AdvancedEmailService
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.processEmailResults(
                accommodationsNeedingEmails: accommodationsNeedingEmails,
                accommodationMapping: accommodationMapping,
                completion: {
                    continuation.resume()
                }
            )
        }
        
        print("Email discovery completed for \(cachedAccommodations.count) accommodations")
    }
    
    /// Helper method to process email results and avoid complex closure structures
    private func processEmailResults(
        accommodationsNeedingEmails: [Accommodation],
        accommodationMapping: [String: CachedAccommodation],
        completion: @escaping () -> Void
    ) {
        Task { @MainActor in
            AdvancedEmailService.shared.processEmails(for: accommodationsNeedingEmails) { emailResults in
            print("Batch email processing completed with \(emailResults.count) results")
                
                Task { @MainActor in
                    self.updateCachedAccommodationsWithEmails(emailResults, accommodationMapping)
                    completion()
                }
            }
        }
    }
    
    /// Updates cached accommodations with email results
    @MainActor
    private func updateCachedAccommodationsWithEmails(
        _ emailResults: [String: EmailResult],
        _ accommodationMapping: [String: CachedAccommodation]
    ) {
        for (accommodationName, emailResult) in emailResults {
            if let cachedAccommodation = accommodationMapping[accommodationName] {
                let email = emailResult.email
                
                // Aktualisiere die CachedAccommodation mit der gefundenen E-Mail
                if var updatedAccommodations = self.accommodations[cachedAccommodation.resortId.uuidString] {
                    if let index = updatedAccommodations.firstIndex(where: { $0.id == cachedAccommodation.id }) {
                        let updatedAccommodation = updatedAccommodations[index].withScrapedEmail(email)
                        updatedAccommodations[index] = updatedAccommodation
                        self.accommodations[cachedAccommodation.resortId.uuidString] = updatedAccommodations
                        
                        print("[OK] Updated \(accommodationName) with email: \(email) (quality: \(emailResult.quality.description))")
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Erstellt CachedAccommodation aus OSM-Daten
    private func createCachedAccommodationFromOSM(
        osmPlace: OverpassAccommodation,
        resort: SkiResort,
        distance: Double
    ) async -> CachedAccommodation {
        let priceCategory = osmPlace.determinePriceCategory()
        let estimatedPrice = estimatePrice(from: priceCategory)
        // Rating will be calculated objectively in toAccommodation() method
        
        // No automatic image generation - will generate screenshot on-demand when user clicks
        let imageUrl = ""
        let imageUrls: [String] = []
        
        print("[OK] Accommodation \(osmPlace.name) added (screenshot will be generated on-demand)")
        
        return CachedAccommodation(
            placeId: osmPlace.id,
            name: osmPlace.name,
            coordinate: osmPlace.coordinate,
            distanceToLift: Int(distance),
            hasPool: osmPlace.hasPool,
            hasJacuzzi: osmPlace.hasJacuzzi,
            hasSpa: osmPlace.hasSpa,
            hasSauna: osmPlace.hasSauna,
            pricePerNight: estimatedPrice,
            rating: 0.0, // Will be calculated objectively later
            imageUrl: imageUrl, // Website screenshot or placeholder
            imageUrls: imageUrls, // Website screenshot or placeholder
            resortId: resort.id,
            isRealData: true,
            email: osmPlace.email,
            scrapedEmail: nil, // Will be populated later by email service
            phone: osmPlace.phone,
            website: osmPlace.website,
            lastUpdated: Date()
        )
    }
    
    /// Schätzt Preis basierend auf Preiskategorie
    private func estimatePrice(from category: Accommodation.PriceCategory) -> Double {
        switch category {
        case .budget:
            return Double.random(in: 60...120)
        case .mid:
            return Double.random(in: 120...200)
        case .luxury:
            return Double.random(in: 200...400)
        }
    }
    
    /// Schätzt Rating basierend auf OSM-Daten
    // REMOVED: estimateRating() - violates NO FAKE DATA policy
    // Rating is now calculated objectively by ObjectiveRatingCalculator
    
    /// Stellt sicher, dass alle gespeicherten Accommodations für ein Resort geladen sind
    private func ensureAccommodationsLoaded(for resortId: String) async {
        // Wenn bereits Accommodations für dieses Resort im Speicher sind, nichts tun
        if let existingAccommodations = accommodations[resortId], !existingAccommodations.isEmpty {
            print("Resort \(resortId) already has \(existingAccommodations.count) accommodations loaded")
            return
        }
        
        // Wenn die Datenbank noch nicht vom Disk geladen wurde, lade sie jetzt
        if accommodations.isEmpty {
            print("Loading accommodations from disk for duplicate check...")
            loadFromDisk()
        }
        
        print("Ensured accommodations loaded: \(accommodations[resortId]?.count ?? 0) existing accommodations for resort \(resortId)")
    }
    
    /// Prüft ob eine Unterkunft mit der gleichen PlaceID bereits existiert
    private func accommodationExists(_ placeId: String, in existingAccommodations: [CachedAccommodation]) -> Bool {
        return existingAccommodations.contains { $0.placeId == placeId }
    }
    
    /// Entfernt Duplikate basierend auf PlaceID und behält neueste Daten
    private func mergeDuplicates(_ newAccommodations: [CachedAccommodation], with existing: [CachedAccommodation]) -> [CachedAccommodation] {
        var result = existing
        
        for newAccommodation in newAccommodations {
            if let existingIndex = result.firstIndex(where: { $0.placeId == newAccommodation.placeId }) {
                // Ersetze mit neueren Daten
                result[existingIndex] = newAccommodation
                print("Updated existing accommodation: \(newAccommodation.name)")
            } else {
                // Füge neue Unterkunft hinzu
                result.append(newAccommodation)
                print("Added new accommodation: \(newAccommodation.name)")
            }
        }
        
        return result
    }
    
    /// Bereinigt Duplikate in bereits gespeicherten Daten basierend auf PlaceID
    func removeDuplicatesFromExistingData() {
        var hasChanges = false
        
        for (resortKey, accommodationList) in accommodations {
            var uniqueAccommodations: [CachedAccommodation] = []
            var seenPlaceIds: Set<String> = []
            
            for accommodation in accommodationList {
                if !seenPlaceIds.contains(accommodation.placeId) {
                    uniqueAccommodations.append(accommodation)
                    seenPlaceIds.insert(accommodation.placeId)
                } else {
                    print("Removed duplicate: \(accommodation.name) (PlaceID: \(accommodation.placeId))")
                    hasChanges = true
                }
            }
            
            if uniqueAccommodations.count != accommodationList.count {
                accommodations[resortKey] = uniqueAccommodations
                print("[OK] Cleaned \(accommodationList.count - uniqueAccommodations.count) duplicates from resort \(resortKey)")
            }
        }
        
        if hasChanges {
            calculateStatistics()
            saveToDisk()
            print("Saved cleaned database without duplicates")
        }
    }
    
    /// Lädt Unterkünfte für alle Skigebiete
    private func loadAccommodationsForAllResorts() async {
        let allResorts = SkiResortDatabase.shared.allSkiResorts
        
        await MainActor.run {
            loadingStatus = .loading
            // Nicht statistics zurücksetzen - nur aktuelle Werte beibehalten
            statistics.totalResorts = allResorts.count // Setze Gesamtzahl sofort!
        }
        
        for (index, resort) in allResorts.enumerated() {
            // Prüfe auf Cancellation
            if isCancelled {
                await MainActor.run {
                    loadingStatus = .idle
                    statistics.currentResort = ""
                }
                print("Loading cancelled by user at resort \(resort.name)")
                return
            }
            
            await MainActor.run {
                loadingStatus = .loading
                statistics.currentResort = resort.name
                statistics.processedResorts = index
                // statistics.totalResorts bereits gesetzt
            }
            
            // Lade nur wenn notwendig (nicht bei jedem App-Start)
            if needsUpdate(for: resort) {
                await loadAccommodationsForResort(resort)
                
                // Kurze Pause zwischen API-Calls um Rate Limits zu vermeiden
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 Sekunde
                
                // Prüfe nochmals auf Cancellation nach dem Sleep
                if isCancelled {
                    await MainActor.run {
                        loadingStatus = .idle
                        statistics.currentResort = ""
                    }
                    print("Loading cancelled by user after \(resort.name)")
                    return
                }
            }
        }
        
        await MainActor.run {
            loadingStatus = .completed
            calculateStatistics()
            saveToDisk()
        }
        
        print("[OK] AccommodationDatabase: Completed loading accommodations for \(allResorts.count) resorts")
    }
    
    /// Lädt Unterkünfte für ein einzelnes Skigebiet
    private func loadSingleResortAccommodations(_ resort: SkiResort, progressCallback: (([CachedAccommodation]) -> Void)? = nil) async {
        await MainActor.run {
            loadingStatus = .loading
            statistics.currentResort = resort.name
            statistics.processedResorts = 0
            statistics.totalResorts = 1
        }
        
        // Prüfe auf Cancellation
        if isCancelled {
            await MainActor.run {
                loadingStatus = .idle
                statistics.currentResort = ""
            }
            print("Loading cancelled by user")
            return
        }
        
        await loadAccommodationsForResort(resort, forceUpdate: false, progressCallback: progressCallback)
        
        await MainActor.run {
            statistics.processedResorts = 1
            loadingStatus = .completed
            calculateStatistics()
            saveToDisk()
        }
        
        print("[OK] AccommodationDatabase: Completed loading accommodations for \(resort.name)")
    }
    
    /// Lädt Unterkünfte für eine Liste von ausgewählten Skigebieten
    private func loadSelectedResortsAccommodations(_ resorts: [SkiResort]) async {
        await MainActor.run {
            loadingStatus = .loading
            // Nicht statistics zurücksetzen - nur totalResorts für den aktuellen Ladevorgang setzen
            statistics.totalResorts = resorts.count
        }
        
        for (index, resort) in resorts.enumerated() {
            // Prüfe auf Cancellation
            if isCancelled {
                await MainActor.run {
                    loadingStatus = .idle
                    statistics.currentResort = ""
                }
                print("Loading cancelled by user at resort \(resort.name)")
                return
            }
            
            await MainActor.run {
                loadingStatus = .loading
                statistics.currentResort = resort.name
                statistics.processedResorts = index
            }
            
            await loadAccommodationsForResort(resort, forceUpdate: false)
            
            // Kurze Pause zwischen API-Calls um Rate Limits zu vermeiden
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 Sekunde
            
            // Prüfe nochmals auf Cancellation nach dem Sleep
            if isCancelled {
                await MainActor.run {
                    loadingStatus = .idle
                    statistics.currentResort = ""
                }
                print("Loading cancelled by user after \(resort.name)")
                return
            }
        }
        
        await MainActor.run {
            statistics.processedResorts = resorts.count
            loadingStatus = .completed
            calculateStatistics()
            saveToDisk()
        }
        
        print("[OK] AccommodationDatabase: Completed loading accommodations for \(resorts.count) selected resorts")
    }
    
    /// Lädt Unterkünfte für ein bestimmtes Skigebiet
    private func loadAccommodationsForResort(_ resort: SkiResort, forceUpdate: Bool = false, progressCallback: (([CachedAccommodation]) -> Void)? = nil) async {
        let resortKey = resort.id.uuidString
        
        // Prüfe ob bereits Daten vorhanden sind und nicht zu alt
        if !forceUpdate {
            let existingAccommodations = accommodations[resortKey] ?? []
            let hasRecentData = !needsUpdate(for: resort)
            let lastUpdate = lastUpdateDates[resortKey]
            
            print("Checking \(resort.name): \(existingAccommodations.count) existing, hasRecentData: \(hasRecentData), lastUpdate: \(lastUpdate?.description ?? "nil")")
            
            if !existingAccommodations.isEmpty && hasRecentData {
                print("[OK] Using existing accommodations for \(resort.name) (\(existingAccommodations.count) items)")
                return
            } else if !existingAccommodations.isEmpty {
                print("Data exists but outdated for \(resort.name), reloading...")
            } else {
                print("🆕 No existing data for \(resort.name), loading for first time...")
            }
        } else {
            print("Force update requested for \(resort.name)")
        }
        
        print("Loading accommodations for \(resort.name)...")
        
        do {
            var cachedAccommodations: [CachedAccommodation] = []
            
            // Spezialfall: Test-Skigebiet - füge Test-Hotel hinzu
            if resort.name == "Test Skigebiet" {
                let existingAccommodations = accommodations[resort.id.uuidString] ?? []
                let testHotelPlaceId = "test_hotel_001"
                
                if !accommodationExists(testHotelPlaceId, in: existingAccommodations) {
                    let testHotel = createTestHotel(for: resort)
                    cachedAccommodations.append(testHotel)
                    print("Added test hotel for Test Skigebiet")
                    
                    // Progress callback für Test-Unterkünfte
                    await MainActor.run {
                        progressCallback?(cachedAccommodations)
                    }
                } else {
                    print("Test hotel already exists for Test Skigebiet")
                }
            } else {
                // Lade Unterkünfte von OpenStreetMap für echte Skigebiete
                let searchRadius = SearchSettings.shared.searchRadiusInMeters
                print("Searching OpenStreetMap around \(resort.name) at coordinate \(resort.coordinate.latitude), \(resort.coordinate.longitude) with \(SearchSettings.shared.searchRadius)km radius...")
                let osmAccommodations = try await overpassService.searchAccommodations(
                    around: resort.coordinate,
                    radius: searchRadius
                )
                print("OpenStreetMap returned \(osmAccommodations.count) accommodations for \(resort.name)")
            
                // Hole bereits existierende Unterkünfte für dieses Resort (auch von Disk)
                await ensureAccommodationsLoaded(for: resort.id.uuidString)
                let existingAccommodations = accommodations[resort.id.uuidString] ?? []
                
                // UI Update: Zeige Anzahl gefundener Unterkünfte
                await MainActor.run {
                    statistics.currentResort = "\(resort.name) - \(osmAccommodations.count) Unterkünfte von OpenStreetMap geladen"
                }
                
                for (index, osmPlace) in osmAccommodations.enumerated() {
                    // UI Update: Zeige Fortschritt der Verarbeitung
                    await MainActor.run {
                        statistics.currentResort = "\(resort.name) - Verarbeite \(osmPlace.name) (\(index + 1)/\(osmAccommodations.count))"
                    }
                    
                    // WICHTIG: Prüfe zuerst ob diese PlaceID bereits existiert
                    if accommodationExists(osmPlace.id, in: existingAccommodations) {
                        print("Skipping existing accommodation: \(osmPlace.name) (ID: \(osmPlace.id)) - already in database")
                        continue
                    } else {
                        print("[OK] Adding new accommodation: \(osmPlace.name) (ID: \(osmPlace.id))")
                    }
                    
                    // Konvertiere OverpassAccommodation zu CachedAccommodation
                    let distance = calculateDistance(
                        from: resort.coordinate,
                        to: osmPlace.coordinate
                    )
                    
                    // Erstelle CachedAccommodation direkt aus OSM-Daten
                    let cached = await createCachedAccommodationFromOSM(
                        osmPlace: osmPlace,
                        resort: resort,
                        distance: distance
                    )
                    
                    cachedAccommodations.append(cached)
                    print("[OK] Added new accommodation from OSM: \(osmPlace.name) (ID: \(osmPlace.id))")
                    
                    // UI Update: Aktualisiere Statistiken live
                    let currentCount = cachedAccommodations.count
                    await MainActor.run {
                        // Only update statistics, don't store accommodations yet in the loop
                        statistics.totalAccommodations = accommodations.values.flatMap { $0 }.count + currentCount
                        
                        // Progress callback für live UI updates (pass the new accommodations directly)
                        progressCallback?(cachedAccommodations)
                    }
                }
                
                // Zusammenfassung der neuen Daten
                let osmPlacesCount = osmAccommodations.count
                let newAccommodationsCount = cachedAccommodations.count
                let skippedCount = osmPlacesCount - newAccommodationsCount
                
                if skippedCount > 0 {
                    print("\(resort.name): Found \(osmPlacesCount) OSM places, added \(newAccommodationsCount) new, skipped \(skippedCount) existing")
                } else {
                    print("\(resort.name): Added \(newAccommodationsCount) new accommodations from OpenStreetMap")
                }
            }
            
            // Update auf dem Main Thread mit lokalen Kopien
            self.updateAccommodationsOnMainThread(
                resort: resort,
                newAccommodations: cachedAccommodations
            )
            
            // Email scraping is now on-demand only - no automatic background scraping
            
            print("[OK] Loaded \(cachedAccommodations.count) accommodations for \(resort.name)")
            
        } catch {
            print("[ERROR] Failed to load accommodations for \(resort.name): \(error)")
        }
    }
    
    /// Updates accommodations on main thread to avoid concurrency issues
    @MainActor
    private func updateAccommodationsOnMainThread(
        resort: SkiResort,
        newAccommodations: [CachedAccommodation]
    ) {
        let resortKey = resort.id.uuidString
        let existingAccommodations = accommodations[resortKey] ?? []
        
        // Merge neue mit existierenden Daten um Duplikate zu vermeiden
        let mergedAccommodations = mergeDuplicates(newAccommodations, with: existingAccommodations)
        
        // Speichere gemischte Daten
        accommodations[resortKey] = mergedAccommodations
        lastUpdateDates[resortKey] = Date()
        
        // Berechne Statistiken neu (statt addieren) um Doppelzählung zu vermeiden
        calculateStatistics()
        
        let newCount = newAccommodations.count
        let totalCount = mergedAccommodations.count
        let existingCount = existingAccommodations.count
        
        if existingCount == 0 {
            print("First load for \(resort.name): \(totalCount) accommodations")
        } else {
            print("Updated \(resort.name): \(newCount) new, \(totalCount) total (was \(existingCount))")
        }
    }
    
    /// Berechnet die Entfernung zwischen zwei Koordinaten
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    /// Startet die Hintergrundaktualisierung
    private func startBackgroundUpdates() {
        // KOMPLETT DEAKTIVIERT: Keine automatischen Updates mehr!
        // Hotels werden nur geladen wenn der User ein Skigebiet explizit auswählt
        
        print("Background updates DISABLED - Lazy loading only!")
        
        // KEIN Timer mehr - verhindert DDoS-ähnliches Verhalten
        // Timer.scheduledTimer... --> ENTFERNT
    }
    
    /// ENTFERNT: checkForUpdates() - keine automatischen Updates mehr
    // private func checkForUpdates() { ... } --> DEAKTIVIERT
    
    /// Berechnet Statistiken
    private func calculateStatistics() {
        var stats = AccommodationStatistics()
        stats.totalResorts = SkiResortDatabase.shared.allSkiResorts.count
        stats.resortsWithAccommodations = accommodations.filter { !$0.value.isEmpty }.count
        stats.totalAccommodations = accommodations.values.reduce(0) { $0 + $1.count }
        
        // Berechne Feature-Statistiken
        for resortAccommodations in accommodations.values {
            for accommodation in resortAccommodations {
                if accommodation.hasCompleteContactInfo {
                    stats.accommodationsWithCompleteContact += 1
                }
                if accommodation.hasWellnessFeatures {
                    stats.accommodationsWithWellness += 1
                }
            }
        }
        
        // Berechne durchschnittliche Entfernung zu Liften
        let allAccommodations = accommodations.values.flatMap { $0 }
        if !allAccommodations.isEmpty {
            stats.averageDistanceToLift = allAccommodations.reduce(0) { $0 + Double($1.distanceToLift) } / Double(allAccommodations.count)
        }
        
        stats.lastFullUpdate = lastUpdateDates.values.max()
        
        self.statistics = stats
    }
    
    // MARK: - Persistence
    
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(accommodations)
            userDefaults.set(data, forKey: accommodationsKey)
            
            let updateData = try JSONEncoder().encode(lastUpdateDates)
            userDefaults.set(updateData, forKey: lastUpdateKey)
            
            print("Saved \(accommodations.values.flatMap { $0 }.count) accommodations to disk")
        } catch {
            print("[ERROR] Failed to save accommodations to disk: \(error)")
        }
    }
    
    private func loadFromDisk() {
        do {
            if let data = userDefaults.data(forKey: accommodationsKey) {
                accommodations = try JSONDecoder().decode([String: [CachedAccommodation]].self, from: data)
                print("Loaded \(accommodations.values.flatMap { $0 }.count) accommodations from disk")
            }
            
            if let updateData = userDefaults.data(forKey: lastUpdateKey) {
                lastUpdateDates = try JSONDecoder().decode([String: Date].self, from: updateData)
                print("Loaded last update dates from disk")
            }
            
            calculateStatistics()
        } catch {
            print("[ERROR] Failed to load accommodations from disk: \(error)")
            accommodations = [:]
            lastUpdateDates = [:]
        }
    }
    
    /// Consolidates duplicate accommodations that might exist under different resort UUIDs
    /// This addresses the issue where resorts had unstable UUIDs in earlier versions
    func consolidateDuplicateResorts() {
        print("Starting resort consolidation to fix UUID-based duplicates...")
        
        // Group accommodations by placeId to identify true duplicates
        var placeIdGroups: [String: [String]] = [:] // placeId -> [uuidStrings where this placeId exists]
        
        for (uuidString, accommodationList) in accommodations {
            for accommodation in accommodationList {
                let placeId = accommodation.placeId
                
                if placeIdGroups[placeId] == nil {
                    placeIdGroups[placeId] = []
                }
                if !placeIdGroups[placeId]!.contains(uuidString) {
                    placeIdGroups[placeId]!.append(uuidString)
                }
            }
        }
        
        var hasChanges = false
        var accommodationsToRemove: [(String, String)] = [] // (uuidString, placeId)
        
        // For each accommodation that appears under multiple resort UUIDs, keep only the most recent
        for (placeId, uuidStrings) in placeIdGroups {
            if uuidStrings.count > 1 {
                print("Found accommodation \(placeId) in \(uuidStrings.count) different resort UUID entries")
                
                // Find the accommodation with the most recent lastUpdated date
                var mostRecentUUID: String?
                var mostRecentDate: Date?
                
                for uuidString in uuidStrings {
                    if let accommodationList = accommodations[uuidString] {
                        for accommodation in accommodationList where accommodation.placeId == placeId {
                            if mostRecentDate == nil || accommodation.lastUpdated > mostRecentDate! {
                                mostRecentDate = accommodation.lastUpdated
                                mostRecentUUID = uuidString
                            }
                        }
                    }
                }
                
                // Mark duplicates for removal (keep only the most recent)
                for uuidString in uuidStrings {
                    if uuidString != mostRecentUUID {
                        accommodationsToRemove.append((uuidString, placeId))
                        hasChanges = true
                    }
                }
            }
        }
        
        // Remove the marked duplicates
        for (uuidString, placeId) in accommodationsToRemove {
            if var accommodationList = accommodations[uuidString] {
                accommodationList.removeAll { $0.placeId == placeId }
                
                if accommodationList.isEmpty {
                    // Remove the entire UUID entry if no accommodations left
                    accommodations.removeValue(forKey: uuidString)
                    lastUpdateDates.removeValue(forKey: uuidString)
                    print("Removed empty resort UUID entry: \(uuidString)")
                } else {
                    // Update the list with remaining accommodations
                    accommodations[uuidString] = accommodationList
                }
            }
        }
        
        if hasChanges {
            calculateStatistics()
            saveToDisk()
            print("[OK] Resort consolidation completed and saved")
        } else {
            print("[OK] No resort consolidation needed")
        }
    }
    
    // MARK: - Test Data Methods
    
    /// Erstellt ein Test-Hotel für das Test-Skigebiet
    private func createTestHotel(for resort: SkiResort) -> CachedAccommodation {
        return CachedAccommodation(
            testPlaceId: "test_hotel_001", 
            testName: "Test Mountain Hotel",
            testCoordinate: CLLocationCoordinate2D(latitude: 47.0010, longitude: 10.0010), // Nahe Test-Skigebiet
            testDistanceToLift: 100, // 100m zum Lift
            testHasPool: true,
            testHasJacuzzi: true, 
            testHasSpa: true,
            testHasSauna: true,
            testPricePerNight: 180.0,
            testRating: 4.5,
            testImageUrl: "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800",
            testImageUrls: [
                "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800",
                "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800",
                "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800"
            ],
            testResortId: resort.id,
            testEmail: "csieb@me.com", // Test-Email wie gewünscht
            testPhone: "+49 8821 12345",
            testWebsite: "https://test-mountain-hotel.com",
            testLastUpdated: Date()
        )
    }
}

// MARK: - Data Models

/// Gecachte Unterkunft mit zusätzlichen Metadaten
struct CachedAccommodation: Identifiable, Codable {
    let id: UUID
    let placeId: String
    let name: String
    let coordinate: CLLocationCoordinate2D?
    let distanceToLift: Int
    let hasPool: Bool
    let hasJacuzzi: Bool
    let hasSpa: Bool
    let hasSauna: Bool
    let pricePerNight: Double
    let rating: Double
    let imageUrl: String
    let imageUrls: [String] // Mehrere Bilder von Google Places
    let resortId: UUID
    let isRealData: Bool
    let email: String?
    let scrapedEmail: String? // Email von Website-Scraping
    let phone: String?
    let website: String?
    let lastUpdated: Date
    
    // Zusätzliche Google Places Daten
    let vicinity: String?
    let priceLevel: Int?
    let userRatingsTotal: Int?
    let businessStatus: String?
    let formattedAddress: String?
    let types: [String]?
    
    init(from realAccommodation: RealAccommodation, placeId: String, photoUrls: [String]? = nil, lastUpdated: Date) {
        self.id = UUID()
        self.placeId = placeId
        self.name = realAccommodation.name
        self.coordinate = realAccommodation.coordinate
        self.distanceToLift = realAccommodation.distanceToLift
        self.hasPool = realAccommodation.hasPool
        self.hasJacuzzi = realAccommodation.hasJacuzzi
        self.hasSpa = realAccommodation.hasSpa
        self.hasSauna = false
        self.pricePerNight = realAccommodation.pricePerNight
        self.rating = realAccommodation.accommodationRating
        let finalImageUrls = photoUrls ?? realAccommodation.imageURLs
        self.imageUrl = finalImageUrls.first ?? ""
        self.imageUrls = finalImageUrls
        self.resortId = realAccommodation.resort.id
        self.isRealData = true
        self.lastUpdated = lastUpdated
        self.email = nil
        self.scrapedEmail = nil
        self.phone = nil
        self.website = nil
        self.vicinity = realAccommodation.address
        self.priceLevel = nil
        self.userRatingsTotal = nil
        self.businessStatus = nil
        self.formattedAddress = nil
        self.types = nil
    }
    
    /// Test-Initialisierer für Test-Hotels
    init(testPlaceId: String, testName: String, testCoordinate: CLLocationCoordinate2D, testDistanceToLift: Int, testHasPool: Bool, testHasJacuzzi: Bool, testHasSpa: Bool, testHasSauna: Bool, testPricePerNight: Double, testRating: Double, testImageUrl: String, testImageUrls: [String], testResortId: UUID, testEmail: String, testPhone: String, testWebsite: String, testLastUpdated: Date) {
        self.id = UUID()
        self.placeId = testPlaceId
        self.name = testName
        self.coordinate = testCoordinate
        self.distanceToLift = testDistanceToLift
        self.hasPool = testHasPool
        self.hasJacuzzi = testHasJacuzzi
        self.hasSpa = testHasSpa
        self.hasSauna = testHasSauna
        self.pricePerNight = testPricePerNight
        self.rating = testRating
        self.imageUrl = testImageUrl
        self.imageUrls = testImageUrls
        self.resortId = testResortId
        self.isRealData = false // Test-Daten sind nicht echt
        self.email = nil
        self.scrapedEmail = testEmail // Test-Email direkt setzen
        self.phone = testPhone
        self.website = testWebsite
        self.lastUpdated = testLastUpdated
        
        // Test-Daten für zusätzliche Felder
        self.vicinity = "Test Area"
        self.priceLevel = 2
        self.userRatingsTotal = 42
        self.businessStatus = "OPERATIONAL"
        self.formattedAddress = "Test Mountain Hotel, Test Area, Test"
        self.types = ["lodging", "establishment"]
    }
    
    /// Konvertiert zurück zu legacy Accommodation für UI-Kompatibilität
    func toAccommodation(resort: SkiResort) async -> Accommodation {
        // Berechne objektive Bewertung wenn möglich
        let spaFeatures = SpaFeatureSet(
            hasPool: hasPool,
            hasJacuzzi: hasJacuzzi,
            hasSpa: hasSpa,
            hasSauna: hasSauna
        )
        
        // Erstelle OSM-ähnliche Daten aus verfügbaren Informationen
        let osmData = OSMHotelData(
            stars: nil, // Cached data usually doesn't have OSM stars
            capacity: nil, // Not available in cached data
            hasEmail: (scrapedEmail ?? email) != nil,
            hasPhone: phone != nil,
            hasWebsite: website != nil,
            hasCompleteAddress: true // Assume complete for cached data
        )
        
        // Lade historische Schneedaten für die Bewertung
        let snowData = await SnowDataCache.shared.getHistoricalSnowData(for: resort.coordinate)
        
        let objectiveRating = ObjectiveRatingCalculator.shared.calculateRating(
            distanceToLift: distanceToLift,
            spaFeatures: spaFeatures,
            resort: resort,
            osmData: osmData,
            snowData: snowData, // Jetzt mit echten Schneedaten!
            hotelName: name // Hotel Name für Debug
        )
        
        return Accommodation(
            name: name,
            distanceToLift: distanceToLift,
            hasPool: hasPool,
            hasJacuzzi: hasJacuzzi,
            hasSpa: hasSpa,
            hasSauna: hasSauna,
            pricePerNight: pricePerNight,
            rating: objectiveRating, // Objektive Bewertung statt gespeicherte
            imageUrl: imageUrl,
            imageUrls: imageUrls,
            resort: resort,
            isRealData: isRealData,
            email: scrapedEmail ?? email,
            phone: phone,
            website: website,
            coordinate: coordinate
        )
    }
    
    /// Prüft ob vollständige Kontaktdaten vorhanden sind
    var hasCompleteContactInfo: Bool {
        return phone != nil && website != nil
    }
    
    /// Prüft ob Wellness-Features vorhanden sind
    var hasWellnessFeatures: Bool {
        return hasPool || hasJacuzzi || hasSpa || hasSauna
    }
    
    /// Erstelle eine Kopie mit aktualisierter scraped E-Mail
    func withScrapedEmail(_ scrapedEmail: String) -> CachedAccommodation {
        return CachedAccommodation(
            id: self.id, // Preserve the original ID
            placeId: self.placeId,
            name: self.name,
            coordinate: self.coordinate,
            distanceToLift: self.distanceToLift,
            hasPool: self.hasPool,
            hasJacuzzi: self.hasJacuzzi,
            hasSpa: self.hasSpa,
            hasSauna: self.hasSauna,
            pricePerNight: self.pricePerNight,
            rating: self.rating,
            imageUrl: self.imageUrl,
            imageUrls: self.imageUrls,
            resortId: self.resortId,
            isRealData: self.isRealData,
            email: self.email,
            scrapedEmail: scrapedEmail,
            phone: self.phone,
            website: self.website,
            lastUpdated: self.lastUpdated,
            vicinity: self.vicinity,
            priceLevel: self.priceLevel,
            userRatingsTotal: self.userRatingsTotal,
            businessStatus: self.businessStatus,
            formattedAddress: self.formattedAddress,
            types: self.types
        )
    }
}

extension CachedAccommodation {
    /// Vollständiger Initializer für manuelle Erstellung
    init(id: UUID = UUID(), placeId: String, name: String, coordinate: CLLocationCoordinate2D?, distanceToLift: Int, hasPool: Bool, hasJacuzzi: Bool, hasSpa: Bool, hasSauna: Bool, pricePerNight: Double, rating: Double, imageUrl: String, imageUrls: [String], resortId: UUID, isRealData: Bool, email: String?, scrapedEmail: String?, phone: String?, website: String?, lastUpdated: Date, vicinity: String? = nil, priceLevel: Int? = nil, userRatingsTotal: Int? = nil, businessStatus: String? = nil, formattedAddress: String? = nil, types: [String]? = nil) {
        self.id = id
        self.placeId = placeId
        self.name = name
        self.coordinate = coordinate
        self.distanceToLift = distanceToLift
        self.hasPool = hasPool
        self.hasJacuzzi = hasJacuzzi
        self.hasSpa = hasSpa
        self.hasSauna = hasSauna
        self.pricePerNight = pricePerNight
        self.rating = rating
        self.imageUrl = imageUrl
        self.imageUrls = imageUrls
        self.resortId = resortId
        self.isRealData = isRealData
        self.email = email
        self.scrapedEmail = scrapedEmail
        self.phone = phone
        self.website = website
        self.lastUpdated = lastUpdated
        
        // Zusätzliche Google Places Daten
        self.vicinity = vicinity
        self.priceLevel = priceLevel
        self.userRatingsTotal = userRatingsTotal
        self.businessStatus = businessStatus
        self.formattedAddress = formattedAddress
        self.types = types
    }
}

/// Status des Ladeprozesses
enum AccommodationLoadingStatus: Equatable {
    case idle
    case loading
    case completed
    case error(String)
    
    static func == (lhs: AccommodationLoadingStatus, rhs: AccommodationLoadingStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.completed, .completed):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

/// Statistiken über die Unterkunftsdatenbank
struct AccommodationStatistics: Codable {
    var totalResorts: Int = 0
    var resortsWithAccommodations: Int = 0
    var totalAccommodations: Int = 0
    var accommodationsWithCompleteContact: Int = 0
    var accommodationsWithWellness: Int = 0
    var averageDistanceToLift: Double = 0
    var processedResorts: Int = 0
    var currentResort: String = ""
    var lastFullUpdate: Date?
    
    /// Prozentuale Abdeckung der Kontaktdaten
    var contactCompletionRate: Double {
        guard totalAccommodations > 0 else { return 0 }
        return Double(accommodationsWithCompleteContact) / Double(totalAccommodations) * 100
    }
    
    /// Prozentuale Abdeckung der Wellness-Features
    var wellnessFeatureRate: Double {
        guard totalAccommodations > 0 else { return 0 }
        return Double(accommodationsWithWellness) / Double(totalAccommodations) * 100
    }
    
    /// Durchschnittliche Anzahl Unterkünfte pro Skigebiet
    var averageAccommodationsPerResort: Double {
        guard resortsWithAccommodations > 0 else { return 0 }
        return Double(totalAccommodations) / Double(resortsWithAccommodations)
    }
}

// MARK: - Extensions

