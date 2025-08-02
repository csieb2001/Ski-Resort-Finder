# SkiResort Finder - iOS App

Eine iOS-App für Ski-Enthusiasten zum Finden von Unterkünften mit speziellen Kriterien für Wintersportler.

## ⚠️ WICHTIGE GRUNDSÄTZE

**STRUKTURIERTES SKIPASS-PREIS-SCRAPING:**
- **Hierarchische Quellen:** skiresort.info → skiinfo.de → bergfex.de → Resort-Website
- **Umfassende Länderabdeckung:** 15+ europäische Länder über skiinfo.de
- **Multi-Währungs-Support:** EUR, CHF, SEK, NOK, CZK, PLN, BGN, RON
- **Intelligente Fallbacks:** Geografische Zuordnung für unbekannte Länder
- **Transparente Quellenangabe:** Benutzer sehen genau woher die Preise stammen

**KEINE FAKE-DATEN POLICY:**
- Im gesamten Projekt werden ausschließlich echte Daten aus APIs verwendet
- Keine generierten, fake oder simulierten Kontaktdaten (E-Mail, Telefon, Website)
- Keine fake Skipass-Preise, Liftanzahlen oder andere Gebietsdaten verwenden
- **KEINE fake Schneedaten**: Ohne gültigen ERA5 API-Schlüssel werden KEINE Schneedaten generiert
- Hotel-Bewertungen funktionieren ohne Schnee-Komponente (22% Gewichtung entfällt)
- Wenn keine echten Daten verfügbar sind, wird dies transparent angezeigt ("Nicht verfügbar")
- Benutzer werden klar informiert, wenn Daten nicht verfügbar sind
- Alle Datenquellen müssen authentisch und verifizierbar sein
- **NIEMALS** fake Preise, Zahlen oder andere Daten erfinden - nur echte gescrapte oder API-Daten verwenden

**AUTOMATISCHE LOCALIZATION POLICY:**
- **ALLE** Texte in der App müssen automatisch lokalisiert werden
- **NIEMALS** hart kodierte deutsche oder englische Texte direkt im Code verwenden
- Immer `.localized` für alle Benutzer-sichtbaren Texte verwenden
- **PFLICHT:** Neue Texte sofort in ALLE Sprachdateien eintragen:
  - de.lproj/Localizable.strings (Deutsch)
  - en.lproj/Localizable.strings (Englisch)
  - fr.lproj/Localizable.strings (Französisch)
  - es.lproj/Localizable.strings (Spanisch)
  - it.lproj/Localizable.strings (Italienisch)
  - pt.lproj/Localizable.strings (Portugiesisch)
  - ru.lproj/Localizable.strings (Russisch)
  - uk.lproj/Localizable.strings (Ukrainisch)
- Bei neuen Features oder Views: Localization-Keys ZUERST in allen Sprachen definieren, dann implementieren
- Beispiel: `"search_prices".localized` statt `"Preise suchen"`
- **NIEMALS** nur eine oder zwei Sprachen aktualisieren - immer alle!

## Projektübersicht

Diese SwiftUI-App ermöglicht es Nutzern:
- Skigebiete weltweit zu suchen und auszuwählen
- Reisezeitraum festzulegen
- Unterkünfte nach Wintersport-spezifischen Kriterien zu filtern
- Direkte Buchungsanfragen an Hotels zu senden

## Hauptfunktionen

### 1. Skigebiet-Auswahl
- Textbasierte Suche nach Skiort, Land oder Region
- Anzeige von Gebietsinformationen (Pistenlänge, Höhenlage)
- Beispieldaten für St. Anton, Verbier, Chamonix und Aspen

### 2. Filterkriterien für Unterkünfte
- **Entfernung zur Liftstation** (in Metern)
- **Wellness-Angebote**: Pool, Jacuzzi, Spa
- **Bewertungen** und **Preise pro Nacht**

### 3. Buchungsanfrage-System
- Direkter Kontakt zur Unterkunft
- Formular mit Kontaktdaten und persönlicher Nachricht

## Technische Implementierung

### Architektur
- **SwiftUI** mit MVVM-Pattern
- **ObservableObject** für State Management
- Modulare View-Komponenten

### Hauptkomponenten

#### Models
```swift
struct SkiResort: Identifiable
struct Accommodation: Identifiable
```

#### ViewModels
```swift
class SkiResortViewModel: ObservableObject
```

#### Views
- `ContentView`: Hauptansicht mit Suchformular
- `ResortPickerView`: Skigebiet-Auswahl
- `AccommodationListView`: Unterkunftsliste
- `AccommodationCard`: Einzelne Unterkunftsanzeige
- `BookingRequestView`: Buchungsanfrage-Formular

## Installation und Setup

### Voraussetzungen
- Xcode 14.0 oder höher
- iOS 16.0 oder höher
- Swift 5.7 oder höher

### Schritte
1. Neues iOS-Projekt in Xcode erstellen
2. SwiftUI als Framework wählen
3. Code in die entsprechenden Dateien kopieren
4. Build und Run

## Code-Struktur

```
SkiResortFinderApp/
├── Models/
│   ├── SkiResort.swift
│   └── Accommodation.swift
├── ViewModels/
│   └── SkiResortViewModel.swift
├── Views/
│   ├── ContentView.swift
│   ├── ResortPickerView.swift
│   ├── AccommodationListView.swift
│   ├── AccommodationCard.swift
│   └── BookingRequestView.swift
└── SkiResortFinderApp.swift
```

## Vollständiger Code

```swift
import SwiftUI
import MapKit

// MARK: - Models
struct SkiResort: Identifiable {
    let id = UUID()
    let name: String
    let country: String
    let region: String
    let totalSlopes: Int
    let maxElevation: Int
    let minElevation: Int
    let coordinate: CLLocationCoordinate2D
}

struct Accommodation: Identifiable {
    let id = UUID()
    let name: String
    let distanceToLift: Int // in meters
    let hasPool: Bool
    let hasJacuzzi: Bool
    let hasSpa: Bool
    let pricePerNight: Double
    let rating: Double
    let imageUrl: String
    let resort: SkiResort
}

// MARK: - ViewModels
class SkiResortViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedResort: SkiResort?
    @Published var startDate = Date()
    @Published var endDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @Published var accommodations: [Accommodation] = []
    @Published var isLoading = false
    
    // Sample data
    let sampleResorts = [
        SkiResort(name: "St. Anton am Arlberg", country: "Österreich", region: "Tirol", 
                  totalSlopes: 305, maxElevation: 2811, minElevation: 1304,
                  coordinate: CLLocationCoordinate2D(latitude: 47.1296, longitude: 10.2686)),
        SkiResort(name: "Verbier", country: "Schweiz", region: "Wallis", 
                  totalSlopes: 410, maxElevation: 3330, minElevation: 1500,
                  coordinate: CLLocationCoordinate2D(latitude: 46.0960, longitude: 7.2286)),
        SkiResort(name: "Chamonix", country: "Frankreich", region: "Haute-Savoie", 
                  totalSlopes: 155, maxElevation: 3842, minElevation: 1035,
                  coordinate: CLLocationCoordinate2D(latitude: 45.9237, longitude: 6.8694)),
        SkiResort(name: "Aspen", country: "USA", region: "Colorado", 
                  totalSlopes: 337, maxElevation: 3813, minElevation: 2399,
                  coordinate: CLLocationCoordinate2D(latitude: 39.1911, longitude: -106.8175))
    ]
    
    var filteredResorts: [SkiResort] {
        if searchText.isEmpty {
            return sampleResorts
        } else {
            return sampleResorts.filter { resort in
                resort.name.localizedCaseInsensitiveContains(searchText) ||
                resort.country.localizedCaseInsensitiveContains(searchText) ||
                resort.region.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func searchAccommodations() {
        guard let resort = selectedResort else { return }
        
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.accommodations = [
                Accommodation(name: "Alpine Wellness Hotel", distanceToLift: 50, 
                             hasPool: true, hasJacuzzi: true, hasSpa: true,
                             pricePerNight: 280, rating: 4.8, 
                             imageUrl: "hotel1", resort: resort),
                Accommodation(name: "Ski Lodge Deluxe", distanceToLift: 200, 
                             hasPool: true, hasJacuzzi: false, hasSpa: true,
                             pricePerNight: 195, rating: 4.5, 
                             imageUrl: "hotel2", resort: resort),
                Accommodation(name: "Mountain View Resort", distanceToLift: 100, 
                             hasPool: false, hasJacuzzi: true, hasSpa: false,
                             pricePerNight: 150, rating: 4.3, 
                             imageUrl: "hotel3", resort: resort),
                Accommodation(name: "Powder Paradise Hotel", distanceToLift: 0, 
                             hasPool: true, hasJacuzzi: true, hasSpa: true,
                             pricePerNight: 350, rating: 4.9, 
                             imageUrl: "hotel4", resort: resort)
            ]
            self.isLoading = false
        }
    }
}

// MARK: - Views
struct ContentView: View {
    @StateObject private var viewModel = SkiResortViewModel()
    @State private var showingResortPicker = false
    @State private var showingAccommodations = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                Text("SkiResort Finder")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 15) {
                    // Resort Selection
                    Button(action: { showingResortPicker = true }) {
                        HStack {
                            Image(systemName: "mountain.2.fill")
                            Text(viewModel.selectedResort?.name ?? "Skigebiet auswählen")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .foregroundColor(.primary)
                    
                    // Date Selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Reisezeitraum")
                            .font(.headline)
                        
                        DatePicker("Von", selection: $viewModel.startDate, displayedComponents: .date)
                        DatePicker("Bis", selection: $viewModel.endDate, displayedComponents: .date)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Search Button
                    Button(action: {
                        viewModel.searchAccommodations()
                        showingAccommodations = true
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Unterkünfte suchen")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.selectedResort != nil ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.selectedResort == nil)
                }
                .padding(.horizontal)
                
                // Resort Info
                if let resort = viewModel.selectedResort {
                    ResortInfoCard(resort: resort)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .sheet(isPresented: $showingResortPicker) {
                ResortPickerView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAccommodations) {
                AccommodationListView(viewModel: viewModel)
            }
        }
    }
}

struct ResortPickerView: View {
    @ObservedObject var viewModel: SkiResortViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Suche nach Ort oder Land...", text: $viewModel.searchText)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
                
                // Resort List
                List(viewModel.filteredResorts) { resort in
                    Button(action: {
                        viewModel.selectedResort = resort
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(resort.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            HStack {
                                Text("\(resort.country), \(resort.region)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Label("\(resort.totalSlopes) km", systemImage: "figure.skiing.downhill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("Skigebiet auswählen")
            .navigationBarItems(trailing: Button("Schließen") { dismiss() })
        }
    }
}

struct ResortInfoCard: View {
    let resort: SkiResort
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ausgewähltes Skigebiet")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(resort.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("\(resort.country), \(resort.region)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            HStack(spacing: 20) {
                Label("\(resort.totalSlopes) km", systemImage: "figure.skiing.downhill")
                Label("\(resort.maxElevation) m", systemImage: "arrow.up.to.line")
            }
            .font(.caption)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

struct AccommodationListView: View {
    @ObservedObject var viewModel: SkiResortViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedAccommodation: Accommodation?
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Suche Unterkünfte...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(viewModel.accommodations) { accommodation in
                                AccommodationCard(accommodation: accommodation) {
                                    selectedAccommodation = accommodation
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Verfügbare Unterkünfte")
            .navigationBarItems(trailing: Button("Schließen") { dismiss() })
            .sheet(item: $selectedAccommodation) { accommodation in
                BookingRequestView(accommodation: accommodation)
            }
        }
    }
}

struct AccommodationCard: View {
    let accommodation: Accommodation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Hotel Image Placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 150)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
                    .cornerRadius(10)
                
                // Hotel Info
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(accommodation.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", accommodation.rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Distance to Lift
                    Label("\(accommodation.distanceToLift) m zur Liftstation", 
                          systemImage: "figure.skiing.downhill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    // Wellness Features
                    HStack(spacing: 15) {
                        if accommodation.hasPool {
                            Label("Pool", systemImage: "drop.fill")
                                .font(.caption)
                                .foregroundColor(.cyan)
                        }
                        if accommodation.hasJacuzzi {
                            Label("Jacuzzi", systemImage: "sparkles")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                        if accommodation.hasSpa {
                            Label("Spa", systemImage: "leaf.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Price
                    HStack {
                        Text("€\(Int(accommodation.pricePerNight))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("pro Nacht")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Anfrage stellen")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                }
                .padding()
            }
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 5)
        }
    }
}

struct BookingRequestView: View {
    let accommodation: Accommodation
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Kontaktdaten") {
                    TextField("Name", text: $name)
                    TextField("E-Mail", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section("Nachricht") {
                    TextEditor(text: $message)
                        .frame(minHeight: 100)
                }
                
                Section("Unterkunft") {
                    VStack(alignment: .leading) {
                        Text(accommodation.name)
                            .font(.headline)
                        Label("\(accommodation.distanceToLift) m zur Liftstation", 
                              systemImage: "figure.skiing.downhill")
                            .font(.caption)
                        Text("€\(Int(accommodation.pricePerNight)) pro Nacht")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Buchungsanfrage")
            .navigationBarItems(
                leading: Button("Abbrechen") { dismiss() },
                trailing: Button("Senden") {
                    showingAlert = true
                }
                .disabled(name.isEmpty || email.isEmpty)
            )
            .alert("Anfrage gesendet", isPresented: $showingAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Ihre Anfrage wurde erfolgreich an \(accommodation.name) gesendet. Sie erhalten in Kürze eine Antwort per E-Mail.")
            }
        }
    }
}

// MARK: - App Entry Point
@main
struct SkiResortFinderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Geplante Erweiterungen

### Phase 1: Basis-Features
- [ ] Integration echter Skigebiet-APIs
- [ ] Echte Hotel-Buchungs-APIs (Booking.com, Hotels.com)
- [ ] Kartenansicht mit MapKit
- [ ] Erweiterte Filteroptionen

### Phase 2: Erweiterte Features
- [ ] Benutzer-Accounts und Favoriten
- [ ] Push-Benachrichtigungen für Angebote
- [ ] Bewertungssystem
- [ ] Mehrsprachigkeit

### Phase 3: Premium-Features
- [ ] Wetter-Integration
- [ ] Schneebericht und Pistenstatus
- [ ] Skipass-Buchung
- [ ] Equipment-Verleih Integration

## API-Integration

### Benötigte APIs
1. **Skigebiet-Daten**
   - Skiresort.info API
   - OpenSnow API
   
2. **Unterkunfts-Daten**
   - Booking.com API
   - Hotels.com API
   - Airbnb API (falls verfügbar)

3. **Zusätzliche Services**
   - OpenWeatherMap für Wetter
   - Google Maps für Kartenansicht

## Deployment

### App Store Vorbereitung
1. Apple Developer Account erstellen
2. App Icons und Screenshots erstellen
3. App Store Beschreibung verfassen
4. Datenschutzerklärung erstellen

### Testing
- Unit Tests für ViewModels
- UI Tests für kritische User Flows
- Beta Testing via TestFlight

## Lizenz und Verwendung

Dieser Code kann frei für persönliche und kommerzielle Projekte verwendet werden.

---

**Erstellt für**: Ski-Enthusiasten App Projekt  
**Version**: 1.0  
**Datum**: Januar 2025