import Foundation
import UIKit
import SwiftUI

class AccommodationImageLoader: ObservableObject {
    static let shared = AccommodationImageLoader()
    
    @Published var images: [String: UIImage] = [:]
    private let screenshotService = WebsiteScreenshotService.shared
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {}
    
    /// Lädt Bild für eine Unterkunft basierend auf der imageUrl
    func loadImage(for imageUrl: String, accommodationName: String, accommodationType: String?) async -> UIImage? {
        // Check cache first
        if let cachedImage = cache.object(forKey: imageUrl as NSString) {
            await MainActor.run {
                images[imageUrl] = cachedImage
            }
            return cachedImage
        }
        
        var resultImage: UIImage?
        
        if imageUrl.hasPrefix("screenshot://") {
            // This is a website screenshot
            let accommodationId = String(imageUrl.dropFirst("screenshot://".count))
            resultImage = await loadScreenshotImage(for: accommodationId, name: accommodationName)
        } else if imageUrl.hasPrefix("placeholder://") {
            // This is a placeholder image
            let type = String(imageUrl.dropFirst("placeholder://".count))
            resultImage = await loadPlaceholderImage(for: type, name: accommodationName)
        } else if imageUrl.hasPrefix("http") {
            // This is a regular URL
            resultImage = await loadWebImage(from: imageUrl)
        } else {
            // Fallback to placeholder
            resultImage = await loadPlaceholderImage(for: accommodationType, name: accommodationName)
        }
        
        if let image = resultImage {
            cache.setObject(image, forKey: imageUrl as NSString)
            await MainActor.run {
                images[imageUrl] = image
            }
        }
        
        return resultImage
    }
    
    private func loadScreenshotImage(for accommodationId: String, name: String) async -> UIImage? {
        // In a real implementation, you would load the cached screenshot from disk
        // For now, return a placeholder that indicates this should be a screenshot
        return screenshotService.generateFallbackImage(for: "hotel", accommodationName: name)
    }
    
    private func loadPlaceholderImage(for type: String?, name: String) async -> UIImage? {
        return screenshotService.generateFallbackImage(for: type, accommodationName: name)
    }
    
    private func loadWebImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("❌ Failed to load image from \(urlString): \(error)")
            return nil
        }
    }
}

// SwiftUI AsyncImage replacement for accommodation images
struct AccommodationAsyncImage: View {
    let imageUrl: String
    let accommodationName: String
    let accommodationType: String?
    let placeholder: () -> AnyView
    
    @StateObject private var imageLoader = AccommodationImageLoader.shared
    @State private var loadedImage: UIImage?
    
    init(
        imageUrl: String,
        accommodationName: String,
        accommodationType: String? = nil,
        @ViewBuilder placeholder: @escaping () -> some View = { 
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                )
        }
    ) {
        self.imageUrl = imageUrl
        self.accommodationName = accommodationName
        self.accommodationType = accommodationType
        self.placeholder = { AnyView(placeholder()) }
    }
    
    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder()
            }
        }
        .onAppear {
            loadImageIfNeeded()
        }
        .onChange(of: imageUrl) { _, newValue in
            loadImageForUrl(newValue)
        }
    }
    
    private func loadImageIfNeeded() {
        loadImageForUrl(imageUrl)
    }
    
    private func loadImageForUrl(_ url: String) {
        // Check if already loaded
        if let cached = imageLoader.images[url] {
            loadedImage = cached
            return
        }
        
        Task {
            await loadImageAsync(for: url)
        }
    }
    
    @MainActor
    private func loadImageAsync(for url: String) async {
        let image = await imageLoader.loadImage(
            for: url,
            accommodationName: accommodationName,
            accommodationType: accommodationType
        )
        
        loadedImage = image
    }
}