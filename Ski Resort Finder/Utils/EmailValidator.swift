import Foundation

// MARK: - Email Validation Utility
struct EmailValidator {
    
    // MARK: - Validation Methods
    
    /// Validates email format using regex
    static func isValidFormat(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Validates email with comprehensive checks
    static func validateEmail(_ email: String) -> EmailValidationResult {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Basic format check
        guard isValidFormat(trimmedEmail) else {
            return EmailValidationResult(
                isValid: false,
                confidence: 0.0,
                issues: ["Invalid email format"]
            )
        }
        
        var confidence: Double = 1.0
        var issues: [String] = []
        
        // Length checks
        if trimmedEmail.count < 5 {
            confidence -= 0.3
            issues.append("Email too short")
        }
        
        if trimmedEmail.count > 254 {
            confidence -= 0.5
            issues.append("Email too long")
        }
        
        // Domain validation
        let components = trimmedEmail.split(separator: "@")
        guard components.count == 2 else {
            return EmailValidationResult(isValid: false, confidence: 0.0, issues: ["Invalid @ usage"])
        }
        
        let localPart = String(components[0])
        let domain = String(components[1])
        
        // Local part validation
        if localPart.isEmpty || localPart.count > 64 {
            confidence -= 0.4
            issues.append("Invalid local part")
        }
        
        // Domain validation
        let domainValidation = validateDomain(domain)
        confidence *= domainValidation.confidence
        issues.append(contentsOf: domainValidation.issues)
        
        // Check for suspicious patterns
        let suspiciousPatterns = [
            "test", "example", "sample", "dummy", "fake",
            "noreply", "no-reply", "donotreply", "bounce"
        ]
        
        for pattern in suspiciousPatterns {
            if trimmedEmail.contains(pattern) {
                confidence -= 0.2
                issues.append("Contains suspicious pattern: \(pattern)")
            }
        }
        
        // Hotel-specific validation
        let hotelConfidence = validateHotelEmail(trimmedEmail)
        confidence *= hotelConfidence
        
        return EmailValidationResult(
            isValid: confidence > 0.3,
            confidence: max(0.0, min(1.0, confidence)),
            issues: issues.isEmpty ? [] : issues
        )
    }
    
    // MARK: - Domain Validation
    
    private static func validateDomain(_ domain: String) -> (confidence: Double, issues: [String]) {
        var confidence: Double = 1.0
        var issues: [String] = []
        
        // Basic domain format
        guard domain.contains(".") else {
            return (0.0, ["Domain missing TLD"])
        }
        
        let domainParts = domain.split(separator: ".")
        guard domainParts.count >= 2 else {
            return (0.0, ["Invalid domain structure"])
        }
        
        // TLD validation
        let tld = String(domainParts.last!)
        if tld.count < 2 {
            confidence -= 0.5
            issues.append("Invalid TLD")
        }
        
        // Common valid TLDs for hotels
        let hotelTLDs = [
            "com", "ch", "de", "at", "fr", "it", "es", "uk", "net", "org",
            "hotel", "travel", "tourism", "ski", "alpine"
        ]
        
        if hotelTLDs.contains(tld) {
            confidence += 0.1 // Bonus for hotel-related TLDs
        }
        
        // Check for suspicious domains
        let suspiciousDomains = [
            "gmail.com", "yahoo.com", "hotmail.com", "outlook.com",
            "example.com", "test.com", "localhost"
        ]
        
        if suspiciousDomains.contains(domain) {
            confidence -= 0.5
            issues.append("Suspicious domain for hotel: \(domain)")
        }
        
        return (confidence, issues)
    }
    
    // MARK: - Hotel-Specific Validation
    
    private static func validateHotelEmail(_ email: String) -> Double {
        let hotelKeywords = [
            "hotel", "resort", "lodge", "inn", "guest", "reception",
            "booking", "reservation", "info", "contact", "welcome",
            "stay", "rooms", "front", "desk", "concierge"
        ]
        
        let emailLower = email.lowercased()
        
        for keyword in hotelKeywords {
            if emailLower.contains(keyword) {
                return 1.1 // Bonus for hotel-related keywords
            }
        }
        
        return 1.0 // Neutral if no hotel keywords
    }
    
    // MARK: - Bulk Validation
    
    /// Validates multiple emails and returns them sorted by quality
    static func validateAndRankEmails(_ emails: [String]) -> [RankedEmail] {
        let validatedEmails = emails.compactMap { email -> RankedEmail? in
            let validation = validateEmail(email)
            guard validation.isValid else { return nil }
            
            return RankedEmail(
                email: email,
                validation: validation
            )
        }
        
        // Sort by confidence (highest first)
        return validatedEmails.sorted { $0.validation.confidence > $1.validation.confidence }
    }
}

// MARK: - Supporting Types

struct EmailValidationResult {
    let isValid: Bool
    let confidence: Double  // 0.0 to 1.0
    let issues: [String]
    
    var qualityDescription: String {
        switch confidence {
        case 0.9...1.0: return "Excellent"
        case 0.7..<0.9: return "Good"
        case 0.5..<0.7: return "Fair"
        case 0.3..<0.5: return "Poor"
        default: return "Invalid"
        }
    }
}

struct RankedEmail {
    let email: String
    let validation: EmailValidationResult
    
    var qualityScore: Double {
        return validation.confidence
    }
}

// MARK: - Email Normalization
extension EmailValidator {
    
    /// Normalizes email address for consistent storage
    static func normalizeEmail(_ email: String) -> String {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.lowercased()
    }
    
    /// Extracts domain from email
    static func extractDomain(from email: String) -> String? {
        let normalized = normalizeEmail(email)
        let components = normalized.split(separator: "@")
        guard components.count == 2 else { return nil }
        return String(components[1])
    }
    
    /// Checks if email belongs to a hotel domain (vs personal email)
    static func isHotelDomain(_ email: String) -> Bool {
        guard let domain = extractDomain(from: email) else { return false }
        
        let personalEmailProviders = [
            "gmail.com", "yahoo.com", "hotmail.com", "outlook.com",
            "icloud.com", "aol.com", "web.de", "gmx.de", "gmx.com"
        ]
        
        return !personalEmailProviders.contains(domain)
    }
}