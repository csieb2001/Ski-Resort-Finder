import SwiftUI
import Foundation
import CoreLocation
import UIKit

struct DebugView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var debugViewModel = DebugViewModel()
    @ObservedObject private var localization = LocalizationService.shared
    @ObservedObject private var accommodationDB = AccommodationDatabase.shared
    @ObservedObject private var emailService = AdvancedEmailService.shared
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                Section("system_info".localized) {
                    DebugRow(title: "ios_version".localized, value: UIDevice.current.systemVersion)
                    DebugRow(title: "device".localized, value: UIDevice.current.model)
                    DebugRow(title: "app_version".localized, value: AppVersion.currentVersion)
                    DebugRow(title: "ski_resorts_loaded".localized, value: "\(SkiResortDatabase.shared.allSkiResorts.count)")
                    DebugRow(title: "favorites".localized, value: "\(FavoritesManager.shared.favoriteResortIDs.count)")
                }
                
                Section("language_settings".localized) {
                    HStack {
                        Text("current_language".localized)
                        Spacer()
                        Text(localization.currentLanguage.displayName)
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("manual_override".localized, selection: $localization.currentLanguage) {
                        ForEach(LocalizationService.SupportedLanguage.allCases, id: \.rawValue) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("api_status".localized) {
                    HStack {
                        Text("open_meteo_weather".localized)
                        Spacer()
                        APIStatusIndicator(status: debugViewModel.weatherAPIStatus)
                    }
                    
                    HStack {
                        Text("website_screenshots".localized)
                        Spacer()
                        APIStatusIndicator(status: debugViewModel.websiteScreenshotStatus)
                    }
                    
                    HStack {
                        Text("overpass_api_osm".localized)
                        Spacer()
                        APIStatusIndicator(status: debugViewModel.overpassAPIStatus)
                    }
                    
                    HStack {
                        Text("era5_api".localized)
                        Spacer()
                        APIStatusIndicator(status: debugViewModel.era5APIStatus)
                    }
                    
                    Button("test_apis".localized) {
                        debugViewModel.testAPIs()
                    }
                    .foregroundColor(.blue)
                }
                
                Section("last_api_test".localized) {
                    if let lastTest = debugViewModel.lastTestResult {
                        DebugRow(title: "timestamp".localized, value: DateFormatter.localizedString(from: lastTest.timestamp, dateStyle: .short, timeStyle: .medium))
                        DebugRow(title: "Open-Meteo API", value: lastTest.weatherSuccess ? "test_successful".localized : "test_error".localized)
                        DebugRow(title: "Website Screenshots", value: lastTest.websiteScreenshotSuccess ? "test_successful".localized : "test_error".localized)
                        DebugRow(title: "Overpass API (OSM)", value: lastTest.overpassSuccess ? "test_successful".localized : "test_error".localized)
                        DebugRow(title: "ERA5 API", value: lastTest.era5Success ? "test_successful".localized : "test_error".localized)
                        
                        if let weatherError = lastTest.weatherError {
                            Text("weather_error".localized(with: weatherError))
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if let websiteScreenshotError = lastTest.websiteScreenshotError {
                            Text("website_screenshot_error".localized(with: websiteScreenshotError))
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if let overpassError = lastTest.overpassError {
                            Text("overpass_error".localized(with: overpassError))
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if let era5Error = lastTest.era5Error {
                            Text("era5_error".localized(with: era5Error))
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    } else {
                        Text("no_test_performed".localized)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("network".localized) {
                    DebugRow(title: "Internet", value: debugViewModel.isConnectedToInternet ? "connected".localized : "not_connected".localized)
                }
                
                Section("database".localized) {
                    ForEach(debugViewModel.resortsByCountry.keys.sorted(), id: \.self) { country in
                        NavigationLink(destination: SkiResortListView(
                            country: country, 
                            resorts: debugViewModel.resortsByCountry[country] ?? []
                        )) {
                            HStack {
                                Text(country)
                                Spacer()
                                Text("ski_resorts_count".localized(with: debugViewModel.resortsByCountry[country]?.count ?? 0))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("accommodation_database".localized) {
                    DebugRow(title: "total_resorts".localized, value: "\(accommodationDB.statistics.totalResorts)")
                    DebugRow(title: "resorts_with_accommodations".localized, value: "\(accommodationDB.statistics.resortsWithAccommodations)")
                    DebugRow(title: "total_accommodations".localized, value: "\(accommodationDB.statistics.totalAccommodations)")
                    
                    if accommodationDB.statistics.totalAccommodations > 0 {
                        DebugRow(
                            title: "avg_per_resort".localized, 
                            value: String(format: "%.1f", accommodationDB.statistics.averageAccommodationsPerResort)
                        )
                        DebugRow(
                            title: "avg_distance_to_lift".localized, 
                            value: String(format: "%.0f m", accommodationDB.statistics.averageDistanceToLift)
                        )
                    }
                    
                    // Loading Status
                    HStack {
                        Text("loading_status".localized)
                        Spacer()
                        AccommodationLoadingStatusIndicator(status: accommodationDB.loadingStatus)
                    }
                    
                    if !accommodationDB.statistics.currentResort.isEmpty {
                        DebugRow(
                            title: "current_resort".localized, 
                            value: accommodationDB.statistics.currentResort
                        )
                        DebugRow(
                            title: "progress".localized, 
                            value: "\(accommodationDB.statistics.processedResorts)/\(accommodationDB.statistics.totalResorts)"
                        )
                    }
                }
                
                Section("accommodation_features".localized) {
                    DebugRow(
                        title: "complete_contact_info".localized, 
                        value: contactInfoValue
                    )
                    DebugRow(
                        title: "wellness_features".localized, 
                        value: wellnessFeaturesValue
                    )
                    
                    if let lastUpdate = accommodationDB.statistics.lastFullUpdate {
                        DebugRow(
                            title: "last_full_update".localized, 
                            value: DateFormatter.localizedString(from: lastUpdate, dateStyle: .short, timeStyle: .medium)
                        )
                    }
                    
                    Button("force_update_all".localized) {
                        accommodationDB.loadAllAccommodations()
                    }
                    .foregroundColor(.blue)
                    
                    Button("reset_database".localized) {
                        showingResetConfirmation = true
                    }
                    .foregroundColor(.red)
                }
                
                contentScanningSection
            }
            .navigationTitle("debug_info".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close".localized) { dismiss() }
                }
            }
            .onAppear {
                debugViewModel.loadDebugInfo()
            }
            .confirmationDialog("confirm_reset_database".localized, isPresented: $showingResetConfirmation) {
                Button("reset_database_confirm".localized, role: .destructive) {
                    resetDatabase()
                }
                Button("cancel".localized, role: .cancel) { }
            } message: {
                Text("reset_database_warning".localized)
            }
        }
    }
    
    private func resetDatabase() {
        // Reset AccommodationDatabase
        accommodationDB.clearAllData()
        
        print("🗑️ Database has been reset")
    }
    
    // MARK: - Helper Views
    
    // MARK: - Computed Properties
    
    private var contactInfoValue: String {
        "\(accommodationDB.statistics.accommodationsWithCompleteContact) (\(String(format: "%.1f", accommodationDB.statistics.contactCompletionRate))%)"
    }
    
    private var wellnessFeaturesValue: String {
        "\(accommodationDB.statistics.accommodationsWithWellness) (\(String(format: "%.1f", accommodationDB.statistics.wellnessFeatureRate))%)"
    }
    
    @ViewBuilder
    private var contentScanningSection: some View {
        Section("content_scanning".localized) {
            ContentScanningProgressView(
                processingStatus: emailService.processingStatus,
                statistics: emailService.statistics
            )
        }
    }
}

struct DebugRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct APIStatusIndicator: View {
    let status: APIStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            Text(status.text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AccommodationLoadingStatusIndicator: View {
    let status: AccommodationLoadingStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            Text(status.text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

extension AccommodationLoadingStatus {
    var color: Color {
        switch self {
        case .idle: return .gray
        case .loading: return .orange
        case .completed: return .green
        case .error: return .red
        }
    }
    
    var text: String {
        switch self {
        case .idle: return "idle".localized
        case .loading: return "loading".localized
        case .completed: return "completed".localized
        case .error: return "error".localized
        }
    }
}

enum APIStatus {
    case unknown, testing, success, failure
    
    var color: Color {
        switch self {
        case .unknown: return .gray
        case .testing: return .orange
        case .success: return .green
        case .failure: return .red
        }
    }
    
    var text: String {
        switch self {
        case .unknown: return "unknown".localized
        case .testing: return "testing".localized
        case .success: return "ok".localized
        case .failure: return "error".localized
        }
    }
}

struct TestResult {
    let timestamp: Date
    let weatherSuccess: Bool
    let websiteScreenshotSuccess: Bool
    let overpassSuccess: Bool
    let era5Success: Bool
    let weatherError: String?
    let websiteScreenshotError: String?
    let overpassError: String?
    let era5Error: String?
}

class DebugViewModel: ObservableObject {
    @Published var weatherAPIStatus: APIStatus = .unknown
    @Published var websiteScreenshotStatus: APIStatus = .unknown
    @Published var overpassAPIStatus: APIStatus = .unknown
    @Published var era5APIStatus: APIStatus = .unknown
    @Published var isConnectedToInternet = true
    @Published var lastTestResult: TestResult?
    @Published var resortsByCountry: [String: [SkiResort]] = [:]
    
    private let weatherService = OpenMeteoService()
    private let overpassService = OverpassService.shared
    private let screenshotService = WebsiteScreenshotService.shared
    private let era5Service = ERA5SnowService()
    
    func loadDebugInfo() {
        // Gruppiere Skigebiete nach Land
        let resorts = SkiResortDatabase.shared.allSkiResorts
        resortsByCountry = Dictionary(grouping: resorts) { $0.country }
    }
    
    func testAPIs() {
        weatherAPIStatus = .testing
        websiteScreenshotStatus = .testing
        overpassAPIStatus = .testing
        era5APIStatus = .testing
        
        Task {
            async let weatherResult: (success: Bool, error: String?) = testWeatherAPI()
            async let websiteScreenshotResult: (success: Bool, error: String?) = testWebsiteScreenshotAPI()
            async let overpassResult: (success: Bool, error: String?) = testOverpassAPI()
            async let era5Result: (success: Bool, error: String?) = testERA5API()
            
            let results = await (weatherResult, websiteScreenshotResult, overpassResult, era5Result)
            
            await MainActor.run {
                self.lastTestResult = TestResult(
                    timestamp: Date(),
                    weatherSuccess: results.0.success,
                    websiteScreenshotSuccess: results.1.success,
                    overpassSuccess: results.2.success,
                    era5Success: results.3.success,
                    weatherError: results.0.error,
                    websiteScreenshotError: results.1.error,
                    overpassError: results.2.error,
                    era5Error: results.3.error
                )
            }
        }
    }
    
    
    private func testWeatherAPI() async -> (success: Bool, error: String?) {
        let testCoordinate = CLLocationCoordinate2D(latitude: 47.1296, longitude: 10.2686)
        do {
            let _ = try await weatherService.fetchWeather(for: testCoordinate)
            await MainActor.run { self.weatherAPIStatus = .success }
            return (true, nil)
        } catch {
            await MainActor.run { self.weatherAPIStatus = .failure }
            return (false, error.localizedDescription)
        }
    }
    
    private func testWebsiteScreenshotAPI() async -> (success: Bool, error: String?) {
        let screenshot = await screenshotService.generateScreenshot(
            from: "https://www.hotel-arlberg.com",
            accommodationName: "Test Hotel Arlberg"
        )
        
        if screenshot != nil {
            await MainActor.run { self.websiteScreenshotStatus = .success }
            return (true, nil)
        } else {
            await MainActor.run { self.websiteScreenshotStatus = .failure }
            return (false, "Failed to generate screenshot")
        }
    }
    
    
    private func testOverpassAPI() async -> (success: Bool, error: String?) {
        let testCoordinate = CLLocationCoordinate2D(latitude: 47.1296, longitude: 10.2686)
        do {
            let _ = try await overpassService.searchAccommodations(around: testCoordinate, radius: 5000)
            await MainActor.run { self.overpassAPIStatus = .success }
            return (true, nil)
        } catch {
            await MainActor.run { self.overpassAPIStatus = .failure }
            return (false, error.localizedDescription)
        }
    }
    
    private func testERA5API() async -> (success: Bool, error: String?) {
        let testCoordinate = CLLocationCoordinate2D(latitude: 47.1296, longitude: 10.2686)
        do {
            let _ = try await era5Service.fetchHistoricalSnowData(for: testCoordinate)
            await MainActor.run { self.era5APIStatus = .success }
            return (true, nil)
        } catch {
            await MainActor.run { self.era5APIStatus = .failure }
            return (false, error.localizedDescription)
        }
    }
}

// MARK: - Ski Resort List View

struct SkiResortListView: View {
    let country: String
    let resorts: [SkiResort]
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localization = LocalizationService.shared
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    
    var body: some View {
        List {
            ForEach(resorts.sorted(by: { $0.name < $1.name })) { resort in
                NavigationLink(destination: SkiResortDetailView(resort: resort)) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(resort.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if favoritesManager.favoriteResortIDs.contains(resort.id.uuidString) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }
                        
                        HStack {
                            Text("\(resort.region)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Label("\(resort.totalSlopes) km", systemImage: "figure.skiing.downhill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                
                                Label("\(resort.maxElevation) m", systemImage: "mountain.2")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        // Koordinaten für Debug-Zwecke
                        Text("Lat: \(String(format: "%.4f", resort.coordinate.latitude)), Lon: \(String(format: "%.4f", resort.coordinate.longitude))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(country)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("\(resorts.count) Resorts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Ski Resort Detail View

struct SkiResortDetailView: View {
    let resort: SkiResort
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localization = LocalizationService.shared
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(resort.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: toggleFavorite) {
                            Image(systemName: isFavorite ? "star.fill" : "star")
                                .foregroundColor(isFavorite ? .yellow : .gray)
                                .font(.title2)
                        }
                    }
                    
                    Text("\(resort.country.localizedCountryName()), \(resort.region)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                // Statistics
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    StatCard(
                        title: "total_slopes".localized,
                        value: "\(resort.totalSlopes) km",
                        icon: "figure.skiing.downhill",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "max_height".localized,
                        value: "\(resort.maxElevation) m",
                        icon: "mountain.2",
                        color: .green
                    )
                    
                    StatCard(
                        title: "elevation_range".localized,
                        value: "\(resort.minElevation) - \(resort.maxElevation) m",
                        icon: "arrow.up.and.down",
                        color: .orange
                    )
                    
                    if let liftCount = resort.liftCount {
                        StatCard(
                            title: "total_lifts".localized,
                            value: "\(liftCount)",
                            icon: "cable.car",
                            color: .purple
                        )
                    }
                }
                
                // Slope Breakdown (if available)
                if let slopeBreakdown = resort.slopeBreakdown {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("slope_breakdown".localized)
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            SlopeCard(title: "beginner_slopes".localized, count: slopeBreakdown.greenSlopes, color: .green)
                            SlopeCard(title: "easy_slopes".localized, count: slopeBreakdown.blueSlopes, color: .blue)
                            SlopeCard(title: "intermediate_slopes".localized, count: slopeBreakdown.redSlopes, color: .red)
                            SlopeCard(title: "expert_slopes".localized, count: slopeBreakdown.blackSlopes, color: .black)
                        }
                    }
                }
                
                // Coordinates (Debug Info)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Coordinates")
                        .font(.headline)
                    Text("Latitude: \(String(format: "%.6f", resort.coordinate.latitude))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Longitude: \(String(format: "%.6f", resort.coordinate.longitude))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle("resort_details".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var isFavorite: Bool {
        favoritesManager.favoriteResortIDs.contains(resort.id.uuidString)
    }
    
    private func toggleFavorite() {
        favoritesManager.toggleFavorite(resort)
        HapticFeedback.impact(.light)
    }
}

// MARK: - Helper Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SlopeCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}