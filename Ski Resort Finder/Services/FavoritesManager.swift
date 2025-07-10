import Foundation
import Combine

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    @Published var favoriteResortIDs: Set<String> = []
    
    private let userDefaults = UserDefaults.standard
    private let favoritesKey = "favoriteSkiResorts"
    
    private init() {
        loadFavorites()
    }
    
    func isFavorite(_ resort: SkiResort) -> Bool {
        return favoriteResortIDs.contains(resort.id.uuidString)
    }
    
    func toggleFavorite(_ resort: SkiResort) {
        let resortID = resort.id.uuidString
        
        if favoriteResortIDs.contains(resortID) {
            favoriteResortIDs.remove(resortID)
        } else {
            favoriteResortIDs.insert(resortID)
        }
        
        saveFavorites()
    }
    
    func getFavoriteResorts(from allResorts: [SkiResort]) -> [SkiResort] {
        return allResorts.filter { resort in
            favoriteResortIDs.contains(resort.id.uuidString)
        }
    }
    
    private func saveFavorites() {
        let favoritesArray = Array(favoriteResortIDs)
        userDefaults.set(favoritesArray, forKey: favoritesKey)
    }
    
    private func loadFavorites() {
        if let favoritesArray = userDefaults.array(forKey: favoritesKey) as? [String] {
            favoriteResortIDs = Set(favoritesArray)
        }
    }
}