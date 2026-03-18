import Foundation
import CoreLocation

// Simple test script to check OSM accommodation data quality
class OSMDataTester {
    
    static func testAccommodationData() async {
        let overpassService = OverpassService.shared
        
        // Test with popular ski resort coordinates
        let testResorts = [
            ("St. Anton am Arlberg", CLLocationCoordinate2D(latitude: 47.1296, longitude: 10.2686)),
            ("Verbier", CLLocationCoordinate2D(latitude: 46.0960, longitude: 7.2286)),
            ("Chamonix", CLLocationCoordinate2D(latitude: 45.9237, longitude: 6.8694)),
            ("Zermatt", CLLocationCoordinate2D(latitude: 46.0207, longitude: 7.7491)),
            ("Val d'Isère", CLLocationCoordinate2D(latitude: 45.4486, longitude: 6.9786))
        ]
        
        print("Testing OSM Accommodation Data Quality")
        print("="*50)
        
        for (resortName, coordinate) in testResorts {
            print("\nTesting: \(resortName)")
            print("-" * 40)
            
            do {
                let accommodations = try await overpassService.searchAccommodations(
                    around: coordinate,
                    radius: 5000 // 5km radius
                )
                
                print("Found \(accommodations.count) accommodations")
                
                if accommodations.isEmpty {
                    print("[WARN] No accommodations found!")
                    continue
                }
                
                // Analyze data quality
                var hasEmail = 0
                var hasPhone = 0
                var hasWebsite = 0
                var hasStars = 0
                var hasAddress = 0
                
                var accommodationTypes: [String: Int] = [:]
                
                for accommodation in accommodations.prefix(10) { // Show first 10
                print("\n\(accommodation.name)")
                    print("   Type: \(accommodation.tourismType ?? "unknown")")
                    print("   Address: \(accommodation.address.isEmpty ? "Not available" : accommodation.address)")
                    print("   Email: \(accommodation.email ?? "Not available")")
                    print("   Phone: \(accommodation.phone ?? "Not available")")
                    print("   Website: \(accommodation.website ?? "Not available")")
                    print("   Stars: \(accommodation.stars?.description ?? "Not available")")
                    
                    // Count data availability
                    if accommodation.email != nil { hasEmail += 1 }
                    if accommodation.phone != nil { hasPhone += 1 }
                    if accommodation.website != nil { hasWebsite += 1 }
                    if accommodation.stars != nil { hasStars += 1 }
                    if !accommodation.address.isEmpty { hasAddress += 1 }
                    
                    // Count types
                    let type = accommodation.tourismType ?? "unknown"
                    accommodationTypes[type] = (accommodationTypes[type] ?? 0) + 1
                }
                
                // Print summary statistics
                print("\nData Quality Summary:")
                print("   Total found: \(accommodations.count)")
                print("   With email: \(hasEmail)/\(min(10, accommodations.count)) (\(hasEmail * 100 / min(10, accommodations.count))%)")
                print("   With phone: \(hasPhone)/\(min(10, accommodations.count)) (\(hasPhone * 100 / min(10, accommodations.count))%)")
                print("   With website: \(hasWebsite)/\(min(10, accommodations.count)) (\(hasWebsite * 100 / min(10, accommodations.count))%)")
                print("   With stars: \(hasStars)/\(min(10, accommodations.count)) (\(hasStars * 100 / min(10, accommodations.count))%)")
                print("   With address: \(hasAddress)/\(min(10, accommodations.count)) (\(hasAddress * 100 / min(10, accommodations.count))%)")
                
                print("\nAccommodation Types:")
                for (type, count) in accommodationTypes.sorted(by: { $0.value > $1.value }) {
                    print("   \(type): \(count)")
                }
                
            } catch {
                print("[ERROR] Error testing \(resortName): \(error)")
            }
        }
        
        print("\n" + "="*50)
        print("Test completed!")
    }
}

// Helper to repeat characters
extension String {
    static func * (string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
}