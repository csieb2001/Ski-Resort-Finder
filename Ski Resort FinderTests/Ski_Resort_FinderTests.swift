//
//  Ski_Resort_FinderTests.swift
//  Ski Resort FinderTests
//
//  Created by Christopher Siebert on 10.07.25.
//

import Testing
import CoreLocation
@testable import Ski_Resort_Finder

// MARK: - SkiResort Model Tests

struct SkiResortModelTests {

    // MARK: - Helper

    static func makeResort(
        name: String = "Test Resort",
        country: String = "Österreich",
        region: String = "Tirol",
        totalSlopes: Int = 150,
        maxElevation: Int = 2500,
        minElevation: Int = 1000,
        latitude: Double = 47.13,
        longitude: Double = 10.27,
        liftCount: Int? = nil,
        slopeBreakdown: SlopeBreakdown? = nil,
        website: String? = nil
    ) -> SkiResort {
        SkiResort(
            name: name,
            country: country,
            region: region,
            totalSlopes: totalSlopes,
            maxElevation: maxElevation,
            minElevation: minElevation,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            liftCount: liftCount,
            slopeBreakdown: slopeBreakdown,
            website: website
        )
    }

    // MARK: - Initialization Tests

    @Test func skiResortInitializesCorrectly() {
        let resort = Self.makeResort(name: "St. Anton", totalSlopes: 305, maxElevation: 2811, minElevation: 1304)

        #expect(resort.name == "St. Anton")
        #expect(resort.country == "Österreich")
        #expect(resort.region == "Tirol")
        #expect(resort.totalSlopes == 305)
        #expect(resort.maxElevation == 2811)
        #expect(resort.minElevation == 1304)
    }

    @Test func skiResortOptionalFieldsDefaultToNil() {
        let resort = Self.makeResort()

        #expect(resort.liftCount == nil)
        #expect(resort.slopeBreakdown == nil)
        #expect(resort.website == nil)
    }

    @Test func skiResortWithAllFields() {
        let breakdown = SlopeBreakdown(greenSlopes: 5, blueSlopes: 20, redSlopes: 15, blackSlopes: 10)
        let resort = Self.makeResort(
            liftCount: 88,
            slopeBreakdown: breakdown,
            website: "https://example.com"
        )

        #expect(resort.liftCount == 88)
        #expect(resort.slopeBreakdown != nil)
        #expect(resort.website == "https://example.com")
    }

    // MARK: - Stable UUID Tests

    @Test func stableUUIDIsConsistent() {
        let resort1 = Self.makeResort(name: "St. Anton", latitude: 47.1296, longitude: 10.2686)
        let resort2 = Self.makeResort(name: "St. Anton", latitude: 47.1296, longitude: 10.2686)

        #expect(resort1.id == resort2.id)
    }

    @Test func differentResortsHaveDifferentUUIDs() {
        let resort1 = Self.makeResort(name: "St. Anton")
        let resort2 = Self.makeResort(name: "Kitzbühel")

        #expect(resort1.id != resort2.id)
    }

    @Test func stableUUIDFromStringDeterministic() {
        let uuid1 = SkiResort.stableUUID(from: "test_string")
        let uuid2 = SkiResort.stableUUID(from: "test_string")

        #expect(uuid1 == uuid2)
    }

    @Test func stableUUIDFromDifferentStringsAreDifferent() {
        let uuid1 = SkiResort.stableUUID(from: "string_a")
        let uuid2 = SkiResort.stableUUID(from: "string_b")

        #expect(uuid1 != uuid2)
    }

    // MARK: - Equatable Tests

    @Test func equalResortsCompareAsEqual() {
        let resort1 = Self.makeResort(name: "St. Anton")
        let resort2 = Self.makeResort(name: "St. Anton")

        #expect(resort1 == resort2)
    }

    @Test func differentResortsAreNotEqual() {
        let resort1 = Self.makeResort(name: "St. Anton")
        let resort2 = Self.makeResort(name: "Verbier", country: "Schweiz")

        #expect(resort1 != resort2)
    }
}

// MARK: - SlopeBreakdown Tests

struct SlopeBreakdownTests {

    @Test func totalSlopesCalculation() {
        let breakdown = SlopeBreakdown(greenSlopes: 5, blueSlopes: 20, redSlopes: 15, blackSlopes: 10)
        #expect(breakdown.totalSlopes == 50)
    }

    @Test func totalSlopesWithZeroes() {
        let breakdown = SlopeBreakdown(greenSlopes: 0, blueSlopes: 0, redSlopes: 0, blackSlopes: 0)
        #expect(breakdown.totalSlopes == 0)
    }

    @Test func totalSlopesWithSingleCategory() {
        let breakdown = SlopeBreakdown(greenSlopes: 0, blueSlopes: 30, redSlopes: 0, blackSlopes: 0)
        #expect(breakdown.totalSlopes == 30)
    }
}

// MARK: - Accommodation Model Tests

struct AccommodationModelTests {

    static let testResort = SkiResortModelTests.makeResort(name: "Test Resort")

    static func makeAccommodation(
        name: String = "Test Hotel",
        distanceToLift: Int = 100,
        hasPool: Bool = false,
        hasJacuzzi: Bool = false,
        hasSpa: Bool = false,
        hasSauna: Bool = false,
        pricePerNight: Double = 150.0,
        rating: Double? = nil,
        email: String? = nil,
        phone: String? = nil,
        website: String? = nil
    ) -> Accommodation {
        Accommodation(
            name: name,
            distanceToLift: distanceToLift,
            hasPool: hasPool,
            hasJacuzzi: hasJacuzzi,
            hasSpa: hasSpa,
            hasSauna: hasSauna,
            pricePerNight: pricePerNight,
            rating: rating,
            imageUrl: "test.jpg",
            resort: testResort,
            email: email,
            phone: phone,
            website: website
        )
    }

    // MARK: - Initialization

    @Test func accommodationInitializesCorrectly() {
        let acc = Self.makeAccommodation(name: "Alpine Hotel", distanceToLift: 50, pricePerNight: 200.0)

        #expect(acc.name == "Alpine Hotel")
        #expect(acc.distanceToLift == 50)
        #expect(acc.pricePerNight == 200.0)
        #expect(acc.isRealData == true)
    }

    @Test func accommodationStableID() {
        let acc1 = Self.makeAccommodation(name: "Hotel A")
        let acc2 = Self.makeAccommodation(name: "Hotel A")

        #expect(acc1.id == acc2.id)
    }

    @Test func accommodationDifferentNamesHaveDifferentIDs() {
        let acc1 = Self.makeAccommodation(name: "Hotel A")
        let acc2 = Self.makeAccommodation(name: "Hotel B")

        #expect(acc1.id != acc2.id)
    }

    @Test func accommodationPreservesIDOnUpdate() {
        let original = Self.makeAccommodation(name: "Hotel")
        let updated = Accommodation(
            id: original.id,
            name: "Hotel",
            distanceToLift: 200,
            hasPool: true,
            hasJacuzzi: false,
            hasSpa: false,
            pricePerNight: 300.0,
            imageUrl: "test.jpg",
            resort: Self.testResort
        )

        #expect(original.id == updated.id)
    }

    // MARK: - Price Category Tests

    @Test func priceCategoryBudget() {
        let acc = Self.makeAccommodation(pricePerNight: 100.0)
        #expect(acc.priceCategory == .budget)
    }

    @Test func priceCategoryBudgetUpperBound() {
        let acc = Self.makeAccommodation(pricePerNight: 150.0)
        #expect(acc.priceCategory == .budget)
    }

    @Test func priceCategoryMid() {
        let acc = Self.makeAccommodation(pricePerNight: 200.0)
        #expect(acc.priceCategory == .mid)
    }

    @Test func priceCategoryMidUpperBound() {
        let acc = Self.makeAccommodation(pricePerNight: 300.0)
        #expect(acc.priceCategory == .mid)
    }

    @Test func priceCategoryLuxury() {
        let acc = Self.makeAccommodation(pricePerNight: 500.0)
        #expect(acc.priceCategory == .luxury)
    }

    // MARK: - Contact Info Tests

    @Test func hasContactInfoWithEmail() {
        let acc = Self.makeAccommodation(email: "info@hotel.com")
        #expect(acc.hasContactInfo == true)
    }

    @Test func hasContactInfoWithPhone() {
        let acc = Self.makeAccommodation(phone: "+43 1234")
        #expect(acc.hasContactInfo == true)
    }

    @Test func hasContactInfoWithWebsite() {
        let acc = Self.makeAccommodation(website: "https://hotel.com")
        #expect(acc.hasContactInfo == true)
    }

    @Test func noContactInfo() {
        let acc = Self.makeAccommodation()
        #expect(acc.hasContactInfo == false)
    }

    @Test func preferredContactMethodIsEmail() {
        let acc = Self.makeAccommodation(email: "info@hotel.com", phone: "+43 1234", website: "https://hotel.com")
        if case .email(let email) = acc.preferredContactMethod {
            #expect(email == "info@hotel.com")
        } else {
            Issue.record("Expected email as preferred contact method")
        }
    }

    @Test func preferredContactMethodFallsToPhone() {
        let acc = Self.makeAccommodation(phone: "+43 1234", website: "https://hotel.com")
        if case .phone(let phone) = acc.preferredContactMethod {
            #expect(phone == "+43 1234")
        } else {
            Issue.record("Expected phone as preferred contact method")
        }
    }

    @Test func availableContactMethodsCount() {
        let acc = Self.makeAccommodation(email: "info@hotel.com", phone: "+43 1234", website: "https://hotel.com")
        #expect(acc.availableContactMethods.count == 3)
    }

    // MARK: - Spa Features Tests

    @Test func hasSpaFeaturesWithPool() {
        let acc = Self.makeAccommodation(hasPool: true)
        #expect(acc.hasSpaFeatures == true)
    }

    @Test func hasSpaFeaturesWithNothing() {
        let acc = Self.makeAccommodation()
        #expect(acc.hasSpaFeatures == false)
    }

    @Test func hasSpaFeaturesWithAll() {
        let acc = Self.makeAccommodation(hasPool: true, hasJacuzzi: true, hasSpa: true, hasSauna: true)
        #expect(acc.hasSpaFeatures == true)
    }

    // MARK: - Spa Filter Tests

    @Test func matchesSpaFiltersEmptyFilters() {
        let acc = Self.makeAccommodation()
        #expect(acc.matchesSpaFilters([]) == true)
    }

    @Test func matchesSpaFiltersPoolRequired() {
        let accWithPool = Self.makeAccommodation(hasPool: true)
        let accWithoutPool = Self.makeAccommodation(hasPool: false)

        #expect(accWithPool.matchesSpaFilters([.pool]) == true)
        #expect(accWithoutPool.matchesSpaFilters([.pool]) == false)
    }

    @Test func matchesSpaFiltersMultipleRequired() {
        let accAll = Self.makeAccommodation(hasPool: true, hasJacuzzi: true, hasSpa: true)
        let accPartial = Self.makeAccommodation(hasPool: true, hasJacuzzi: false, hasSpa: true)

        #expect(accAll.matchesSpaFilters([.pool, .jacuzzi]) == true)
        #expect(accPartial.matchesSpaFilters([.pool, .jacuzzi]) == false)
    }

    @Test func matchesSpaFiltersNoSpaFeatures() {
        let accWithSpa = Self.makeAccommodation(hasPool: true)
        let accWithoutSpa = Self.makeAccommodation()

        #expect(accWithSpa.matchesSpaFilters([.noSpaFeatures]) == false)
        #expect(accWithoutSpa.matchesSpaFilters([.noSpaFeatures]) == true)
    }

    // MARK: - Image URL Tests

    @Test func imageUrlsFallsBackToSingleUrl() {
        let acc = Accommodation(
            name: "Hotel",
            distanceToLift: 100,
            hasPool: false,
            hasJacuzzi: false,
            hasSpa: false,
            pricePerNight: 100.0,
            imageUrl: "main.jpg",
            imageUrls: [],
            resort: Self.testResort
        )

        #expect(acc.imageUrls == ["main.jpg"])
    }

    // MARK: - Equatable Tests

    @Test func equalAccommodationsCompareAsEqual() {
        let acc1 = Self.makeAccommodation(name: "Hotel A")
        let acc2 = Self.makeAccommodation(name: "Hotel A")

        #expect(acc1 == acc2)
    }

    @Test func differentAccommodationsAreNotEqual() {
        let acc1 = Self.makeAccommodation(name: "Hotel A")
        let acc2 = Self.makeAccommodation(name: "Hotel B")

        #expect(acc1 != acc2)
    }
}

// MARK: - Weather Data Model Tests

struct WeatherDataModelTests {

    @Test func historicalSnowDataInitialization() {
        let coord = CLLocationCoordinate2D(latitude: 47.13, longitude: 10.27)
        let yearlyData = [
            YearlySnowData(year: 2024, totalSnowfall: 300, averageSnowDepth: 50, snowDays: 90, peakSnowfall: 25.0, seasonStart: nil, seasonEnd: nil)
        ]

        let data = HistoricalSnowData(coordinate: coord, yearlyData: yearlyData, averageSnowfall: 300, averageSnowDays: 90)

        #expect(data.latitude == 47.13)
        #expect(data.longitude == 10.27)
        #expect(data.averageSnowfall == 300)
        #expect(data.averageSnowDays == 90)
        #expect(data.yearlyData.count == 1)
    }

    @Test func historicalSnowDataCoordinate() {
        let coord = CLLocationCoordinate2D(latitude: 47.0, longitude: 10.0)
        let data = HistoricalSnowData(coordinate: coord, yearlyData: [], averageSnowfall: 0, averageSnowDays: 0)

        #expect(data.coordinate.latitude == 47.0)
        #expect(data.coordinate.longitude == 10.0)
    }

    @Test func yearlySnowDataSeasonLength() {
        let start = Calendar.current.date(from: DateComponents(year: 2024, month: 11, day: 1))!
        let end = Calendar.current.date(from: DateComponents(year: 2025, month: 4, day: 15))!

        let data = YearlySnowData(year: 2024, totalSnowfall: 300, averageSnowDepth: 50, snowDays: 90, peakSnowfall: 25.0, seasonStart: start, seasonEnd: end)

        #expect(data.seasonLength != nil)
        #expect(data.seasonLength! > 150) // ~165 days
    }

    @Test func yearlySnowDataSeasonLengthNilWithoutDates() {
        let data = YearlySnowData(year: 2024, totalSnowfall: 300, averageSnowDepth: 50, snowDays: 90, peakSnowfall: 25.0, seasonStart: nil, seasonEnd: nil)

        #expect(data.seasonLength == nil)
    }

    @Test func yearlySnowDataFormattedSeason() {
        let data = YearlySnowData(year: 2024, totalSnowfall: 300, averageSnowDepth: 50, snowDays: 90, peakSnowfall: 25.0, seasonStart: nil, seasonEnd: nil)

        #expect(data.formattedSeason == "Keine Daten")
    }

    @Test func weatherDataManualInit() {
        let main = WeatherData.MainWeather(
            temp: -5.0,
            feelsLike: -10.0,
            tempMin: -8.0,
            tempMax: -2.0,
            pressure: 1013,
            humidity: 80
        )

        let weather = [WeatherData.Weather(id: 71, main: "Snow", description: "Leichter Schnee", icon: "13d")]
        let wind = WeatherData.Wind(speed: 15.0, deg: 270)

        let weatherData = WeatherData(
            main: main,
            weather: weather,
            wind: wind,
            snow: nil,
            name: "St. Anton",
            isRealData: true
        )

        #expect(weatherData.main.temp == -5.0)
        #expect(weatherData.main.feelsLike == -10.0)
        #expect(weatherData.name == "St. Anton")
        #expect(weatherData.isRealData == true)
        #expect(weatherData.weather.count == 1)
        #expect(weatherData.weather.first?.main == "Snow")
        #expect(weatherData.wind?.speed == 15.0)
        #expect(weatherData.snow == nil)
    }

    @Test func weatherDataWithSnow() {
        let main = WeatherData.MainWeather(temp: -3.0, feelsLike: -7.0, tempMin: -5.0, tempMax: -1.0, pressure: 1010, humidity: 90)
        let snow = WeatherData.Snow(oneHour: 2.5, threeHours: 5.0)

        let weatherData = WeatherData(
            main: main,
            weather: [],
            wind: nil,
            snow: snow,
            name: "Test",
            isRealData: true
        )

        #expect(weatherData.snow?.oneHour == 2.5)
        #expect(weatherData.snow?.threeHours == 5.0)
    }
}

// MARK: - Email Validator Tests

struct EmailValidatorTests {

    // MARK: - Format Validation

    @Test func validEmailFormats() {
        #expect(EmailValidator.isValidFormat("info@hotel.com") == true)
        #expect(EmailValidator.isValidFormat("reception@alpine-lodge.at") == true)
        #expect(EmailValidator.isValidFormat("booking@hotel-arlberg.ch") == true)
        #expect(EmailValidator.isValidFormat("user.name@domain.de") == true)
    }

    @Test func invalidEmailFormats() {
        #expect(EmailValidator.isValidFormat("") == false)
        #expect(EmailValidator.isValidFormat("noemail") == false)
        #expect(EmailValidator.isValidFormat("@domain.com") == false)
        #expect(EmailValidator.isValidFormat("user@") == false)
        #expect(EmailValidator.isValidFormat("user@.com") == false)
        #expect(EmailValidator.isValidFormat("user @domain.com") == false)
    }

    // MARK: - Comprehensive Validation

    @Test func validHotelEmailHighConfidence() {
        let result = EmailValidator.validateEmail("info@hotel-arlberg.at")

        #expect(result.isValid == true)
        #expect(result.confidence > 0.5)
    }

    @Test func suspiciousEmailLowConfidence() {
        let result = EmailValidator.validateEmail("test@example.com")

        // Contains "test" pattern and "example.com" domain
        #expect(result.confidence < 0.5)
    }

    @Test func personalEmailLowerConfidence() {
        let result = EmailValidator.validateEmail("user@gmail.com")

        #expect(result.isValid == true)
        #expect(result.confidence < 0.8) // Reduced for personal domain
    }

    @Test func invalidEmailValidation() {
        let result = EmailValidator.validateEmail("not-an-email")

        #expect(result.isValid == false)
        #expect(result.confidence == 0.0)
    }

    @Test func qualityDescriptions() {
        let excellent = EmailValidationResult(isValid: true, confidence: 0.95, issues: [])
        let good = EmailValidationResult(isValid: true, confidence: 0.8, issues: [])
        let fair = EmailValidationResult(isValid: true, confidence: 0.6, issues: [])
        let poor = EmailValidationResult(isValid: true, confidence: 0.4, issues: [])
        let invalid = EmailValidationResult(isValid: false, confidence: 0.1, issues: [])

        #expect(excellent.qualityDescription == "Excellent")
        #expect(good.qualityDescription == "Good")
        #expect(fair.qualityDescription == "Fair")
        #expect(poor.qualityDescription == "Poor")
        #expect(invalid.qualityDescription == "Invalid")
    }

    // MARK: - Normalization

    @Test func emailNormalization() {
        #expect(EmailValidator.normalizeEmail("  Info@Hotel.COM  ") == "info@hotel.com")
        #expect(EmailValidator.normalizeEmail("USER@Domain.De") == "user@domain.de")
    }

    // MARK: - Domain Extraction

    @Test func domainExtraction() {
        #expect(EmailValidator.extractDomain(from: "info@hotel.at") == "hotel.at")
        #expect(EmailValidator.extractDomain(from: "noemail") == nil)
    }

    // MARK: - Hotel Domain Detection

    @Test func hotelDomainDetection() {
        #expect(EmailValidator.isHotelDomain("info@hotel-arlberg.at") == true)
        #expect(EmailValidator.isHotelDomain("user@gmail.com") == false)
        #expect(EmailValidator.isHotelDomain("info@web.de") == false)
        #expect(EmailValidator.isHotelDomain("reception@alpine-lodge.ch") == true)
    }

    // MARK: - Bulk Validation

    @Test func bulkValidationSortsByConfidence() {
        let emails = [
            "info@hotel-arlberg.at",
            "test@example.com",
            "reception@alpine-lodge.ch"
        ]

        let ranked = EmailValidator.validateAndRankEmails(emails)

        // Should be sorted by confidence (highest first)
        if ranked.count >= 2 {
            #expect(ranked[0].qualityScore >= ranked[1].qualityScore)
        }
    }

    @Test func bulkValidationFiltersInvalid() {
        let emails = ["valid@hotel.com", "not-an-email", "another@resort.de"]
        let ranked = EmailValidator.validateAndRankEmails(emails)

        // "not-an-email" should be filtered out
        #expect(ranked.count == 2)
    }
}

// MARK: - ObjectiveRatingCalculator Tests

struct ObjectiveRatingCalculatorTests {

    let calculator = ObjectiveRatingCalculator.shared
    let testResort = SkiResortModelTests.makeResort(
        name: "Test Resort",
        totalSlopes: 300,
        maxElevation: 2800,
        minElevation: 1300
    )

    // MARK: - Rating Calculation

    @Test func ratingWithMinimumCriteria() {
        let spa = SpaFeatureSet(hasPool: true, hasJacuzzi: false, hasSpa: false, hasSauna: false)

        let rating = calculator.calculateRating(
            distanceToLift: 100,
            spaFeatures: spa,
            resort: testResort,
            osmData: nil,
            snowData: nil
        )

        // Should return a value with at least 3 criteria (lift, spa, resort + elevation)
        #expect(rating != nil)
        #expect(rating! >= 1.0)
        #expect(rating! <= 5.0)
    }

    @Test func ratingWithAllCriteria() {
        let spa = SpaFeatureSet(hasPool: true, hasJacuzzi: true, hasSpa: true, hasSauna: true)
        let osmData = OSMHotelData(stars: 5, capacity: 100, hasEmail: true, hasPhone: true, hasWebsite: true, hasCompleteAddress: true)
        let snowData = HistoricalSnowData(
            coordinate: CLLocationCoordinate2D(latitude: 47.0, longitude: 10.0),
            yearlyData: [
                YearlySnowData(year: 2024, totalSnowfall: 500, averageSnowDepth: 80, snowDays: 120, peakSnowfall: 40, seasonStart: nil, seasonEnd: nil),
                YearlySnowData(year: 2023, totalSnowfall: 480, averageSnowDepth: 75, snowDays: 115, peakSnowfall: 38, seasonStart: nil, seasonEnd: nil),
                YearlySnowData(year: 2022, totalSnowfall: 520, averageSnowDepth: 85, snowDays: 125, peakSnowfall: 42, seasonStart: nil, seasonEnd: nil)
            ],
            averageSnowfall: 500,
            averageSnowDays: 120
        )

        let rating = calculator.calculateRating(
            distanceToLift: 0,
            spaFeatures: spa,
            resort: testResort,
            osmData: osmData,
            snowData: snowData
        )

        #expect(rating != nil)
        #expect(rating! >= 3.0) // Premium resort should score high
        #expect(rating! <= 5.0)
    }

    @Test func skiInSkiOutScoresHigherThanDistant() {
        let spa = SpaFeatureSet(hasPool: false, hasJacuzzi: false, hasSpa: false, hasSauna: false)

        let closeRating = calculator.calculateRating(
            distanceToLift: 0,
            spaFeatures: spa,
            resort: testResort,
            osmData: nil,
            snowData: nil
        )

        let farRating = calculator.calculateRating(
            distanceToLift: 5000,
            spaFeatures: spa,
            resort: testResort,
            osmData: nil,
            snowData: nil
        )

        #expect(closeRating != nil)
        #expect(farRating != nil)
        #expect(closeRating! > farRating!)
    }

    @Test func moreSpaFeaturesScoreHigher() {
        let noSpa = SpaFeatureSet(hasPool: false, hasJacuzzi: false, hasSpa: false, hasSauna: false)
        let fullSpa = SpaFeatureSet(hasPool: true, hasJacuzzi: true, hasSpa: true, hasSauna: true)

        let noSpaRating = calculator.calculateRating(
            distanceToLift: 100,
            spaFeatures: noSpa,
            resort: testResort,
            osmData: nil,
            snowData: nil
        )

        let fullSpaRating = calculator.calculateRating(
            distanceToLift: 100,
            spaFeatures: fullSpa,
            resort: testResort,
            osmData: nil,
            snowData: nil
        )

        #expect(noSpaRating != nil)
        #expect(fullSpaRating != nil)
        #expect(fullSpaRating! > noSpaRating!)
    }

    @Test func ratingAlwaysInValidRange() {
        let spa = SpaFeatureSet(hasPool: true, hasJacuzzi: true, hasSpa: true, hasSauna: true)

        // Test with extreme values
        let extremeResort = SkiResortModelTests.makeResort(totalSlopes: 1000, maxElevation: 4000, minElevation: 500)

        let rating = calculator.calculateRating(
            distanceToLift: 0,
            spaFeatures: spa,
            resort: extremeResort,
            osmData: nil,
            snowData: nil
        )

        #expect(rating != nil)
        #expect(rating! >= 1.0)
        #expect(rating! <= 5.0)
    }
}

// MARK: - SpaFeatureSet Tests

struct SpaFeatureSetTests {

    @Test func totalFeaturesNone() {
        let features = SpaFeatureSet(hasPool: false, hasJacuzzi: false, hasSpa: false, hasSauna: false)
        #expect(features.totalFeatures == 0)
    }

    @Test func totalFeaturesAll() {
        let features = SpaFeatureSet(hasPool: true, hasJacuzzi: true, hasSpa: true, hasSauna: true)
        #expect(features.totalFeatures == 4)
    }

    @Test func totalFeaturesSome() {
        let features = SpaFeatureSet(hasPool: true, hasJacuzzi: false, hasSpa: true, hasSauna: false)
        #expect(features.totalFeatures == 2)
    }
}

// MARK: - Double Rounding Extension Tests

struct DoubleRoundingTests {

    @Test func roundToOnePlaces() {
        #expect(3.456.rounded(toPlaces: 1) == 3.5)
        #expect(3.444.rounded(toPlaces: 1) == 3.4)
        #expect(3.0.rounded(toPlaces: 1) == 3.0)
    }

    @Test func roundToTwoPlaces() {
        #expect(3.456.rounded(toPlaces: 2) == 3.46)
        #expect(3.454.rounded(toPlaces: 2) == 3.45)
    }

    @Test func roundToZeroPlaces() {
        #expect(3.6.rounded(toPlaces: 0) == 4.0)
        #expect(3.4.rounded(toPlaces: 0) == 3.0)
    }
}

// MARK: - ContactMethod Tests

struct ContactMethodTests {

    @Test func contactMethodIdentifiers() {
        let email = ContactMethod.email("info@hotel.com")
        let phone = ContactMethod.phone("+43 1234")
        let website = ContactMethod.website("https://hotel.com")

        #expect(email.id.hasPrefix("email_"))
        #expect(phone.id.hasPrefix("phone_"))
        #expect(website.id.hasPrefix("website_"))
    }

    @Test func contactMethodValues() {
        let email = ContactMethod.email("info@hotel.com")
        let phone = ContactMethod.phone("+43 1234")
        let website = ContactMethod.website("https://hotel.com")

        #expect(email.value == "info@hotel.com")
        #expect(phone.value == "+43 1234")
        #expect(website.value == "https://hotel.com")
    }

    @Test func contactMethodIcons() {
        let email = ContactMethod.email("test")
        let phone = ContactMethod.phone("test")
        let website = ContactMethod.website("test")

        #expect(email.iconName == "envelope.fill")
        #expect(phone.iconName == "phone.fill")
        #expect(website.iconName == "globe")
    }
}

// MARK: - SkiResortDatabase Tests

struct SkiResortDatabaseTests {

    @Test func databaseHasResorts() {
        let db = SkiResortDatabase.shared
        #expect(!db.allSkiResorts.isEmpty)
    }

    @Test func databaseContainsKnownResorts() {
        let db = SkiResortDatabase.shared
        let resortNames = db.allSkiResorts.map { $0.name }

        #expect(resortNames.contains("St. Anton am Arlberg"))
        #expect(resortNames.contains("Kitzbühel"))
    }

    @Test func databaseResortsHaveValidCoordinates() {
        let db = SkiResortDatabase.shared

        for resort in db.allSkiResorts {
            #expect(resort.coordinate.latitude >= -90 && resort.coordinate.latitude <= 90,
                    "Invalid latitude for \(resort.name)")
            #expect(resort.coordinate.longitude >= -180 && resort.coordinate.longitude <= 180,
                    "Invalid longitude for \(resort.name)")
        }
    }

    @Test func databaseResortsHaveValidElevation() {
        let db = SkiResortDatabase.shared

        for resort in db.allSkiResorts {
            #expect(resort.maxElevation > resort.minElevation,
                    "Max elevation should be > min for \(resort.name)")
            #expect(resort.maxElevation > 0,
                    "Max elevation should be > 0 for \(resort.name)")
            #expect(resort.totalSlopes > 0,
                    "Total slopes should be > 0 for \(resort.name)")
        }
    }

    @Test func databaseSearchByName() {
        let db = SkiResortDatabase.shared
        let results = db.searchResorts(query: "Anton")

        #expect(!results.isEmpty)
        #expect(results.contains(where: { $0.name.contains("Anton") }))
    }

    @Test func databaseSearchByCountry() {
        let db = SkiResortDatabase.shared
        let results = db.searchResorts(query: "Schweiz")

        #expect(!results.isEmpty)
        #expect(results.allSatisfy { $0.country == "Schweiz" || $0.name.contains("Schweiz") || $0.region.contains("Schweiz") })
    }

    @Test func databaseSearchEmptyQuery() {
        let db = SkiResortDatabase.shared
        let results = db.searchResorts(query: "")

        // Empty query should return all resorts
        #expect(results.count == db.allSkiResorts.count)
    }

    @Test func databaseSearchNoResults() {
        let db = SkiResortDatabase.shared
        let results = db.searchResorts(query: "XYZNONEXISTENT12345")

        #expect(results.isEmpty)
    }

    @Test func databaseResortsHaveUniqueIDs() {
        let db = SkiResortDatabase.shared
        let ids = db.allSkiResorts.map { $0.id }
        let uniqueIDs = Set(ids)

        #expect(ids.count == uniqueIDs.count, "Database contains duplicate resort IDs")
    }

    @Test func databaseResortsHaveNonEmptyNames() {
        let db = SkiResortDatabase.shared

        for resort in db.allSkiResorts {
            #expect(!resort.name.isEmpty, "Resort has empty name")
            #expect(!resort.country.isEmpty, "Resort \(resort.name) has empty country")
            #expect(!resort.region.isEmpty, "Resort \(resort.name) has empty region")
        }
    }
}

// MARK: - SearchSettings Tests

struct SearchSettingsTests {

    @Test func defaultSearchRadius() {
        let settings = SearchSettings.shared
        #expect(settings.searchRadius >= 1.0)
        #expect(settings.searchRadius <= 20.0)
    }

    @Test func searchRadiusInMeters() {
        let settings = SearchSettings.shared
        let expectedMeters = Int(settings.searchRadius * 1000)
        #expect(settings.searchRadiusInMeters == expectedMeters)
    }

    @Test func availableRadiiAreSorted() {
        let radii = SearchSettings.availableRadii

        for i in 0..<radii.count - 1 {
            #expect(radii[i] < radii[i + 1], "Available radii should be sorted ascending")
        }
    }

    @Test func availableRadiiRange() {
        let radii = SearchSettings.availableRadii

        #expect(radii.first! >= 1.0)
        #expect(radii.last! <= 20.0)
    }
}

// MARK: - LocalizationService Tests

struct LocalizationServiceTests {

    @Test func supportedLanguagesExist() {
        let languages = LocalizationService.SupportedLanguage.allCases

        #expect(languages.count >= 8) // de, en, fr, es, it, pt, ru, uk + system
    }

    @Test func languageCodesAreValid() {
        let expected: [String: String] = [
            "de": "de",
            "en": "en",
            "fr": "fr",
            "es": "es",
            "it": "it",
            "pt": "pt",
            "ru": "ru",
            "uk": "uk"
        ]

        for (rawValue, expectedCode) in expected {
            if let lang = LocalizationService.SupportedLanguage(rawValue: rawValue) {
                #expect(lang.code == expectedCode, "Language \(rawValue) should have code \(expectedCode)")
            }
        }
    }

    @Test func languageDisplayNamesAreNonEmpty() {
        for language in LocalizationService.SupportedLanguage.allCases {
            #expect(!language.displayName.isEmpty, "Language \(language.rawValue) has empty display name")
        }
    }

    @Test func localizationServiceReturnsSomething() {
        let service = LocalizationService.shared
        let result = service.localized("app_title")

        // Should return either the localized string or the key itself
        #expect(!result.isEmpty)
    }

    @Test func stringLocalizedExtension() {
        let result = "app_title".localized

        #expect(!result.isEmpty)
    }

    @Test func formatDateReturnsNonEmpty() {
        let service = LocalizationService.shared
        let result = service.formatDate(Date())

        #expect(!result.isEmpty)
    }

    @Test func formatNumberReturnsNonEmpty() {
        let service = LocalizationService.shared
        let result = service.formatNumber(1234.56)

        #expect(!result.isEmpty)
    }

    @Test func formatCurrencyReturnsNonEmpty() {
        let service = LocalizationService.shared
        let result = service.formatCurrency(99.99)

        #expect(!result.isEmpty)
    }
}

// MARK: - AppVersion Tests

struct AppVersionTests {

    @Test func currentVersionIsNonEmpty() {
        #expect(!AppVersion.currentVersion.isEmpty)
    }

    @Test func fullVersionInfoIsNonEmpty() {
        #expect(!AppVersion.fullVersionInfo.isEmpty)
    }

    @Test func buildDateIsNonEmpty() {
        #expect(!AppVersion.buildDate.isEmpty)
    }

    @Test func debugInfoContainsVersion() {
        let debugInfo = AppVersion.debugInfo

        #expect(debugInfo.contains("Version:"))
        #expect(debugInfo.contains("Build Date:"))
        #expect(debugInfo.contains("Bundle ID:"))
    }
}
