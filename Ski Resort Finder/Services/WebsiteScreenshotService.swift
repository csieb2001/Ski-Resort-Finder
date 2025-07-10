import Foundation
import UIKit
import WebKit

class WebsiteScreenshotService: ObservableObject {
    static let shared = WebsiteScreenshotService()
    
    private let session = URLSession.shared
    private var webView: WKWebView?
    private let screenshotCache = NSCache<NSString, UIImage>()
    
    private init() {
        setupWebView()
    }
    
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 375, height: 667), configuration: config)
        webView?.isHidden = true
    }
    
    /// Erstellt Screenshot von Hotel-Website
    func generateScreenshot(from websiteURL: String, accommodationName: String) async -> UIImage? {
        // Check cache first
        let cacheKey = "\(websiteURL)_\(accommodationName)" as NSString
        if let cachedImage = screenshotCache.object(forKey: cacheKey) {
            print("📸 Using cached screenshot for \(accommodationName)")
            return cachedImage
        }
        
        guard let url = sanitizeURL(websiteURL) else {
            print("❌ Invalid URL for \(accommodationName): \(websiteURL)")
            return nil
        }
        
        do {
            let screenshot = try await takeScreenshot(of: url, for: accommodationName)
            
            // Cache the result
            if let screenshot = screenshot {
                screenshotCache.setObject(screenshot, forKey: cacheKey)
                print("📸 Cached new screenshot for \(accommodationName)")
            }
            
            return screenshot
        } catch {
            print("❌ Failed to take screenshot for \(accommodationName): \(error)")
            return nil
        }
    }
    
    private func sanitizeURL(_ urlString: String) -> URL? {
        var cleanURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add https:// if no protocol specified
        if !cleanURL.hasPrefix("http://") && !cleanURL.hasPrefix("https://") {
            cleanURL = "https://" + cleanURL
        }
        
        return URL(string: cleanURL)
    }
    
    @MainActor
    private func takeScreenshot(of url: URL, for accommodationName: String) async throws -> UIImage? {
        guard let webView = webView else {
            throw ScreenshotError.webViewNotAvailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            print("📸 Taking screenshot for \(accommodationName) from \(url.absoluteString)")
            
            // Set timeout for loading
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                continuation.resume(throwing: ScreenshotError.timeout)
            }
            
            // Load the website
            let request = URLRequest(url: url, timeoutInterval: 10.0)
            webView.load(request)
            
            // Wait for page to load
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                // Take screenshot after 3 seconds
                webView.takeSnapshot(with: nil) { image, error in
                    timeoutTask.cancel()
                    
                    if let error = error {
                        print("❌ Screenshot error for \(accommodationName): \(error)")
                        continuation.resume(returning: nil)
                    } else if let image = image {
                        print("✅ Screenshot taken for \(accommodationName)")
                        continuation.resume(returning: image)
                    } else {
                        print("⚠️ No screenshot generated for \(accommodationName)")
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
    
    /// Generiert Fallback-Bild wenn Website-Screenshot fehlschlägt
    func generateFallbackImage(for accommodationType: String?, accommodationName: String) -> UIImage? {
        return createPlaceholderImage(for: accommodationType, name: accommodationName)
    }
    
    private func createPlaceholderImage(for type: String?, name: String) -> UIImage? {
        let size = CGSize(width: 375, height: 250)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Background gradient based on accommodation type
        let colors = getColorsForAccommodationType(type)
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                colors: [colors.0.cgColor, colors.1.cgColor] as CFArray,
                                locations: [0.0, 1.0])
        
        if let gradient = gradient {
            context.drawLinearGradient(gradient,
                                     start: CGPoint(x: 0, y: 0),
                                     end: CGPoint(x: size.width, y: size.height),
                                     options: [])
        }
        
        // Add accommodation icon
        let iconName = getIconForAccommodationType(type)
        if let icon = UIImage(systemName: iconName) {
            let iconSize: CGFloat = 80
            let iconRect = CGRect(x: (size.width - iconSize) / 2,
                                y: (size.height - iconSize) / 2 - 20,
                                width: iconSize,
                                height: iconSize)
            
            UIColor.white.withAlphaComponent(0.8).setFill()
            icon.draw(in: iconRect)
        }
        
        // Add accommodation name
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black.withAlphaComponent(0.5),
            .strokeWidth: -2.0
        ]
        
        let text = name.count > 25 ? String(name.prefix(22)) + "..." : name
        let textSize = text.size(withAttributes: textAttributes)
        let textRect = CGRect(x: (size.width - textSize.width) / 2,
                            y: size.height - 40,
                            width: textSize.width,
                            height: textSize.height)
        
        text.draw(in: textRect, withAttributes: textAttributes)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func getColorsForAccommodationType(_ type: String?) -> (UIColor, UIColor) {
        switch type?.lowercased() {
        case "hotel":
            return (UIColor.systemBlue, UIColor.systemIndigo)
        case "resort":
            return (UIColor.systemPurple, UIColor.systemPink)
        case "guest_house":
            return (UIColor.systemGreen, UIColor.systemTeal)
        case "hostel":
            return (UIColor.systemOrange, UIColor.systemYellow)
        case "apartment", "chalet":
            return (UIColor.systemBrown, UIColor.systemOrange)
        default:
            return (UIColor.systemGray, UIColor.systemGray2)
        }
    }
    
    private func getIconForAccommodationType(_ type: String?) -> String {
        switch type?.lowercased() {
        case "hotel":
            return "building.2.fill"
        case "resort":
            return "mountain.2.fill"
        case "guest_house":
            return "house.fill"
        case "hostel":
            return "bed.double.fill"
        case "apartment":
            return "building.fill"
        case "chalet":
            return "house.lodge.fill"
        default:
            return "bed.double"
        }
    }
}

enum ScreenshotError: Error {
    case webViewNotAvailable
    case timeout
    case invalidURL
    
    var localizedDescription: String {
        switch self {
        case .webViewNotAvailable:
            return "WebView not available"
        case .timeout:
            return "Screenshot timeout"
        case .invalidURL:
            return "Invalid URL"
        }
    }
}