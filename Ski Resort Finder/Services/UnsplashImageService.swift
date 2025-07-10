import Foundation
import SwiftUI

class UnsplashImageService: ObservableObject {
    
    // Picsum Photos API (zuverlässig und kostenlos)
    private let baseURL = "https://picsum.photos"
    
    // MARK: - Hotel/Resort Foto URLs
    static func getHotelImageURL(for accommodationName: String, width: Int = 400, height: Int = 300) -> URL? {
        // Intelligente Bildauswahl basierend auf Hotel-Namen und -typ
        let hotelId = getSmartHotelImageId(from: accommodationName)
        
        // Picsum Photos URL mit intelligenter Bild-ID für hotelspezifische Bilder
        let urlString = "https://picsum.photos/id/\(hotelId)/\(width)/\(height)"
        
        return URL(string: urlString)
    }
    
    // Intelligente Bildauswahl basierend auf Hotelname und -typ
    private static func getSmartHotelImageId(from name: String) -> Int {
        let cleanName = name.lowercased()
            .replacingOccurrences(of: "(demo)", with: "")
            .replacingOccurrences(of: "demo", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Spezielle Bilder für verschiedene Hotel-Typen
        if cleanName.contains("wellness") || cleanName.contains("spa") {
            // Wellness/Spa Hotels - Entspannungsbilder
            let spaImages = [540, 541, 565, 618, 634] // Architektur/Entspannung
            return spaImages[abs(cleanName.hashValue) % spaImages.count]
        }
        
        if cleanName.contains("alpine") || cleanName.contains("mountain") || cleanName.contains("berg") {
            // Alpine Hotels - Bergbilder
            let mountainImages = [274, 337, 426, 442, 683] // Berge/Natur
            return mountainImages[abs(cleanName.hashValue) % mountainImages.count]
        }
        
        if cleanName.contains("lodge") || cleanName.contains("chalet") || cleanName.contains("hütte") {
            // Lodges/Chalets - Gemütliche Bilder
            let lodgeImages = [164, 232, 354, 582, 747] // Gemütliche Architektur
            return lodgeImages[abs(cleanName.hashValue) % lodgeImages.count]
        }
        
        if cleanName.contains("luxury") || cleanName.contains("deluxe") || cleanName.contains("premium") {
            // Luxus Hotels - Edle Bilder
            let luxuryImages = [188, 258, 390, 463, 590] // Elegante Architektur
            return luxuryImages[abs(cleanName.hashValue) % luxuryImages.count]
        }
        
        if cleanName.contains("gasthof") || cleanName.contains("gasthaus") || cleanName.contains("pension") {
            // Traditionelle Unterkünfte
            let traditionalImages = [102, 190, 459, 615, 668] // Traditionelle Gebäude
            return traditionalImages[abs(cleanName.hashValue) % traditionalImages.count]
        }
        
        // Standard Hotels - Allgemeine Hotel-Bilder
        let standardHotelImages = [540, 541, 565, 582, 590, 615, 618, 634, 663, 668]
        return standardHotelImages[abs(cleanName.hashValue) % standardHotelImages.count]
    }
    
    // Generiert eine konsistente Bild-ID basierend auf Hotel-Namen
    private static func generateStableImageId(from name: String) -> Int {
        let cleanName = name
            .lowercased()
            .replacingOccurrences(of: "(demo)", with: "")
            .replacingOccurrences(of: "demo", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Hash-Funktion für konsistente IDs - bevorzuge Hotel/Architektur-Fotos
        let hash = abs(cleanName.hashValue)
        // Verwende spezielle Bild-IDs für Hotel-ähnliche Fotos
        let hotelImageIds = [102, 164, 188, 190, 232, 258, 274, 337, 354, 390, 
                           426, 442, 459, 463, 540, 541, 565, 582, 590, 615, 
                           618, 634, 663, 668, 683, 747, 780, 821, 870, 907]
        let imageId = hotelImageIds[hash % hotelImageIds.count]
        
        return imageId
    }
    
    // MARK: - Fallback Fotos für verschiedene Hoteltypen
    static func getFallbackImageURL(for accommodationType: String, width: Int = 400, height: Int = 300) -> URL? {
        // Verwende verschiedene Bild-IDs für verschiedene Typen
        let fallbackIds = [150, 200, 250, 300, 350, 400, 450, 500, 550, 600]
        let randomId = fallbackIds.randomElement() ?? 200
        
        let urlString = "https://picsum.photos/id/\(randomId)/\(width)/\(height)"
        return URL(string: urlString)
    }
    
    // MARK: - Spezifische Kategorien
    static func getLuxuryHotelImageURL(width: Int = 400, height: Int = 300) -> URL? {
        let urlString = "https://picsum.photos/id/540/\(width)/\(height)" // Schönes Architektur-Foto
        return URL(string: urlString)
    }
    
    static func getSkiResortImageURL(width: Int = 400, height: Int = 300) -> URL? {
        let urlString = "https://picsum.photos/id/431/\(width)/\(height)" // Berg/Schnee-Foto
        return URL(string: urlString)
    }
    
    static func getChaletImageURL(width: Int = 400, height: Int = 300) -> URL? {
        let urlString = "https://picsum.photos/id/342/\(width)/\(height)" // Haus/Hütte-Foto
        return URL(string: urlString)
    }
}

// MARK: - Caching für bessere Performance
class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100 // Limitiere auf 100 Bilder
    }
    
    func getImage(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

// MARK: - Async Image Loader
@MainActor
class AsyncImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    
    func loadImage(from url: URL?) async {
        guard let url = url else { return }
        
        let cacheKey = url.absoluteString
        
        // Prüfe Cache erst
        if let cachedImage = ImageCache.shared.getImage(for: cacheKey) {
            self.image = cachedImage
            return
        }
        
        isLoading = true
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let loadedImage = UIImage(data: data) {
                ImageCache.shared.setImage(loadedImage, for: cacheKey)
                self.image = loadedImage
            }
        } catch {
            print("Fehler beim Laden des Bildes: \(error)")
            // Keine Fallbacks mehr - zeige leeres Bild bei Fehlern
        }
        
        isLoading = false
    }
}