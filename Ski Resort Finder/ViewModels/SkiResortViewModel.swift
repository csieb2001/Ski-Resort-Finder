import Foundation
import MapKit

class SkiResortViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedResort: SkiResort?
    @Published var startDate = Date() {
        didSet {
            // Automatisch endDate auf 7 Tage nach startDate setzen
            endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate.addingTimeInterval(7 * 24 * 60 * 60)
        }
    }
    @Published var endDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @Published var numberOfGuests = 2
    @Published var numberOfRooms = 1
    @Published var accommodations: [Accommodation] = []
    @Published var isLoading = false
    @Published var weatherData: WeatherData?
    @Published var openMeteoData: OpenMeteoWeatherData?
    @Published var errorMessage: String?
    
    private let apiService = APIService()
    private let googlePlacesService = GooglePlacesService()
    private let weatherService = OpenMeteoService()
    private let database = SkiResortDatabase.shared
    // Using SimpleEmailService for basic email functionality
    
    var filteredResorts: [SkiResort] {
        return database.searchResorts(query: searchText)
    }
    
    
    @MainActor
    func searchAccommodations() {
        guard let resort = selectedResort else { 
            print("❌ No resort selected")
            return 
        }
        
        print("🔍 Starting search for accommodations in \(resort.name)")
        isLoading = true
        errorMessage = nil
        
        // Verwende AccommodationDatabase anstatt direkte API-Calls
        let cachedAccommodations = AccommodationDatabase.shared.getAccommodations(for: resort)
        print("📦 Found \(cachedAccommodations.count) cached accommodations for \(resort.name)")
        
        if !cachedAccommodations.isEmpty {
            // Verwende gecachte Daten
            self.accommodations = cachedAccommodations.map { $0.toAccommodation(resort: resort) }
            self.isLoading = false
            print("✅ Loaded \(cachedAccommodations.count) cached accommodations for \(resort.name)")
            return
        }
        
        // Falls keine gecachten Daten, lade von API mit UI-Progress
        print("🔄 Loading accommodations for \(resort.name) from database...")
        AccommodationDatabase.shared.loadAccommodationsForSingleResort(
            resort,
            progressCallback: { [weak self] cachedAccommodations in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    // Update UI with the live accommodations from callback
                    let newAccommodations = cachedAccommodations.map { $0.toAccommodation(resort: resort) }
                    self.accommodations = newAccommodations
                    print("📊 Live update: UI now shows \(self.accommodations.count) accommodations")
                    print("📊 First accommodation has spa: \(newAccommodations.first?.hasSpaFeatures ?? false)")
                }
            }
        ) {
            // Completion callback - wird ausgeführt wenn das Laden abgeschlossen ist
            print("📞 Completion callback called for \(resort.name)")
            DispatchQueue.main.async {
                let updatedCachedAccommodations = AccommodationDatabase.shared.getAccommodations(for: resort)
                print("🔍 After loading: Found \(updatedCachedAccommodations.count) accommodations for \(resort.name)")
                
                if !updatedCachedAccommodations.isEmpty {
                    self.accommodations = updatedCachedAccommodations.map { $0.toAccommodation(resort: resort) }
                    print("✅ UI Updated: Loaded \(updatedCachedAccommodations.count) fresh accommodations for \(resort.name) from database")
                } else {
                    print("⚠️ No accommodations found for \(resort.name) after loading")
                    
                    // Fallback: Create some test accommodations for "Test Skigebiet"
                    if resort.name == "Test Skigebiet" {
                        print("🧪 Creating fallback test accommodations")
                        self.accommodations = self.createTestAccommodations(for: resort)
                        print("✅ Created \(self.accommodations.count) fallback test accommodations")
                    } else {
                        self.errorMessage = "Keine Unterkünfte für \(resort.name) gefunden"
                    }
                }
                self.isLoading = false
            }
        }
    }
    
    /// Direkte API-Ladung als letzter Fallback
    private func loadFromAPIDirectly(resort: SkiResort) {
        // Implementierung als Fallback falls AccommodationDatabase komplett fehlschlägt
        self.errorMessage = "Keine Unterkünfte in der Datenbank verfügbar. Datenbank wird aktualisiert..."
        print("⚠️ No accommodations found in database for \(resort.name) - triggering background update")
    }
    
    // REMOVED: Old fallback methods - using AccommodationDatabase now
    
    @MainActor
    func fetchWeatherData() async {
        guard let resort = selectedResort else { return }
        
        do {
            // Verwende Open-Meteo für bessere Wetterdaten
            let openMeteoData = try await weatherService.fetchWeather(
                for: resort.coordinate
            )
            
            self.openMeteoData = openMeteoData
            
            // Erstelle auch kompatible WeatherData für bestehende UI
            self.weatherData = WeatherData(from: openMeteoData)
            
            print("✅ Wetterdaten erfolgreich geladen für \(resort.name)")
            
        } catch {
            print("❌ Fehler beim Laden der Wetterdaten: \(error)")
            self.weatherData = nil
            self.openMeteoData = nil
        }
    }
    
    // Helper functions for weather code conversion
    private func weatherCodeToDescription(_ code: Int) -> String {
        switch code {
        case 0: return "clear_sky".localized
        case 1, 2, 3: return "partly_cloudy".localized
        case 45, 48: return "fog".localized
        case 51, 53, 55: return "drizzle".localized
        case 56, 57: return "freezing_drizzle".localized
        case 61, 63, 65: return "rain".localized
        case 66, 67: return "freezing_rain".localized
        case 71, 73, 75: return "snow".localized
        case 77: return "snow_grains".localized
        case 80, 81, 82: return "rain_showers".localized
        case 85, 86: return "snow_showers".localized
        case 95: return "thunderstorm".localized
        case 96, 99: return "thunderstorm_with_hail".localized
        default: return "unknown".localized
        }
    }
    
    private func weatherCodeToIcon(_ code: Int) -> String {
        switch code {
        case 0: return "01d"
        case 1, 2, 3: return "02d"
        case 45, 48: return "50d"
        case 51, 53, 55: return "09d"
        case 56, 57: return "09d"
        case 61, 63, 65: return "10d"
        case 66, 67: return "10d"
        case 71, 73, 75: return "13d"
        case 77: return "13d"
        case 80, 81, 82: return "09d"
        case 85, 86: return "13d"
        case 95: return "11d"
        case 96, 99: return "11d"
        default: return "01d"
        }
    }
    
    /// Generiert eine E-Mail-Adresse aus dem Hotelnamen
    private func generateEmailFromHotelName(_ hotelName: String) -> String {
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
    
    // MARK: - Test Data Fallback
    private func createTestAccommodations(for resort: SkiResort) -> [Accommodation] {
        return [
            Accommodation(
                name: "Test Mountain Hotel",
                distanceToLift: 100,
                hasPool: true,
                hasJacuzzi: true,
                hasSpa: true,
                hasSauna: true,
                pricePerNight: 180.0,
                rating: 4.5,
                imageUrl: "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800",
                imageUrls: [
                    "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800",
                    "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800",
                    "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800"
                ],
                resort: resort,
                isRealData: false,
                email: "csieb@me.com",
                phone: "+49 8821 12345",
                website: "https://test-mountain-hotel.com"
            ),
            Accommodation(
                name: "Alpine Test Lodge",
                distanceToLift: 50,
                hasPool: false,
                hasJacuzzi: true,
                hasSpa: false,
                hasSauna: true,
                pricePerNight: 120.0,
                rating: 4.2,
                imageUrl: "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800",
                imageUrls: ["https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800"],
                resort: resort,
                isRealData: false,
                email: "info@alpine-test-lodge.com",
                phone: "+49 8821 54321",
                website: "https://alpine-test-lodge.com"
            )
        ]
    }
    
    // MARK: - Accommodation Updates
    func updateAccommodation(_ updatedAccommodation: Accommodation) {
        print("🔄 SkiResortViewModel: Updating accommodation \(updatedAccommodation.name)")
        print("🔄 Updated accommodation ID: \(updatedAccommodation.id)")
        print("🔄 Updated spa features: Pool=\(updatedAccommodation.hasPool), Jacuzzi=\(updatedAccommodation.hasJacuzzi), Spa=\(updatedAccommodation.hasSpa), Sauna=\(updatedAccommodation.hasSauna)")
        
        // Find the accommodation by ID first (now stable), fallback to name/resort matching
        if let index = accommodations.firstIndex(where: { $0.id == updatedAccommodation.id }) {
            print("✅ Found accommodation by ID at index \(index)")
            accommodations[index] = updatedAccommodation
        } else if let index = accommodations.firstIndex(where: { $0.name == updatedAccommodation.name && $0.resort.id == updatedAccommodation.resort.id }) {
            print("✅ Found accommodation by name/resort at index \(index)")
            accommodations[index] = updatedAccommodation
        } else {
            print("❌ Could not find accommodation to update")
            print("❌ Available accommodation IDs: \(accommodations.map { $0.id })")
            print("❌ Available accommodation names: \(accommodations.map { $0.name })")
        }
    }
}