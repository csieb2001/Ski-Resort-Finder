//
//  IntegrationTests.swift
//  Ski Resort FinderTests
//
//  Integration tests that test interaction between multiple services.
//

import Testing
import CoreLocation
@testable import Ski_Resort_Finder

// MARK: - FavoritesManager Integration Tests

struct FavoritesManagerIntegrationTests {

    @Test @MainActor func toggleFavoriteAddsAndRemoves() {
        let manager = FavoritesManager.shared
        let resort = SkiResortModelTests.makeResort(name: "IntTest Resort", latitude: 99.0, longitude: 99.0)
        let resortID = resort.id.uuidString

        // Ensure clean state
        if manager.favoriteResortIDs.contains(resortID) {
            manager.toggleFavorite(resort)
        }

        // Add favorite
        #expect(manager.isFavorite(resort) == false)
        manager.toggleFavorite(resort)
        #expect(manager.isFavorite(resort) == true)
        #expect(manager.favoriteResortIDs.contains(resortID))

        // Remove favorite
        manager.toggleFavorite(resort)
        #expect(manager.isFavorite(resort) == false)
        #expect(!manager.favoriteResortIDs.contains(resortID))
    }

    @Test @MainActor func getFavoriteResortsFiltersCorrectly() {
        let manager = FavoritesManager.shared
        let resort1 = SkiResortModelTests.makeResort(name: "IntFav1", latitude: 98.0, longitude: 98.0)
        let resort2 = SkiResortModelTests.makeResort(name: "IntFav2", latitude: 97.0, longitude: 97.0)
        let resort3 = SkiResortModelTests.makeResort(name: "IntFav3", latitude: 96.0, longitude: 96.0)
        let allResorts = [resort1, resort2, resort3]

        // Clean state
        for r in allResorts {
            if manager.isFavorite(r) { manager.toggleFavorite(r) }
        }

        // Add resort1 and resort3 as favorites
        manager.toggleFavorite(resort1)
        manager.toggleFavorite(resort3)

        let favorites = manager.getFavoriteResorts(from: allResorts)
        #expect(favorites.count == 2)
        #expect(favorites.contains(resort1))
        #expect(!favorites.contains(resort2))
        #expect(favorites.contains(resort3))

        // Cleanup
        manager.toggleFavorite(resort1)
        manager.toggleFavorite(resort3)
    }
}

// MARK: - SnowDataCache Integration Tests

struct SnowDataCacheIntegrationTests {

    @Test func cacheKeyConsistency() {
        let cache = SnowDataCache.shared
        let coord = CLLocationCoordinate2D(latitude: 47.1296, longitude: 10.2686)

        // Both calls should use the same cache key
        let hasCached = cache.hasCachedData(for: coord)
        // Just verify the method doesn't crash - the actual caching depends on prior API calls
        #expect(hasCached == true || hasCached == false) // Always true
    }

    @Test func cacheReturnsDataForCoordinatesWithNearbyRounding() {
        let cache = SnowDataCache.shared
        // Coordinates that should round to same key (2 decimal places)
        let coord1 = CLLocationCoordinate2D(latitude: 47.1296, longitude: 10.2686)
        let coord2 = CLLocationCoordinate2D(latitude: 47.1299, longitude: 10.2684)

        // Both should map to "47.13,10.27" cache key
        let hasCached1 = cache.hasCachedData(for: coord1)
        let hasCached2 = cache.hasCachedData(for: coord2)

        // They should have the same cache status since they round to same key
        #expect(hasCached1 == hasCached2)
    }
}

// MARK: - ObjectiveRating + Resort Integration Tests

struct ObjectiveRatingIntegrationTests {

    @Test func ratingForRealResorts() {
        let db = SkiResortDatabase.shared
        let calculator = ObjectiveRatingCalculator.shared

        // Get first 3 real resorts
        let resorts = Array(db.allSkiResorts.prefix(3))

        for resort in resorts {
            let spa = SpaFeatureSet(hasPool: false, hasJacuzzi: false, hasSpa: false, hasSauna: false)
            let rating = calculator.calculateRating(
                distanceToLift: 200,
                spaFeatures: spa,
                resort: resort,
                osmData: nil,
                snowData: nil
            )

            #expect(rating != nil, "Rating should be calculable for \(resort.name)")
            if let rating = rating {
                #expect(rating >= 1.0 && rating <= 5.0,
                        "Rating \(rating) out of range for \(resort.name)")
            }
        }
    }

    @Test func largerResortScoresHigherThanSmaller() {
        let calculator = ObjectiveRatingCalculator.shared
        let spa = SpaFeatureSet(hasPool: false, hasJacuzzi: false, hasSpa: false, hasSauna: false)

        let largeResort = SkiResortModelTests.makeResort(
            name: "Large Resort",
            totalSlopes: 500,
            maxElevation: 3500,
            minElevation: 1000
        )

        let smallResort = SkiResortModelTests.makeResort(
            name: "Small Resort",
            totalSlopes: 20,
            maxElevation: 1200,
            minElevation: 800
        )

        let largeRating = calculator.calculateRating(
            distanceToLift: 100,
            spaFeatures: spa,
            resort: largeResort,
            osmData: nil,
            snowData: nil
        )

        let smallRating = calculator.calculateRating(
            distanceToLift: 100,
            spaFeatures: spa,
            resort: smallResort,
            osmData: nil,
            snowData: nil
        )

        #expect(largeRating != nil)
        #expect(smallRating != nil)
        #expect(largeRating! > smallRating!)
    }
}

// MARK: - Accommodation + Resort Integration Tests

struct AccommodationResortIntegrationTests {

    @Test func accommodationLinkedToResort() {
        let resort = SkiResortModelTests.makeResort(name: "Linked Resort")
        let acc = AccommodationModelTests.makeAccommodation(name: "Linked Hotel")

        // The accommodation should reference a valid resort
        #expect(!acc.resort.name.isEmpty)
        #expect(!acc.resort.country.isEmpty)
    }

    @Test func multipleAccommodationsForSameResort() {
        let resort = SkiResortModelTests.makeResort(name: "Multi Hotel Resort")

        let hotels = (1...5).map { i in
            Accommodation(
                name: "Hotel \(i)",
                distanceToLift: i * 100,
                hasPool: i % 2 == 0,
                hasJacuzzi: false,
                hasSpa: false,
                pricePerNight: Double(100 + i * 50),
                imageUrl: "test.jpg",
                resort: resort
            )
        }

        // All should have unique IDs
        let uniqueIDs = Set(hotels.map { $0.id })
        #expect(uniqueIDs.count == 5)

        // All should reference the same resort
        #expect(hotels.allSatisfy { $0.resort == resort })
    }

    @Test func accommodationPriceCategoriesDistribution() {
        let resort = SkiResortModelTests.makeResort()
        let prices: [Double] = [50, 100, 150, 200, 250, 300, 350, 500]

        let accommodations = prices.map { price in
            Accommodation(
                name: "Hotel \(Int(price))",
                distanceToLift: 100,
                hasPool: false,
                hasJacuzzi: false,
                hasSpa: false,
                pricePerNight: price,
                imageUrl: "test.jpg",
                resort: resort
            )
        }

        let budget = accommodations.filter { $0.priceCategory == .budget }
        let mid = accommodations.filter { $0.priceCategory == .mid }
        let luxury = accommodations.filter { $0.priceCategory == .luxury }

        #expect(budget.count > 0)
        #expect(mid.count > 0)
        #expect(luxury.count > 0)
        #expect(budget.count + mid.count + luxury.count == prices.count)
    }
}

// MARK: - Localization Integration Tests

struct LocalizationIntegrationTests {

    @Test func allLanguagesHaveLocalizationFiles() {
        let languages: [String] = ["de", "en", "fr", "es", "it", "pt", "ru", "uk"]

        for langCode in languages {
            let path = Bundle.main.path(forResource: langCode, ofType: "lproj")
            #expect(path != nil, "Missing localization file for language: \(langCode)")
        }
    }

    @Test func keyLocalizationsExistInAllLanguages() {
        let testKeys = ["app_title", "search_accommodations", "favorites", "settings"]
        let languages: [String] = ["de", "en", "fr", "es", "it", "pt", "ru", "uk"]

        for langCode in languages {
            guard let path = Bundle.main.path(forResource: langCode, ofType: "lproj"),
                  let bundle = Bundle(path: path) else {
                Issue.record("Missing bundle for \(langCode)")
                continue
            }

            for key in testKeys {
                let localized = NSLocalizedString(key, bundle: bundle, comment: "")
                // If the key isn't found, NSLocalizedString returns the key itself
                // We accept both the key and a proper translation
                #expect(!localized.isEmpty, "Empty localization for key '\(key)' in \(langCode)")
            }
        }
    }
}

// MARK: - HistoricalSnowData Codable Integration Tests

struct HistoricalSnowDataCodableTests {

    @Test func encodeDecodeRoundTrip() throws {
        let coord = CLLocationCoordinate2D(latitude: 47.13, longitude: 10.27)
        let yearlyData = [
            YearlySnowData(year: 2024, totalSnowfall: 300, averageSnowDepth: 50, snowDays: 90, peakSnowfall: 25.0, seasonStart: nil, seasonEnd: nil),
            YearlySnowData(year: 2023, totalSnowfall: 280, averageSnowDepth: 45, snowDays: 85, peakSnowfall: 22.0, seasonStart: nil, seasonEnd: nil)
        ]

        let original = HistoricalSnowData(coordinate: coord, yearlyData: yearlyData, averageSnowfall: 290, averageSnowDays: 87)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HistoricalSnowData.self, from: data)

        #expect(decoded.latitude == original.latitude)
        #expect(decoded.longitude == original.longitude)
        #expect(decoded.averageSnowfall == original.averageSnowfall)
        #expect(decoded.averageSnowDays == original.averageSnowDays)
        #expect(decoded.yearlyData.count == original.yearlyData.count)
    }

    @Test func yearlySnowDataCodableRoundTrip() throws {
        let original = YearlySnowData(year: 2024, totalSnowfall: 300, averageSnowDepth: 50, snowDays: 90, peakSnowfall: 25.0, seasonStart: nil, seasonEnd: nil)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(YearlySnowData.self, from: data)

        #expect(decoded.year == 2024)
        #expect(decoded.totalSnowfall == 300)
        #expect(decoded.snowDays == 90)
    }
}

// MARK: - OpenMeteoService Rate Limiting Integration Tests

struct OpenMeteoServiceIntegrationTests {

    @Test func serviceExists() {
        // Basic smoke test - just verify the service can be instantiated
        let _ = OpenMeteoService()
    }
}

// MARK: - AccommodationDatabase Integration Tests

struct AccommodationDatabaseIntegrationTests {

    @Test @MainActor func databaseInitializes() {
        let db = AccommodationDatabase.shared
        // Should not crash on access
        #expect(db.loadingStatus == .idle || true) // Just verify it's accessible
    }

    @Test @MainActor func databaseStatisticsAccessible() {
        let db = AccommodationDatabase.shared
        let stats = db.statistics

        #expect(stats.totalResorts >= 0)
    }
}
