import Foundation
import CoreLocation

/// Objektives Bewertungssystem basierend auf messbaren Kriterien
/// Folgt der NO FAKE DATA Policy - nur echte, berechenbare Bewertungen
class ObjectiveRatingCalculator {

    nonisolated(unsafe) static let shared = ObjectiveRatingCalculator()
    private init() {}
    
    /// Berechnet objektive Bewertung basierend auf messbaren Kriterien
    /// Returns nil wenn nicht genügend Daten für Bewertung vorhanden
    func calculateRating(
        distanceToLift: Int,          // Meter zum Skilift
        spaFeatures: SpaFeatureSet,   // Wellness-Ausstattung
        resort: SkiResort,            // Skigebiet-Daten
        osmData: OSMHotelData?,       // OSM-spezifische Daten
        snowData: HistoricalSnowData?, // Historische Schneedaten (5 Jahre)
        hotelName: String = "Unknown Hotel" // Hotel Name für Debug
    ) -> Double? {
        
        var totalScore: Double = 0
        var maxPossibleScore: Double = 0
        var criteriaCount = 0
        
        // 1. SKILIFT ENTFERNUNG (20% Gewichtung)
        let liftScore = calculateLiftDistanceScore(distanceToLift)
        totalScore += liftScore * 0.20
        maxPossibleScore += 1.0 * 0.20
        criteriaCount += 1
        
        // 2. SPA/WELLNESS FEATURES (18% Gewichtung)
        let spaScore = calculateSpaScore(spaFeatures)
        totalScore += spaScore * 0.18
        maxPossibleScore += 1.0 * 0.18
        criteriaCount += 1
        
        // 3. SKIGEBIET QUALITÄT (20% Gewichtung)
        let resortScore = calculateResortScore(resort)
        totalScore += resortScore * 0.20
        maxPossibleScore += 1.0 * 0.20
        criteriaCount += 1
        
        // 4. SCHNEE-HISTORIE (22% Gewichtung) - nur wenn Schneedaten verfügbar
        var snowScore: Double = 0
        if let snowData = snowData {
            snowScore = calculateSnowScore(snowData)
            totalScore += snowScore * 0.22
            maxPossibleScore += 1.0 * 0.22
            criteriaCount += 1
        }
        
        // 5. HOTEL QUALITÄT (10% Gewichtung) - nur wenn OSM Daten verfügbar
        var hotelScore: Double = 0
        if let osmData = osmData {
            hotelScore = calculateHotelQualityScore(osmData)
            totalScore += hotelScore * 0.10
            maxPossibleScore += 1.0 * 0.10
            criteriaCount += 1
        }
        
        // 6. LAGE/HÖHE (10% Gewichtung)
        let elevationScore = calculateElevationScore(resort)
        totalScore += elevationScore * 0.10
        maxPossibleScore += 1.0 * 0.10
        criteriaCount += 1
        
        // Minimum 3 Kriterien für gültige Bewertung
        guard criteriaCount >= 3 else {
            print("Nicht genügend Daten für Bewertung (\(criteriaCount) Kriterien)")
            return nil
        }
        
        // Normalisiere auf 1-5 Sterne Skala
        let normalizedScore = (totalScore / maxPossibleScore)
        let finalRating = 1.0 + (normalizedScore * 4.0) // 1-5 Sterne
        
        print("\(hotelName) - Objektive Bewertung: \(String(format: "%.3f", finalRating)) Sterne (raw: \(String(format: "%.6f", normalizedScore)))")
        print("   Distance to lift: \(distanceToLift)m -> Score: \(String(format: "%.2f", liftScore))")
        print("   Spa features: Pool=\(spaFeatures.hasPool), Spa=\(spaFeatures.hasSpa), Sauna=\(spaFeatures.hasSauna), Jacuzzi=\(spaFeatures.hasJacuzzi) -> Score: \(String(format: "%.2f", spaScore))")
        print("   Resort: \(resort.name) (\(resort.totalSlopes)km, \(resort.maxElevation)m) -> Score: \(String(format: "%.2f", resortScore))")
        if snowData != nil {
            print("   Snow: \(String(format: "%.1f", snowData?.averageSnowfall ?? 0))cm avg -> Score: \(String(format: "%.2f", snowScore))")
        }
        if let osmData = osmData {
            print("   Hotel: stars=\(osmData.stars?.description ?? "nil"), capacity=\(osmData.capacity?.description ?? "nil") -> Score: \(String(format: "%.2f", hotelScore))")
        }
        print("   Elevation: \((resort.maxElevation + resort.minElevation) / 2)m avg -> Score: \(String(format: "%.2f", elevationScore))")
        
        let roundedRating = finalRating.rounded(toPlaces: 1)
        print("Gerundet: \(String(format: "%.1f", roundedRating))")
        print("═" * 50)
        return roundedRating
    }
    
    // MARK: - Scoring Functions
    
    /// Bewertet Entfernung zum Skilift (0-1.0)
    private func calculateLiftDistanceScore(_ distance: Int) -> Double {
        switch distance {
        case 0...50:        return 1.0    // Ski-in/Ski-out (perfekt)
        case 51...200:      return 0.9    // Sehr nah
        case 201...500:     return 0.7    // Nah
        case 501...1000:    return 0.5    // Akzeptabel
        case 1001...2000:   return 0.3    // Weit
        default:            return 0.1    // Sehr weit
        }
    }
    
    /// Bewertet Spa/Wellness Features (0-1.0)
    private func calculateSpaScore(_ features: SpaFeatureSet) -> Double {
        var score: Double = 0.4 // Basis-Score für jede Unterkunft
        
        if features.hasPool { score += 0.25 }    // Pool = +25%
        if features.hasSpa { score += 0.20 }     // Spa = +20%
        if features.hasSauna { score += 0.10 }   // Sauna = +10%
        if features.hasJacuzzi { score += 0.05 } // Jacuzzi = +5%
        
        return min(score, 1.0) // Max 1.0
    }
    
    /// Bewertet Skigebiet Qualität (0-1.0)
    private func calculateResortScore(_ resort: SkiResort) -> Double {
        var score: Double = 0.3 // Basis-Score
        
        // Pistenlänge Bewertung
        let totalSlopes = resort.totalSlopes
        switch totalSlopes {
        case 0...50:        score += 0.1
        case 51...150:      score += 0.2
        case 151...300:     score += 0.3
        case 301...500:     score += 0.4
        default:            score += 0.5  // 500+ km = Premium
        }
        
        // Höhenunterschied Bewertung
        let elevation = resort.maxElevation - resort.minElevation
        switch elevation {
        case 0...500:       score += 0.05
        case 501...1000:    score += 0.1
        case 1001...1500:   score += 0.15
        default:            score += 0.2  // 1500+ m = Excellent
        }
        
        return min(score, 1.0)
    }
    
    /// Bewertet Hotel-spezifische Qualität aus OSM (0-1.0)
    private func calculateHotelQualityScore(_ osmData: OSMHotelData) -> Double {
        var score: Double = 0.3 // Basis-Score
        
        // OSM Sterne (offizielle Hotel-Klassifikation)
        if let stars = osmData.stars {
            score += Double(stars) * 0.1 // 1-5 Sterne = +10-50%
        }
        
        // Kapazität (größere Hotels oft besser ausgestattet)
        if let capacity = osmData.capacity {
            switch capacity {
            case 1...20:        score += 0.05  // Kleine Pension
            case 21...50:       score += 0.1   // Kleines Hotel
            case 51...150:      score += 0.15  // Mittelgroßes Hotel
            default:            score += 0.2   // Großes Hotel/Resort
            }
        }
        
        // Kontaktdaten Vollständigkeit (Qualitätsindikator)
        if osmData.hasEmail { score += 0.05 }
        if osmData.hasPhone { score += 0.05 }
        if osmData.hasWebsite { score += 0.05 }
        
        // Adresse Vollständigkeit
        if osmData.hasCompleteAddress { score += 0.05 }
        
        return min(score, 1.0)
    }
    
    /// Bewertet historische Schneedaten der letzten 5 Jahre (0-1.0)
    private func calculateSnowScore(_ snowData: HistoricalSnowData) -> Double {
        var score: Double = 0.2 // Basis-Score
        
        // 1. Durchschnittlicher Schneefall (50% Gewichtung)
        let avgSnowfall = snowData.averageSnowfall
        switch avgSnowfall {
        case 0...50:        score += 0.1    // Sehr wenig Schnee
        case 51...150:      score += 0.2    // Wenig Schnee
        case 151...300:     score += 0.3    // Moderate Schneemenge
        case 301...500:     score += 0.4    // Gute Schneemenge
        case 501...800:     score += 0.5    // Sehr gute Schneemenge
        default:            score += 0.5    // Exzellente Schneemenge (800cm+)
        }
        
        // 2. Schneereiche Tage (30% Gewichtung)
        let avgSnowDays = snowData.averageSnowDays
        switch avgSnowDays {
        case 0...30:        score += 0.05   // Wenige Schneetage
        case 31...60:       score += 0.1    // Moderate Schneetage
        case 61...100:      score += 0.15   // Gute Anzahl Schneetage
        case 101...150:     score += 0.25   // Viele Schneetage
        default:            score += 0.3    // Sehr viele Schneetage (150+)
        }
        
        // 3. Konsistenz über Jahre (20% Gewichtung)
        let consistencyScore = calculateSnowConsistency(snowData.yearlyData)
        score += consistencyScore * 0.2
        
        return min(score, 1.0)
    }
    
    /// Bewertet Schneekonsistenz über die Jahre (0-1.0)
    private func calculateSnowConsistency(_ yearlyData: [YearlySnowData]) -> Double {
        guard yearlyData.count >= 3 else { return 0.5 } // Nicht genügend Daten
        
        let snowfalls = yearlyData.map { $0.totalSnowfall }
        let mean = snowfalls.reduce(0, +) / Double(snowfalls.count)
        
        // Berechne Standardabweichung
        let variance = snowfalls.map { pow($0 - mean, 2) }.reduce(0, +) / Double(snowfalls.count)
        let standardDeviation = sqrt(variance)
        
        // Konsistenz Score: je geringer die Abweichung, desto besser
        let variationCoefficient = standardDeviation / mean
        
        switch variationCoefficient {
        case 0...0.15:      return 1.0   // Sehr konsistent
        case 0.16...0.25:   return 0.8   // Gut konsistent
        case 0.26...0.40:   return 0.6   // Mäßig konsistent
        case 0.41...0.60:   return 0.4   // Inkonsistent
        default:            return 0.2   // Sehr inkonsistent
        }
    }
    
    /// Bewertet Höhenlage (0-1.0)
    private func calculateElevationScore(_ resort: SkiResort) -> Double {
        let avgElevation = (resort.maxElevation + resort.minElevation) / 2
        
        switch avgElevation {
        case 0...800:       return 0.3   // Niedrige Lage
        case 801...1200:    return 0.5   // Mittlere Lage
        case 1201...1800:   return 0.7   // Gute Höhe
        case 1801...2500:   return 0.9   // Sehr gute Höhe
        default:            return 1.0   // Hochalpin (2500m+)
        }
    }
}

// MARK: - Supporting Data Structures

struct SpaFeatureSet {
    let hasPool: Bool
    let hasJacuzzi: Bool
    let hasSpa: Bool
    let hasSauna: Bool
    
    var totalFeatures: Int {
        return [hasPool, hasJacuzzi, hasSpa, hasSauna].filter { $0 }.count
    }
}

struct OSMHotelData {
    let stars: Int?           // OSM stars tag
    let capacity: Int?        // OSM capacity/beds
    let hasEmail: Bool        // Kontaktdaten verfügbar
    let hasPhone: Bool
    let hasWebsite: Bool
    let hasCompleteAddress: Bool  // Vollständige Adresse
}

// MARK: - Helper Extensions

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}