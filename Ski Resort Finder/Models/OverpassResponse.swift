import Foundation

struct OverpassResponse: Codable {
    let elements: [OverpassElement]
}

struct OverpassElement: Codable {
    let type: String
    let id: Int
    let lat: Double?
    let lon: Double?
    let tags: [String: String]?
    let geometry: [OverpassCoordinate]?
    
    var name: String {
        return tags?["name"] ?? "Unnamed Location"
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

struct OverpassCoordinate: Codable {
    let lat: Double
    let lon: Double
}