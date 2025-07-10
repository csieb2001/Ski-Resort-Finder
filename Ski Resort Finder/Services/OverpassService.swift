import Foundation
import CoreLocation

class OverpassService: ObservableObject {
    static let shared = OverpassService()
    
    private let overpassAPIURL = "https://overpass-api.de/api/interpreter"
    private let session = URLSession.shared
    
    private init() {}
    
    func searchAccommodations(
        around coordinate: CLLocationCoordinate2D,
        radius: Int = 5000
    ) async throws -> [OverpassAccommodation] {
        print("🌍 OverpassService: Starting search at \(coordinate.latitude), \(coordinate.longitude) with radius \(radius)m")
        
        let query = buildOverpassQuery(coordinate: coordinate, radius: radius)
        print("📝 OverpassService: Built query: \(query.prefix(200))...")
        
        var request = URLRequest(url: URL(string: overpassAPIURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "data=\(query)".data(using: .utf8)
        
        print("🌐 OverpassService: Sending request to Overpass API...")
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ OverpassService: Invalid response type")
            throw OverpassError.requestFailed
        }
        
        print("📡 OverpassService: Received response with status code \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ OverpassService: HTTP error \(httpResponse.statusCode)")
            if let errorData = String(data: data, encoding: .utf8) {
                print("❌ OverpassService: Error response: \(errorData.prefix(500))")
            }
            throw OverpassError.requestFailed
        }
        
        print("✅ OverpassService: Successfully received \(data.count) bytes of data")
        
        do {
            let overpassResponse = try JSONDecoder().decode(OverpassResponse.self, from: data)
            print("🏨 OverpassService: Decoded \(overpassResponse.elements.count) elements from API")
            
            let accommodations = parseAccommodations(from: overpassResponse.elements)
            print("✅ OverpassService: Parsed \(accommodations.count) valid accommodations")
            
            return accommodations
        } catch {
            print("❌ OverpassService: JSON decoding failed: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("❌ OverpassService: Raw JSON: \(jsonString.prefix(1000))")
            }
            throw error
        }
    }
    
    private func buildOverpassQuery(coordinate: CLLocationCoordinate2D, radius: Int) -> String {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        return """
        [out:json][timeout:25];
        (
          node["tourism"~"^(hotel|guest_house|hostel|motel|resort|apartment|chalet)$"](around:\(radius),\(lat),\(lon));
          way["tourism"~"^(hotel|guest_house|hostel|motel|resort|apartment|chalet)$"](around:\(radius),\(lat),\(lon));
          relation["tourism"~"^(hotel|guest_house|hostel|motel|resort|apartment|chalet)$"](around:\(radius),\(lat),\(lon));
        );
        out geom;
        """.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
    
    private func parseAccommodations(from elements: [OverpassElement]) -> [OverpassAccommodation] {
        return elements.compactMap { element in
            guard !element.name.isEmpty,
                  element.isAccommodation,
                  let coordinate = getCoordinate(from: element) else {
                return nil
            }
            
            return OverpassAccommodation(
                id: "\(element.id)",
                name: element.name,
                coordinate: coordinate,
                phone: element.phone,
                email: extractEmail(from: element),
                website: element.website,
                tourismType: element.tourism,
                address: buildAddress(from: element),
                stars: parseStars(from: element),
                capacity: parseCapacity(from: element),
                hasPool: parseWellnessFeature("pool", from: element),
                hasJacuzzi: parseWellnessFeature("jacuzzi", from: element),
                hasSpa: parseWellnessFeature("spa", from: element),
                hasSauna: parseWellnessFeature("sauna", from: element)
            )
        }
    }
    
    private func extractEmail(from element: OverpassElement) -> String? {
        guard let tags = element.tags else { return nil }
        
        // Check multiple possible email fields in OpenStreetMap
        let emailFields = [
            "email",                    // Standard email field
            "contact:email",           // Contact namespace
            "email:booking",           // Booking specific
            "email:reservation",       // Reservation specific  
            "reservation:email",       // Alternative reservation
            "contact:reservation",     // Contact reservation
            "booking:email",           // Alternative booking
            "info:email",             // Info email
            "reception:email",        // Reception email
            "hotel:email",            // Hotel namespace
            "guest:email",            // Guest services
            "service:email"           // Service email
        ]
        
        for field in emailFields {
            if let email = tags[field], !email.isEmpty {
                print("📧 Found email in OSM field '\(field)': \(email)")
                return email
            }
        }
        
        return nil
    }
    
    private func getCoordinate(from element: OverpassElement) -> CLLocationCoordinate2D? {
        if let lat = element.lat, let lon = element.lon {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        
        if let geometry = element.geometry?.first {
            return CLLocationCoordinate2D(latitude: geometry.lat, longitude: geometry.lon)
        }
        
        return nil
    }
    
    private func buildAddress(from element: OverpassElement) -> String {
        guard let tags = element.tags else { return "" }
        
        var addressParts: [String] = []
        
        if let street = tags["addr:street"], let houseNumber = tags["addr:housenumber"] {
            addressParts.append("\(street) \(houseNumber)")
        } else if let street = tags["addr:street"] {
            addressParts.append(street)
        }
        
        if let postcode = tags["addr:postcode"], let city = tags["addr:city"] {
            addressParts.append("\(postcode) \(city)")
        } else if let city = tags["addr:city"] {
            addressParts.append(city)
        }
        
        if let country = tags["addr:country"] {
            addressParts.append(country)
        }
        
        return addressParts.joined(separator: ", ")
    }
    
    private func parseStars(from element: OverpassElement) -> Int? {
        if let starsString = element.stars {
            return Int(starsString)
        }
        return nil
    }
    
    private func parseCapacity(from element: OverpassElement) -> Int? {
        guard let tags = element.tags else { return nil }
        
        if let capacityString = tags["capacity"] {
            return Int(capacityString)
        }
        if let bedsString = tags["beds"] {
            return Int(bedsString)
        }
        return nil
    }
    
    // MARK: - Wellness Feature Detection
    
    /// Parse wellness features from OpenStreetMap tags
    private func parseWellnessFeature(_ featureType: String, from element: OverpassElement) -> Bool {
        guard let tags = element.tags else { 
            // Try heuristic detection from name if no tags
            return detectWellnessFeatureFromName(featureType, element: element)
        }
        
        // Debug logging to see what tags we're receiving
        print("🏨 Checking wellness feature '\(featureType)' for '\(element.name)'")
        print("📋 Available tags: \(tags.keys.sorted())")
        if let facilities = tags["facilities"] {
            print("🎯 Facilities tag: '\(facilities)'")
        }
        
        let hasFeature: Bool
        
        switch featureType.lowercased() {
        case "pool":
            // Check for swimming pool tags based on OSM wiki documentation
            hasFeature = tags["swimming_pool"] == "yes" ||
                   tags["swimming_pool"] == "indoor" ||
                   tags["swimming_pool"] == "outdoor" ||
                   tags["swimming_pool"] == "inground" ||
                   tags["leisure"] == "swimming_pool" ||  // Separate pool entity
                   tags["amenity"] == "swimming_pool" ||   // Less common but still used
                   tags["sport"] == "swimming" ||
                   // Hotel-specific amenity keys (common in some regions)
                   tags["amenity:swimming_pool"] == "yes" ||
                   tags["hotel:pool"] == "yes" ||
                   tags["facilities"] != nil && tags["facilities"]!.lowercased().contains("pool")
                   
        case "jacuzzi":
            // Check for hot tub/jacuzzi tags
            hasFeature = tags["swimming_pool"] == "hot_tub" ||  // Proper OSM tagging
                   tags["swimming_pool"] == "spa" ||       // Spa pools with jets
                   tags["amenity"] == "hot_tub" ||
                   tags["leisure"] == "hot_tub" ||
                   tags["jacuzzi"] == "yes" ||
                   tags["hot_tub"] == "yes" ||
                   tags["whirlpool"] == "yes" ||
                   // Hotel-specific amenity keys
                   tags["amenity:hot_tub"] == "yes" ||
                   tags["hotel:jacuzzi"] == "yes" ||
                   tags["facilities"] != nil && (tags["facilities"]!.lowercased().contains("jacuzzi") || 
                                                tags["facilities"]!.lowercased().contains("hot_tub"))
                   
        case "spa":
            // Check for spa-related tags (note: amenity=spa is deprecated)
            hasFeature = tags["shop"] == "beauty" && tags["beauty"] == "spa" ||  // New standard
                   tags["amenity"] == "public_bath" ||      // Thermal spas
                   tags["leisure"] == "spa" ||              // Still used
                   tags["tourism"] == "spa_resort" ||       // Full spa resorts
                   tags["amenity"] == "spa" ||              // Deprecated but still found
                   tags["spa"] == "yes" ||
                   tags["wellness"] == "yes" ||
                   // Hotel-specific amenity keys
                   tags["amenity:spa"] == "yes" ||
                   tags["hotel:spa"] == "yes" ||
                   tags["facilities"] != nil && (tags["facilities"]!.lowercased().contains("spa") || 
                                                tags["facilities"]!.lowercased().contains("wellness"))
                   
        case "sauna":
            // Check for sauna tags based on OSM wiki documentation
            hasFeature = tags["leisure"] == "sauna" ||       // Primary sauna tag
                   tags["sauna"] == "yes" ||             // General sauna
                   tags["sauna"] == "hot" ||             // Finnish-style
                   tags["sauna"] == "steam" ||           // Steam sauna
                   tags["sauna"] == "dry" ||             // Dry sauna
                   tags["sauna"] == "infrared" ||        // Infrared sauna
                   tags["amenity"] == "sauna" ||         // Less common
                   // Hotel-specific amenity keys
                   tags["amenity:sauna"] == "yes" ||
                   tags["hotel:sauna"] == "yes" ||
                   tags["facilities"] != nil && tags["facilities"]!.lowercased().contains("sauna")
                   
        default:
            hasFeature = false
        }
        
        // If no explicit tags found, try heuristic detection from name and description
        if !hasFeature {
            let heuristicResult = detectWellnessFeatureFromName(featureType, element: element)
            print("🔍 Heuristic detection for '\(featureType)': \(heuristicResult)")
            return heuristicResult
        }
        
        print("✅ Found explicit tag for '\(featureType)': true")
        return hasFeature
    }
    
    /// Fallback heuristic detection of wellness features from accommodation names and descriptions
    private func detectWellnessFeatureFromName(_ featureType: String, element: OverpassElement) -> Bool {
        let name = element.name.lowercased()
        let description = element.tags?["description"]?.lowercased() ?? ""
        let brand = element.tags?["brand"]?.lowercased() ?? ""
        
        // Combine all text fields for searching
        let searchText = "\(name) \(description) \(brand)"
        
        switch featureType.lowercased() {
        case "pool":
            // Look for pool-related keywords in names
            return searchText.contains("pool") ||
                   searchText.contains("schwimmbad") ||    // German
                   searchText.contains("piscine") ||       // French
                   searchText.contains("piscina") ||       // Spanish/Italian
                   searchText.contains("swimming") ||
                   searchText.contains("aqua") ||
                   searchText.contains("thermal") ||
                   searchText.contains("water")
                   
        case "jacuzzi":
            return searchText.contains("jacuzzi") ||
                   searchText.contains("hot tub") ||
                   searchText.contains("whirlpool") ||
                   searchText.contains("hottub") ||
                   searchText.contains("spa pool")
                   
        case "spa":
            return searchText.contains("spa") ||
                   searchText.contains("wellness") ||
                   searchText.contains("therme") ||        // German
                   searchText.contains("thermal") ||
                   searchText.contains("beauty") ||
                   searchText.contains("relax") ||
                   searchText.contains("resort") ||
                   name.contains("spa") ||                 // Check name specifically
                   name.contains("wellness")
                   
        case "sauna":
            return searchText.contains("sauna") ||
                   searchText.contains("steam") ||
                   searchText.contains("finnish") ||
                   searchText.contains("dampf")            // German
                   
        default:
            return false
        }
    }
    
    // MARK: - Ski Piste Queries
    
    func searchSkiPistes(
        around coordinate: CLLocationCoordinate2D,
        radius: Int = 10000
    ) async throws -> [SkiPiste] {
        print("🎿 OverpassService: Starting piste search at \(coordinate.latitude), \(coordinate.longitude) with radius \(radius)m")
        
        let query = buildPisteQuery(coordinate: coordinate, radius: radius)
        print("📝 OverpassService: Built piste query: \(query.prefix(200))...")
        
        var request = URLRequest(url: URL(string: overpassAPIURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "data=\(query)".data(using: .utf8)
        
        print("🌐 OverpassService: Sending piste request to Overpass API...")
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ OverpassService: Invalid response type for pistes")
            throw OverpassError.invalidResponse
        }
        
        print("📡 OverpassService: Piste response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ OverpassService: HTTP error \(httpResponse.statusCode) for pistes")
            throw OverpassError.requestFailed
        }
        
        guard let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let elements = jsonData["elements"] as? [[String: Any]] else {
            print("❌ OverpassService: Failed to parse piste JSON response")
            throw OverpassError.invalidResponse
        }
        
        print("🔍 OverpassService: Found \(elements.count) piste elements")
        
        let overpassElements = elements.compactMap { elementDict -> OverpassElement? in
            return parseOverpassElement(from: elementDict)
        }
        
        let pistes = parsePistes(from: overpassElements)
        print("🎿 OverpassService: Successfully parsed \(pistes.count) ski pistes")
        
        return pistes
    }
    
    private func buildPisteQuery(coordinate: CLLocationCoordinate2D, radius: Int) -> String {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        return """
        [out:json][timeout:30];
        (
          way["piste:type"]["piste:type"!="connection"](around:\(radius),\(lat),\(lon));
          relation["piste:type"]["piste:type"!="connection"](around:\(radius),\(lat),\(lon));
        );
        out geom;
        """.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
    
    private func parsePistes(from elements: [OverpassElement]) -> [SkiPiste] {
        return elements.compactMap { element in
            guard let pisteTypeString = element.tags?["piste:type"],
                  let pisteType = PisteType(rawValue: pisteTypeString) else {
                print("⚠️ Skipping element without valid piste:type: \(element.tags?["piste:type"] ?? "nil")")
                return nil
            }
            
            // Parse difficulty (default to easy if not specified)
            let difficulty: PisteDifficulty
            if let difficultyString = element.tags?["piste:difficulty"],
               let parsedDifficulty = PisteDifficulty(rawValue: difficultyString) {
                difficulty = parsedDifficulty
            } else {
                difficulty = .easy // Default difficulty
            }
            
            // Parse grooming
            let grooming: PisteGrooming?
            if let groomingString = element.tags?["piste:grooming"] {
                grooming = PisteGrooming(rawValue: groomingString)
            } else {
                grooming = nil
            }
            
            // Parse status
            let status: PisteStatus?
            if let statusString = element.tags?["piste:status"] {
                status = PisteStatus(rawValue: statusString)
            } else {
                status = .unknown
            }
            
            // Get coordinates from geometry
            let coordinates = getCoordinatesFromGeometry(element: element)
            
            // Skip if no valid coordinates
            guard !coordinates.isEmpty else {
                print("⚠️ Skipping piste without coordinates: \(element.name)")
                return nil
            }
            
            let name = element.name.isEmpty ? nil : element.name
            let id = "piste_\(element.id)"
            
            print("✅ Parsed piste: \(name ?? id) (\(pisteType.rawValue), \(difficulty.rawValue))")
            
            return SkiPiste(
                id: id,
                name: name,
                type: pisteType,
                difficulty: difficulty,
                coordinates: coordinates,
                grooming: grooming,
                status: status
            )
        }
    }
    
    private func getCoordinatesFromGeometry(element: OverpassElement) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        
        // Check for geometry in the element
        if let geometry = element.geometry {
            for geoPoint in geometry {
                let coordinate = CLLocationCoordinate2D(latitude: geoPoint.lat, longitude: geoPoint.lon)
                coordinates.append(coordinate)
            }
        }
        
        // Fallback: use lat/lon if available
        if coordinates.isEmpty && element.lat != nil && element.lon != nil {
            coordinates.append(CLLocationCoordinate2D(latitude: element.lat!, longitude: element.lon!))
        }
        
        return coordinates
    }
    
    private func parseOverpassElement(from elementDict: [String: Any]) -> OverpassElement? {
        guard let id = elementDict["id"] as? Int,
              let type = elementDict["type"] as? String else { return nil }
        
        let lat = elementDict["lat"] as? Double
        let lon = elementDict["lon"] as? Double
        let tags = elementDict["tags"] as? [String: String]
        
        // Parse geometry if available
        var geometry: [OverpassCoordinate] = []
        if let geoData = elementDict["geometry"] as? [[String: Any]] {
            geometry = geoData.compactMap { geoDict in
                guard let geoLat = geoDict["lat"] as? Double,
                      let geoLon = geoDict["lon"] as? Double else { return nil }
                return OverpassCoordinate(lat: geoLat, lon: geoLon)
            }
        }
        
        return OverpassElement(
            type: type,
            id: id,
            lat: lat,
            lon: lon,
            tags: tags,
            geometry: geometry.isEmpty ? nil : geometry
        )
    }
    
    // MARK: - Debug Methods
    
    /// Debug method to test wellness feature detection with sample data
    func debugWellnessFeatureDetection() {
        print("🧪 Testing Wellness Feature Detection")
        print("=" * 50)
        
        // Create test accommodation with various wellness tags
        let testCases: [(String, [String: String])] = [
            ("Hotel with swimming_pool=yes", ["tourism": "hotel", "name": "Test Hotel", "swimming_pool": "yes"]),
            ("Hotel with leisure=swimming_pool", ["tourism": "hotel", "name": "Pool Hotel", "leisure": "swimming_pool"]),
            ("Spa Resort with wellness=yes", ["tourism": "resort", "name": "Wellness Resort", "wellness": "yes"]),
            ("Hotel with sauna in name", ["tourism": "hotel", "name": "Sauna Hotel Alpina"]),
            ("Hotel with facilities tag", ["tourism": "hotel", "name": "Mountain Hotel", "facilities": "pool, spa, sauna"]),
            ("Hotel with amenity=spa (deprecated)", ["tourism": "hotel", "name": "Spa Hotel", "amenity": "spa"]),
            ("Hotel with shop=beauty+beauty=spa", ["tourism": "hotel", "name": "Beauty Hotel", "shop": "beauty", "beauty": "spa"]),
            ("Plain hotel with no wellness", ["tourism": "hotel", "name": "Basic Hotel"])
        ]
        
        for (description, tags) in testCases {
            print("\n🏨 Testing: \(description)")
            print("   Tags: \(tags)")
            
            let testElement = MockOverpassElement(tags: tags)
            
            let hasPool = testParseWellnessFeature("pool", from: testElement)
            let hasJacuzzi = testParseWellnessFeature("jacuzzi", from: testElement)
            let hasSpa = testParseWellnessFeature("spa", from: testElement)
            let hasSauna = testParseWellnessFeature("sauna", from: testElement)
            
            print("   Results: Pool=\(hasPool), Jacuzzi=\(hasJacuzzi), Spa=\(hasSpa), Sauna=\(hasSauna)")
            
            if hasPool || hasJacuzzi || hasSpa || hasSauna {
                print("   ✅ Wellness features detected!")
            } else {
                print("   ❌ No wellness features detected")
            }
        }
        
        print("\n" + "=" * 50)
        print("🎯 Debug test completed!")
    }
    
    /// Test version of parseWellnessFeature that works with mock elements
    private func testParseWellnessFeature(_ featureType: String, from element: MockOverpassElement) -> Bool {
        guard let tags = element.tags else { 
            print("🏷️ No tags found for element \(element.id)")
            return false 
        }
        
        // Debug logging for wellness feature detection
        print("🔍 Checking \(featureType) for \(element.name) (ID: \(element.id))")
        print("🏷️ Available tags: \(tags)")
        
        let hasFeature: Bool
        
        switch featureType.lowercased() {
        case "pool":
            // Check for swimming pool tags based on OSM wiki documentation
            hasFeature = tags["swimming_pool"] == "yes" ||
                   tags["swimming_pool"] == "indoor" ||
                   tags["swimming_pool"] == "outdoor" ||
                   tags["swimming_pool"] == "inground" ||
                   tags["leisure"] == "swimming_pool" ||  // Separate pool entity
                   tags["amenity"] == "swimming_pool" ||   // Less common but still used
                   tags["sport"] == "swimming" ||
                   // Hotel-specific amenity keys (common in some regions)
                   tags["amenity:swimming_pool"] == "yes" ||
                   tags["hotel:pool"] == "yes" ||
                   tags["facilities"] != nil && tags["facilities"]!.lowercased().contains("pool")
                   
        case "jacuzzi":
            // Check for hot tub/jacuzzi tags
            hasFeature = tags["swimming_pool"] == "hot_tub" ||  // Proper OSM tagging
                   tags["swimming_pool"] == "spa" ||       // Spa pools with jets
                   tags["amenity"] == "hot_tub" ||
                   tags["leisure"] == "hot_tub" ||
                   tags["jacuzzi"] == "yes" ||
                   tags["hot_tub"] == "yes" ||
                   tags["whirlpool"] == "yes" ||
                   // Hotel-specific amenity keys
                   tags["amenity:hot_tub"] == "yes" ||
                   tags["hotel:jacuzzi"] == "yes" ||
                   tags["facilities"] != nil && (tags["facilities"]!.lowercased().contains("jacuzzi") || 
                                                tags["facilities"]!.lowercased().contains("hot_tub"))
                   
        case "spa":
            // Check for spa-related tags (note: amenity=spa is deprecated)
            hasFeature = tags["shop"] == "beauty" && tags["beauty"] == "spa" ||  // New standard
                   tags["amenity"] == "public_bath" ||      // Thermal spas
                   tags["leisure"] == "spa" ||              // Still used
                   tags["tourism"] == "spa_resort" ||       // Full spa resorts
                   tags["amenity"] == "spa" ||              // Deprecated but still found
                   tags["spa"] == "yes" ||
                   tags["wellness"] == "yes" ||
                   // Hotel-specific amenity keys
                   tags["amenity:spa"] == "yes" ||
                   tags["hotel:spa"] == "yes" ||
                   tags["facilities"] != nil && (tags["facilities"]!.lowercased().contains("spa") || 
                                                tags["facilities"]!.lowercased().contains("wellness"))
                   
        case "sauna":
            // Check for sauna tags based on OSM wiki documentation
            hasFeature = tags["leisure"] == "sauna" ||       // Primary sauna tag
                   tags["sauna"] == "yes" ||             // General sauna
                   tags["sauna"] == "hot" ||             // Finnish-style
                   tags["sauna"] == "steam" ||           // Steam sauna
                   tags["sauna"] == "dry" ||             // Dry sauna
                   tags["sauna"] == "infrared" ||        // Infrared sauna
                   tags["amenity"] == "sauna" ||         // Less common
                   // Hotel-specific amenity keys
                   tags["amenity:sauna"] == "yes" ||
                   tags["hotel:sauna"] == "yes" ||
                   tags["facilities"] != nil && tags["facilities"]!.lowercased().contains("sauna")
                   
        default:
            hasFeature = false
        }
        
        print("✅ Feature '\(featureType)' result: \(hasFeature)")
        
        // If no explicit tags found, try heuristic detection from name and description
        if !hasFeature {
            let heuristicResult = testDetectWellnessFeatureFromName(featureType, element: element)
            if heuristicResult {
                print("🔍 Heuristic detection found '\(featureType)' in name/description")
            }
            return heuristicResult
        }
        
        return hasFeature
    }
    
    /// Test version of heuristic detection that works with mock elements
    private func testDetectWellnessFeatureFromName(_ featureType: String, element: MockOverpassElement) -> Bool {
        let name = element.name.lowercased()
        let description = element.tags?["description"]?.lowercased() ?? ""
        let brand = element.tags?["brand"]?.lowercased() ?? ""
        
        // Combine all text fields for searching
        let searchText = "\(name) \(description) \(brand)"
        
        switch featureType.lowercased() {
        case "pool":
            // Look for pool-related keywords in names
            return searchText.contains("pool") ||
                   searchText.contains("schwimmbad") ||    // German
                   searchText.contains("piscine") ||       // French
                   searchText.contains("piscina") ||       // Spanish/Italian
                   searchText.contains("swimming") ||
                   searchText.contains("aqua") ||
                   searchText.contains("thermal") ||
                   searchText.contains("water")
                   
        case "jacuzzi":
            return searchText.contains("jacuzzi") ||
                   searchText.contains("hot tub") ||
                   searchText.contains("whirlpool") ||
                   searchText.contains("hottub") ||
                   searchText.contains("spa pool")
                   
        case "spa":
            return searchText.contains("spa") ||
                   searchText.contains("wellness") ||
                   searchText.contains("therme") ||        // German
                   searchText.contains("thermal") ||
                   searchText.contains("beauty") ||
                   searchText.contains("relax") ||
                   searchText.contains("resort") ||
                   name.contains("spa") ||                 // Check name specifically
                   name.contains("wellness")
                   
        case "sauna":
            return searchText.contains("sauna") ||
                   searchText.contains("steam") ||
                   searchText.contains("finnish") ||
                   searchText.contains("dampf")            // German
                   
        default:
            return false
        }
    }
}

// MARK: - Mock Data for Testing

private struct MockOverpassElement {
    let type: String = "node"
    let id: Int = 12345
    let lat: Double? = 47.0
    let lon: Double? = 10.0
    let tags: [String: String]?
    let geometry: [OverpassCoordinate]? = nil
    
    init(tags: [String: String]) {
        self.tags = tags
    }
    
    var name: String {
        return tags?["name"] ?? "Test Location"
    }
    
    var tourism: String? {
        return tags?["tourism"]
    }
    
    var amenity: String? {
        return tags?["amenity"]
    }
    
    var stars: String? {
        return tags?["stars"]
    }
    
    var website: String? {
        return tags?["website"]
    }
    
    var phone: String? {
        return tags?["phone"]
    }
    
    var isAccommodation: Bool {
        return tourism == "hotel" || 
               tourism == "guest_house" || 
               tourism == "hostel" || 
               tourism == "apartment" ||
               tourism == "motel" ||
               tourism == "resort" ||
               tourism == "chalet"
    }
    
    var isSkiResort: Bool {
        return tags?["leisure"] == "ski_resort" || tags?["piste:type"] != nil
    }
    
    var aerialway: String? {
        return tags?["aerialway"]
    }
}

// MARK: - Data Models

struct OverpassAccommodation {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let phone: String?
    let email: String?
    let website: String?
    let tourismType: String?
    let address: String
    let stars: Int?
    let capacity: Int?
    let hasPool: Bool
    let hasJacuzzi: Bool
    let hasSpa: Bool
    let hasSauna: Bool
    
    func toAccommodation(resort: SkiResort) -> Accommodation {
        let distance = calculateDistance(to: resort.coordinate)
        let priceCategory = determinePriceCategory()
        let estimatedPrice = estimatePrice(from: priceCategory)
        
        return Accommodation(
            name: name,
            distanceToLift: Int(distance),
            hasPool: hasPool,
            hasJacuzzi: hasJacuzzi,
            hasSpa: hasSpa,
            hasSauna: hasSauna,
            pricePerNight: estimatedPrice,
            rating: estimateRating(),
            imageUrl: "", // OSM doesn't provide photos
            resort: resort,
            email: email,
            phone: phone,
            website: website,
            coordinate: coordinate
        )
    }
    
    // MARK: - Helper Methods for Distance and Price Estimation
    
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
    
    private func estimateRating() -> Double {
        if let stars = stars {
            return Double(stars)
        }
        
        // Estimate based on accommodation type
        switch tourismType {
        case "hotel":
            return Double.random(in: 3.5...4.5)
        case "resort":
            return Double.random(in: 4.0...5.0)
        case "guest_house":
            return Double.random(in: 3.0...4.0)
        case "hostel":
            return Double.random(in: 2.5...3.5)
        default:
            return Double.random(in: 3.0...4.0)
        }
    }
    
    private func calculateDistance(to coordinate: CLLocationCoordinate2D) -> Double {
        let accommodationLocation = CLLocation(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude)
        let resortLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return accommodationLocation.distance(from: resortLocation)
    }
    
    func determinePriceCategory() -> Accommodation.PriceCategory {
        if let stars = stars {
            switch stars {
            case 1...2:
                return .budget
            case 3:
                return .mid
            case 4...5:
                return .luxury
            default:
                return .mid
            }
        }
        
        if let tourismType = tourismType {
            switch tourismType {
            case "hostel", "guest_house":
                return .budget
            case "resort", "hotel":
                return .luxury
            default:
                return .mid
            }
        }
        
        return .mid
    }
}

enum OverpassError: Error {
    case requestFailed
    case invalidResponse
    case noDataFound
    
    var localizedDescription: String {
        switch self {
        case .requestFailed:
            return "Overpass API request failed"
        case .invalidResponse:
            return "Invalid response from Overpass API"
        case .noDataFound:
            return "No accommodation data found"
        }
    }
}