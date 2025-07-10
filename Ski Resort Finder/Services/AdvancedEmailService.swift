import Foundation
import UIKit

// MARK: - Email Quality Scoring
enum EmailQuality: Int, CaseIterable {
    case verified = 100      // Found in OSM data
    case scraped = 80        // Extracted from website
    case inferred = 60       // Generated from website domain
    case fallback = 40       // Generated from hotel name
    case invalid = 0         // Invalid format
    
    var description: String {
        switch self {
        case .verified: return "Verified"
        case .scraped: return "Scraped"
        case .inferred: return "Inferred"
        case .fallback: return "Fallback"
        case .invalid: return "Invalid"
        }
    }
}

// MARK: - Email Result
class EmailResult {
    let email: String
    let quality: EmailQuality
    let source: String
    let confidence: Double
    
    init(email: String, quality: EmailQuality, source: String, confidence: Double) {
        self.email = email
        self.quality = quality
        self.source = source
        self.confidence = confidence
    }
    
    var isValid: Bool {
        return quality != .invalid && confidence > 0.5
    }
}

// MARK: - Wellness Features Result
class WellnessScrapingResult {
    let hasPool: Bool
    let hasJacuzzi: Bool
    let hasSpa: Bool
    let hasSauna: Bool
    let source: String
    let confidence: Double
    let detectionDetails: [String: String] // What keywords/sections triggered detection
    
    init(hasPool: Bool, hasJacuzzi: Bool, hasSpa: Bool, hasSauna: Bool, source: String, confidence: Double, detectionDetails: [String: String] = [:]) {
        self.hasPool = hasPool
        self.hasJacuzzi = hasJacuzzi  
        self.hasSpa = hasSpa
        self.hasSauna = hasSauna
        self.source = source
        self.confidence = confidence
        self.detectionDetails = detectionDetails
    }
    
    var hasAnyWellnessFeatures: Bool {
        return hasPool || hasJacuzzi || hasSpa || hasSauna
    }
    
    var wellnessFeatureCount: Int {
        return [hasPool, hasJacuzzi, hasSpa, hasSauna].filter { $0 }.count
    }
}

// MARK: - Email Processing Status
enum EmailProcessingStatus: Equatable {
    case idle
    case processing
    case completed
    case error(String)
}

// MARK: - Email Processing Statistics
struct EmailProcessingStatistics {
    var totalAccommodations: Int = 0
    var processedAccommodations: Int = 0
    var currentAccommodation: String = ""
    var foundEmails: Int = 0
    var verifiedEmails: Int = 0
    var scrapedEmails: Int = 0
    var inferredEmails: Int = 0
    var fallbackEmails: Int = 0
    
    // Wellness feature statistics
    var foundWellnessFeatures: Int = 0
    var foundPools: Int = 0
    var foundJacuzzis: Int = 0
    var foundSpas: Int = 0
    var foundSaunas: Int = 0
    
    var progressPercentage: Double {
        guard totalAccommodations > 0 else { return 0.0 }
        return Double(processedAccommodations) / Double(totalAccommodations)
    }
    
    var wellnessDetectionRate: Double {
        guard totalAccommodations > 0 else { return 0.0 }
        return Double(foundWellnessFeatures) / Double(totalAccommodations)
    }
}

// MARK: - Advanced Email Service
class AdvancedEmailService: ObservableObject {
    static let shared = AdvancedEmailService()
    
    @Published var processingStatus: EmailProcessingStatus = .idle
    @Published var statistics: EmailProcessingStatistics = EmailProcessingStatistics()
    
    private let session = URLSession.shared
    private let emailCache = NSCache<NSString, EmailResult>()
    private let wellnessCache = NSCache<NSString, WellnessScrapingResult>()
    
    // Email regex patterns
    private let emailRegex = try! NSRegularExpression(
        pattern: #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#,
        options: .caseInsensitive
    )
    
    // Common hotel email patterns
    private let hotelEmailPatterns = [
        "info", "reservation", "reservations", "booking", "bookings",
        "contact", "reception", "front.desk", "frontdesk", "hotel",
        "welcome", "stay", "guest", "guests"
    ]
    
    // Comprehensive wellness feature keywords for different languages
    private let wellnessKeywords = [
        "pool": [
            // English
            "swimming pool", "pool", "indoor pool", "outdoor pool", "heated pool", "infinity pool",
            "swimming", "swim", "aqua", "water sports", "pool area", "poolside",
            // German
            "schwimmbad", "schwimm", "hallenbad", "freibad", "pool", "wassersport", "aqua",
            "schwimmen", "schwimmbereich", "poolbereich", "heated pool", "beheizt",
            // French
            "piscine", "piscine intérieure", "piscine extérieure", "piscine chauffée", "natation",
            "bassin", "aquatique", "nage", "espace piscine",
            // Italian
            "piscina", "piscina coperta", "piscina scoperta", "piscina riscaldata", "nuoto",
            "vasca", "area piscina", "zona piscina"
        ],
        "jacuzzi": [
            // English
            "jacuzzi", "hot tub", "whirlpool", "spa pool", "jetted tub", "hot pool", "hydro",
            "bubble bath", "therapeutic pool", "hydrotherapy",
            // German  
            "whirlpool", "jacuzzi", "sprudelbad", "whirlwanne", "sprudel", "hydro",
            "blubberbad", "therapeutisches bad", "hydrotherapie",
            // French
            "jacuzzi", "bain à remous", "spa", "bain bouillonnant", "hydromassage",
            "bain thérapeutique", "hydrothérapie",
            // Italian
            "jacuzzi", "vasca idromassaggio", "idromassaggio", "spa", "vasca calda",
            "bagno terapeutico", "idroterapia"
        ],
        "spa": [
            // English
            "spa", "wellness", "beauty", "massage", "treatment", "therapy", "relaxation",
            "wellness center", "spa center", "beauty center", "thermal", "wellness area",
            "rejuvenation", "aromatherapy", "body treatment", "facial", "wellness suite",
            // German
            "spa", "wellness", "wellnessbereich", "wellnesscenter", "massage", "massagen",
            "behandlung", "therapie", "entspannung", "schönheit", "therme", "thermal",
            "wellness-oase", "wellnesshotel", "kur", "kurbereich", "aromatherapie",
            // French
            "spa", "bien-être", "wellness", "massage", "soins", "thérapie", "relaxation",
            "centre de bien-être", "centre spa", "thermal", "détente", "aromathérapie",
            "soins du corps", "soins du visage",
            // Italian
            "spa", "benessere", "wellness", "massaggio", "trattamento", "terapia", "relax",
            "centro benessere", "centro spa", "termale", "rilassamento", "aromaterapia",
            "trattamenti corpo", "trattamenti viso"
        ],
        "sauna": [
            // English
            "sauna", "steam room", "steam bath", "finnish sauna", "infrared sauna", "dry sauna",
            "bio sauna", "panorama sauna", "steam", "sweat lodge",
            // German
            "sauna", "dampfbad", "dampfsauna", "finnische sauna", "infrarotsauna", "biosana",
            "panoramasauna", "dampf", "saunabereich", "saunalandschaft", "aufguss",
            "finnland sauna", "trockensauna",
            // French  
            "sauna", "sauna finlandais", "bain de vapeur", "hammam", "sauna infrarouge",
            "sauna sec", "vapeur", "espace sauna",
            // Italian
            "sauna", "sauna finlandese", "bagno turco", "sauna a infrarossi", "sauna secca",
            "vapore", "area sauna", "hammam"
        ]
    ]
    
    private init() {}
    
    /// Find the best email for an accommodation using multiple strategies
    func findBestEmail(for accommodation: Accommodation, completion: @escaping (EmailResult?) -> Void) {
        let cacheKey = accommodation.name as NSString
        
        // Check cache first
        if let cached = emailCache.object(forKey: cacheKey) {
            print("📧 Using cached email for \(accommodation.name): \(cached.email) (\(cached.quality.description))")
            completion(cached)
            return
        }
        
        Task {
            let result = await findEmailWithStrategies(for: accommodation)
            
            // Cache the result
            if let result = result {
                emailCache.setObject(result, forKey: cacheKey)
            }
            
            await MainActor.run {
                completion(result)
            }
        }
    }
    
    // MARK: - Multi-Strategy Email Finding
    private func findEmailWithStrategies(for accommodation: Accommodation) async -> EmailResult? {
        var candidates: [EmailResult] = []
        
        // Strategy 1: Use existing OSM email (highest quality)
        if let osmEmail = accommodation.email, !osmEmail.isEmpty {
            let quality = validateEmail(osmEmail) ? EmailQuality.verified : EmailQuality.invalid
            let result = EmailResult(
                email: osmEmail,
                quality: quality,
                source: "OpenStreetMap",
                confidence: quality == .verified ? 1.0 : 0.0
            )
            candidates.append(result)
            print("📧 OSM Email found: \(osmEmail) (quality: \(quality.description))")
        }
        
        // Strategy 2: Scrape website for emails
        if let website = accommodation.website, !website.isEmpty {
            let scrapedEmails = await scrapeEmailsFromWebsite(website)
            for email in scrapedEmails {
                let result = EmailResult(
                    email: email,
                    quality: .scraped,
                    source: "Website Scraping",
                    confidence: 0.9
                )
                candidates.append(result)
                print("📧 Scraped email from website: \(email)")
            }
        }
        
        // Strategy 3: Infer from website domain
        if let website = accommodation.website, !website.isEmpty {
            let inferredEmails = inferEmailsFromWebsite(website, hotelName: accommodation.name)
            for email in inferredEmails {
                let result = EmailResult(
                    email: email,
                    quality: .inferred,
                    source: "Domain Inference",
                    confidence: 0.7
                )
                candidates.append(result)
                print("📧 Inferred email from domain: \(email)")
            }
        }
        
        // Strategy 4: Generate fallback email
        let fallbackEmail = generateFallbackEmail(for: accommodation)
        let fallbackResult = EmailResult(
            email: fallbackEmail,
            quality: .fallback,
            source: "Generated Fallback",
            confidence: 0.5
        )
        candidates.append(fallbackResult)
        print("📧 Generated fallback email: \(fallbackEmail)")
        
        // Return the best candidate
        let bestEmail = selectBestEmail(from: candidates)
        print("✅ Best email for \(accommodation.name): \(bestEmail?.email ?? "none") (quality: \(bestEmail?.quality.description ?? "none"), confidence: \(String(format: "%.1f", bestEmail?.confidence ?? 0.0 * 100))%)")
        
        return bestEmail
    }
    
    // MARK: - Wellness Feature Scraping
    
    /// Scrape wellness features from accommodation website
    func scrapeWellnessFeatures(for accommodation: Accommodation, completion: @escaping (WellnessScrapingResult?) -> Void) {
        let cacheKey = accommodation.name as NSString
        
        // Check cache first
        if let cached = wellnessCache.object(forKey: cacheKey) {
            print("🏊‍♀️ Using cached wellness features for \(accommodation.name): \(cached.wellnessFeatureCount) features found")
            completion(cached)
            return
        }
        
        Task {
            let result = await scrapeWellnessFeaturesFromWebsite(for: accommodation)
            
            // Cache the result
            if let result = result {
                wellnessCache.setObject(result, forKey: cacheKey)
            }
            
            await MainActor.run {
                completion(result)
            }
        }
    }
    
    /// Internal method to scrape wellness features from website
    private func scrapeWellnessFeaturesFromWebsite(for accommodation: Accommodation) async -> WellnessScrapingResult? {
        guard let website = accommodation.website, !website.isEmpty,
              let url = sanitizeURL(website) else {
            // Fallback to name-based detection if no website
            return detectWellnessFeaturesFromName(accommodation)
        }
        
        do {
            print("🏊‍♀️ Scraping wellness features from: \(url.absoluteString)")
            let (data, _) = try await session.data(from: url)
            
            guard let html = String(data: data, encoding: .utf8) else {
                return detectWellnessFeaturesFromName(accommodation)
            }
            
            // Clean HTML and extract text content
            let cleanText = cleanHTMLAndExtractText(html)
            
            // Detect wellness features from website content
            let result = detectWellnessFeaturesFromText(cleanText, source: "Website Scraping", accommodation: accommodation)
            
            print("🏊‍♀️ Wellness features detected for \(accommodation.name): Pool=\(result.hasPool), Jacuzzi=\(result.hasJacuzzi), Spa=\(result.hasSpa), Sauna=\(result.hasSauna)")
            
            return result
            
        } catch {
            print("❌ Failed to scrape wellness features from \(website): \(error)")
            return detectWellnessFeaturesFromName(accommodation)
        }
    }
    
    /// Detect wellness features from text content using comprehensive keyword matching
    private func detectWellnessFeaturesFromText(_ text: String, source: String, accommodation: Accommodation) -> WellnessScrapingResult {
        let lowercaseText = text.lowercased()
        var detectionDetails: [String: String] = [:]
        
        // Detect each wellness feature type
        let hasPool = detectFeatureInText(lowercaseText, featureType: "pool", detectionDetails: &detectionDetails)
        let hasJacuzzi = detectFeatureInText(lowercaseText, featureType: "jacuzzi", detectionDetails: &detectionDetails)
        let hasSpa = detectFeatureInText(lowercaseText, featureType: "spa", detectionDetails: &detectionDetails)
        let hasSauna = detectFeatureInText(lowercaseText, featureType: "sauna", detectionDetails: &detectionDetails)
        
        // Calculate confidence based on detection strength
        let detectionCount = [hasPool, hasJacuzzi, hasSpa, hasSauna].filter { $0 }.count
        let confidence = detectionCount > 0 ? 0.85 : 0.0
        
        return WellnessScrapingResult(
            hasPool: hasPool,
            hasJacuzzi: hasJacuzzi,
            hasSpa: hasSpa,
            hasSauna: hasSauna,
            source: source,
            confidence: confidence,
            detectionDetails: detectionDetails
        )
    }
    
    /// Detect specific wellness feature in text using keyword matching
    private func detectFeatureInText(_ text: String, featureType: String, detectionDetails: inout [String: String]) -> Bool {
        guard let keywords = wellnessKeywords[featureType] else { return false }
        
        var foundKeywords: [String] = []
        
        for keyword in keywords {
            if text.contains(keyword.lowercased()) {
                foundKeywords.append(keyword)
            }
        }
        
        if !foundKeywords.isEmpty {
            detectionDetails[featureType] = foundKeywords.joined(separator: ", ")
            return true
        }
        
        return false
    }
    
    /// Fallback detection from accommodation name only
    private func detectWellnessFeaturesFromName(_ accommodation: Accommodation) -> WellnessScrapingResult {
        let result = detectWellnessFeaturesFromText(accommodation.name, source: "Name Detection", accommodation: accommodation)
        print("🏊‍♀️ Fallback name-based detection for \(accommodation.name): \(result.wellnessFeatureCount) features")
        return result
    }
    
    /// Clean HTML content and extract readable text
    private func cleanHTMLAndExtractText(_ html: String) -> String {
        var cleanText = html
        
        // Remove script and style content
        cleanText = cleanText.replacingOccurrences(of: #"<script[^>]*>.*?</script>"#, with: "", options: [.regularExpression, .caseInsensitive])
        cleanText = cleanText.replacingOccurrences(of: #"<style[^>]*>.*?</style>"#, with: "", options: [.regularExpression, .caseInsensitive])
        
        // Remove HTML tags but keep the content
        cleanText = cleanText.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
        
        // Clean up whitespace and decode HTML entities
        cleanText = cleanText.replacingOccurrences(of: "&nbsp;", with: " ")
        cleanText = cleanText.replacingOccurrences(of: "&amp;", with: "&")
        cleanText = cleanText.replacingOccurrences(of: "&lt;", with: "<")
        cleanText = cleanText.replacingOccurrences(of: "&gt;", with: ">")
        cleanText = cleanText.replacingOccurrences(of: "&quot;", with: "\"")
        
        // Normalize whitespace
        cleanText = cleanText.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        return cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Website Email Scraping
    private func scrapeEmailsFromWebsite(_ urlString: String) async -> [String] {
        guard let url = sanitizeURL(urlString) else { return [] }
        
        do {
            print("🌐 Scraping emails from: \(url.absoluteString)")
            let (data, _) = try await session.data(from: url)
            
            guard let html = String(data: data, encoding: .utf8) else { return [] }
            
            let emails = extractEmailsFromText(html)
            let rankedEmails = EmailValidator.validateAndRankEmails(emails)
            let validEmails = rankedEmails.map { $0.email }
            
            print("📧 Found \(validEmails.count) valid emails in website content (from \(emails.count) candidates)")
            for (index, rankedEmail) in rankedEmails.prefix(3).enumerated() {
                print("   \(index + 1). \(rankedEmail.email) (quality: \(rankedEmail.validation.qualityDescription), confidence: \(String(format: "%.1f", rankedEmail.validation.confidence * 100))%)")
            }
            
            return validEmails
            
        } catch {
            print("❌ Failed to scrape website \(urlString): \(error)")
            return []
        }
    }
    
    // MARK: - Email Extraction from Text
    private func extractEmailsFromText(_ text: String) -> [String] {
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = emailRegex.matches(in: text, options: [], range: range)
        
        var emails: [String] = []
        for match in matches {
            if let range = Range(match.range, in: text) {
                let email = String(text[range]).lowercased()
                
                // Filter out common non-hotel emails
                if !isNonHotelEmail(email) {
                    emails.append(email)
                }
            }
        }
        
        return Array(Set(emails)) // Remove duplicates
    }
    
    // MARK: - Domain-Based Email Inference
    private func inferEmailsFromWebsite(_ urlString: String, hotelName: String) -> [String] {
        guard let url = URL(string: urlString),
              let domain = url.host else { return [] }
        
        var inferredEmails: [String] = []
        
        // Generate emails with common prefixes
        for prefix in hotelEmailPatterns {
            let email = "\(prefix)@\(domain)"
            if validateEmail(email) {
                inferredEmails.append(email)
            }
        }
        
        // Add hotel name-based email
        let hotelPrefix = sanitizeHotelNameForEmail(hotelName)
        if !hotelPrefix.isEmpty {
            let email = "\(hotelPrefix)@\(domain)"
            if validateEmail(email) {
                inferredEmails.append(email)
            }
        }
        
        return inferredEmails
    }
    
    // MARK: - Email Validation
    private func validateEmail(_ email: String) -> Bool {
        let validation = EmailValidator.validateEmail(email)
        return validation.isValid && validation.confidence > 0.5
    }
    
    private func getEmailQuality(_ email: String) -> (quality: EmailQuality, confidence: Double) {
        let validation = EmailValidator.validateEmail(email)
        
        if !validation.isValid {
            return (.invalid, 0.0)
        }
        
        // Determine quality based on validation confidence
        let quality: EmailQuality
        switch validation.confidence {
        case 0.9...1.0: quality = .verified
        case 0.7..<0.9: quality = .scraped
        case 0.5..<0.7: quality = .inferred
        default: quality = .fallback
        }
        
        return (quality, validation.confidence)
    }
    
    // MARK: - Email Quality Assessment
    private func selectBestEmail(from candidates: [EmailResult]) -> EmailResult? {
        // Filter valid emails
        let validCandidates = candidates.filter { $0.isValid }
        
        if validCandidates.isEmpty {
            return candidates.first // Return any candidate if none are valid
        }
        
        // Sort by quality (highest first), then by confidence
        let sorted = validCandidates.sorted { first, second in
            if first.quality.rawValue == second.quality.rawValue {
                return first.confidence > second.confidence
            }
            return first.quality.rawValue > second.quality.rawValue
        }
        
        return sorted.first
    }
    
    // MARK: - Utility Functions
    private func sanitizeURL(_ urlString: String) -> URL? {
        var sanitized = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !sanitized.hasPrefix("http") {
            sanitized = "https://" + sanitized
        }
        
        return URL(string: sanitized)
    }
    
    private func isNonHotelEmail(_ email: String) -> Bool {
        let nonHotelPatterns = [
            "noreply", "no-reply", "donotreply", "support", "admin", "webmaster",
            "postmaster", "mailer-daemon", "abuse", "spam", "privacy",
            "legal", "careers", "jobs", "press", "media", "news"
        ]
        
        let lowercaseEmail = email.lowercased()
        return nonHotelPatterns.contains { pattern in
            lowercaseEmail.contains(pattern)
        }
    }
    
    private func sanitizeHotelNameForEmail(_ hotelName: String) -> String {
        var sanitized = hotelName.lowercased()
        
        // Remove common hotel prefixes/suffixes
        let removePhrases = ["hotel", "resort", "lodge", "inn", "guesthouse", "pension", 
                           "gasthof", "gasthaus", "chalet", "apartment", "apartments"]
        
        for phrase in removePhrases {
            sanitized = sanitized.replacingOccurrences(of: phrase, with: "")
        }
        
        // Clean up special characters
        sanitized = sanitized.replacingOccurrences(of: " ", with: "")
        sanitized = sanitized.replacingOccurrences(of: "-", with: "")
        sanitized = sanitized.replacingOccurrences(of: "_", with: "")
        sanitized = sanitized.replacingOccurrences(of: "'", with: "")
        sanitized = sanitized.replacingOccurrences(of: "&", with: "and")
        
        // Replace umlauts
        let umlautMap = ["ä": "ae", "ö": "oe", "ü": "ue", "ß": "ss"]
        for (umlaut, replacement) in umlautMap {
            sanitized = sanitized.replacingOccurrences(of: umlaut, with: replacement)
        }
        
        // Keep only alphanumeric characters
        sanitized = sanitized.filter { $0.isLetter || $0.isNumber }
        
        // Limit length and ensure minimum length
        if sanitized.count < 3 {
            return "hotel"
        }
        
        return String(sanitized.prefix(15))
    }
    
    private func generateFallbackEmail(for accommodation: Accommodation) -> String {
        let sanitizedName = sanitizeHotelNameForEmail(accommodation.name)
        let domain = sanitizedName.isEmpty ? "hotel" : sanitizedName
        
        // Add some randomness to avoid duplicates
        let hash = abs(accommodation.name.hashValue) % 999
        return "info@\(domain)\(hash).com"
    }
    
    /// Process emails and wellness features for multiple accommodations with progress tracking
    @MainActor
    func processEmailsAndWellnessFeatures(for accommodations: [Accommodation], completion: @escaping ([String: EmailResult], [String: WellnessScrapingResult]) -> Void) {
        guard !accommodations.isEmpty else {
            completion([:], [:])
            return
        }
        
        // Initialize statistics
        statistics = EmailProcessingStatistics()
        statistics.totalAccommodations = accommodations.count
        processingStatus = .processing
        
        var emailResults: [String: EmailResult] = [:]
        var wellnessResults: [String: WellnessScrapingResult] = [:]
        var processedCount = 0
        
        print("📧🏊‍♀️ Starting email and wellness feature processing for \(accommodations.count) accommodations")
        
        // Process accommodations sequentially to avoid overwhelming servers
        Task {
            for (index, accommodation) in accommodations.enumerated() {
                await MainActor.run {
                    statistics.currentAccommodation = accommodation.name
                    statistics.processedAccommodations = index
                }
                
                // Process email and wellness features concurrently for each accommodation
                async let emailResult = findEmailWithStrategies(for: accommodation)
                async let wellnessResult = scrapeWellnessFeaturesFromWebsite(for: accommodation)
                
                let (email, wellness) = await (emailResult, wellnessResult)
                
                await MainActor.run {
                    // Handle email results
                    if let emailResult = email {
                        emailResults[accommodation.name] = emailResult
                        statistics.foundEmails += 1
                        
                        // Update quality statistics
                        switch emailResult.quality {
                        case .verified:
                            statistics.verifiedEmails += 1
                        case .scraped:
                            statistics.scrapedEmails += 1
                        case .inferred:
                            statistics.inferredEmails += 1
                        case .fallback:
                            statistics.fallbackEmails += 1
                        case .invalid:
                            break
                        }
                    }
                    
                    // Handle wellness results
                    if let wellnessResult = wellness {
                        wellnessResults[accommodation.name] = wellnessResult
                        
                        if wellnessResult.hasAnyWellnessFeatures {
                            statistics.foundWellnessFeatures += 1
                        }
                        
                        if wellnessResult.hasPool { statistics.foundPools += 1 }
                        if wellnessResult.hasJacuzzi { statistics.foundJacuzzis += 1 }
                        if wellnessResult.hasSpa { statistics.foundSpas += 1 }
                        if wellnessResult.hasSauna { statistics.foundSaunas += 1 }
                    }
                    
                    processedCount += 1
                    statistics.processedAccommodations = processedCount
                }
                
                // Small delay to prevent overwhelming servers
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds (increased due to dual processing)
            }
            
            await MainActor.run {
                processingStatus = .completed
                print("✅ Email and wellness processing completed.")
                print("   📧 Found \(emailResults.count) emails out of \(accommodations.count) accommodations")
                print("   🏊‍♀️ Found wellness features in \(statistics.foundWellnessFeatures) accommodations (\(String(format: "%.1f", statistics.wellnessDetectionRate * 100))%)")
                print("   📊 Wellness breakdown: Pools=\(statistics.foundPools), Jacuzzis=\(statistics.foundJacuzzis), Spas=\(statistics.foundSpas), Saunas=\(statistics.foundSaunas)")
                completion(emailResults, wellnessResults)
            }
        }
    }
    
    /// Stop email processing
    @MainActor
    func stopProcessing() {
        processingStatus = .idle
        statistics = EmailProcessingStatistics()
        print("⏹️ Email processing stopped by user")
    }
}

// MARK: - Extension for Backward Compatibility
extension AdvancedEmailService {
    /// Simple interface for backward compatibility
    func findEmail(for accommodation: Accommodation, completion: @escaping (String?) -> Void) {
        findBestEmail(for: accommodation) { result in
            completion(result?.email)
        }
    }
    
    /// Check if service is currently processing emails
    var isProcessing: Bool {
        return processingStatus == .processing
    }
    
    /// Get processing progress (0.0 to 1.0)
    var processingProgress: Double {
        return statistics.progressPercentage
    }
    
    /// Process emails for multiple accommodations with progress tracking (backward compatibility)
    @MainActor
    func processEmails(for accommodations: [Accommodation], completion: @escaping ([String: EmailResult]) -> Void) {
        processEmailsAndWellnessFeatures(for: accommodations) { emailResults, _ in
            completion(emailResults)
        }
    }
}