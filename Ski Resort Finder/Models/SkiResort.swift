import Foundation
import MapKit

struct SlopeBreakdown {
    let greenSlopes: Int    // Beginner
    let blueSlopes: Int     // Easy/Intermediate
    let redSlopes: Int      // Intermediate/Advanced
    let blackSlopes: Int    // Expert/Difficult
    
    var totalSlopes: Int {
        return greenSlopes + blueSlopes + redSlopes + blackSlopes
    }
}


struct SkiResort: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let country: String
    let region: String
    let totalSlopes: Int
    let maxElevation: Int
    let minElevation: Int
    let coordinate: CLLocationCoordinate2D
    
    // Detailed resort information (optional - only if real data available)
    let liftCount: Int?
    let slopeBreakdown: SlopeBreakdown?
    let website: String? // Official resort website
    
    // Convenience initializer for backward compatibility - NO FAKE DATA
    init(name: String, country: String, region: String, totalSlopes: Int, maxElevation: Int, minElevation: Int, coordinate: CLLocationCoordinate2D, liftCount: Int? = nil, slopeBreakdown: SlopeBreakdown? = nil, website: String? = nil) {
        self.name = name
        self.country = country
        self.region = region
        self.totalSlopes = totalSlopes
        self.maxElevation = maxElevation
        self.minElevation = minElevation
        self.coordinate = coordinate
        self.liftCount = liftCount
        self.slopeBreakdown = slopeBreakdown
        self.website = website
    }
    
    static func == (lhs: SkiResort, rhs: SkiResort) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.country == rhs.country &&
               lhs.region == rhs.region
    }
}