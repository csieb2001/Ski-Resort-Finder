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
    let id: UUID
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
        // Generate stable, deterministic UUID based on resort properties
        let stableString = "\(name)_\(country)_\(region)_\(String(format: "%.4f", coordinate.latitude))_\(String(format: "%.4f", coordinate.longitude))"
        self.id = SkiResort.stableUUID(from: stableString)
        
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
    
    /// Generates a stable UUID based on a string input
    /// Same input will always produce the same UUID across app sessions
    static func stableUUID(from string: String) -> UUID {
        // Use a simple hash-based approach to generate deterministic UUID
        let hasher = string.hash
        
        // Create UUID bytes from hash
        var bytes: [UInt8] = []
        for i in 0..<16 {
            bytes.append(UInt8((hasher >> (i * 2)) & 0xFF))
        }
        
        // Set version (4) and variant bits to make it a valid UUID
        bytes[6] = (bytes[6] & 0x0F) | 0x40 // Version 4
        bytes[8] = (bytes[8] & 0x3F) | 0x80 // Variant bits
        
        let uuidString = String(format: "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
                               bytes[0], bytes[1], bytes[2], bytes[3],
                               bytes[4], bytes[5], bytes[6], bytes[7],
                               bytes[8], bytes[9], bytes[10], bytes[11],
                               bytes[12], bytes[13], bytes[14], bytes[15])
        
        return UUID(uuidString: uuidString) ?? UUID()
    }
}