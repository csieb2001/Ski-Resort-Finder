import Foundation

/// ERA5 API Konfiguration
/// 
/// Um Ihren kostenlosen ERA5 API-Schlüssel zu erhalten:
/// 1. Gehen Sie zu: https://cds.climate.copernicus.eu/
/// 2. Kostenloses Konto erstellen
/// 3. API-Schlüssel unter "Your Account" → "API Key" kopieren
/// 4. Hier eintragen oder als Environment Variable ERA5_API_KEY setzen
struct ERA5Config {
    
    // MARK: - API Configuration
    
    /// ERA5 API Base URL - CDS API v2
    static let baseURL = "https://cds.climate.copernicus.eu/api/v2"
    
    /// Ihr ERA5 API-Schlüssel hier eintragen
    /// Format: "uuid:uuid" (beide Teile sind UUIDs mit Bindestrichen)
    /// 
    /// [WARN] WICHTIG: Für Production-Apps sollten Sie dies nicht hart kodieren!
    /// Verwenden Sie stattdessen:
    /// - Environment Variables
    /// - Keychain Services  
    /// - Remote Configuration
    /// 
    /// BEISPIEL: private static let hardcodedAPIKey: String? = "uuid:uuid"
    private static let hardcodedAPIKey: String? = nil // Configure via Settings → ERA5 API Key or Environment Variable ERA5_API_KEY
    
    // MARK: - API Key Retrieval
    
    /// Holt den API-Schlüssel aus verschiedenen Quellen
    static var apiKey: String? {
        // 1. Priorität: Environment Variable (für Entwicklung)
        if let envKey = ProcessInfo.processInfo.environment["ERA5_API_KEY"] {
            return envKey
        }
        
        // 2. Priorität: Hardcoded Key (für schnelle Tests)
        if let hardcoded = hardcodedAPIKey, !hardcoded.isEmpty {
            return hardcoded
        }
        
        // 3. Priorität: Keychain (für Production)
        if let keychainKey = loadFromKeychain() {
            return keychainKey
        }
        
        return nil
    }
    
    /// Speichert API-Schlüssel sicher im Keychain
    static func saveAPIKey(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "ERA5_API_KEY",
            kSecAttrService as String: "SkiResortFinder",
            kSecValueData as String: key.data(using: .utf8)!
        ]
        
        // Erst löschen falls bereits vorhanden
        SecItemDelete(query as CFDictionary)
        
        // Dann neu speichern
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Lädt API-Schlüssel aus dem Keychain
    private static func loadFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "ERA5_API_KEY",
            kSecAttrService as String: "SkiResortFinder",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let key = String(data: data, encoding: .utf8) {
            return key
        }
        
        return nil
    }
    
    /// Löscht API-Schlüssel aus dem Keychain
    static func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "ERA5_API_KEY",
            kSecAttrService as String: "SkiResortFinder"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - Configuration Validation
    
    /// Prüft ob API-Schlüssel konfiguriert ist
    static var isConfigured: Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }
    
    /// Prüft ob API-Schlüssel das richtige Format hat
    static var isValidFormat: Bool {
        guard let key = apiKey else { return false }
        
        // ERA5 API Keys haben das Format: "uuid:uuid" (beide Teile sind UUIDs)
        let pattern = #"^[a-f0-9\-]+:[a-f0-9\-]+$"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: key.count)
        return regex?.firstMatch(in: key, options: [], range: range) != nil
    }
    
    // MARK: - Development Helpers
    
    /// Für Debug-Zwecke: Zeigt API-Schlüssel Status
    static var debugStatus: String {
        if !isConfigured {
            return "[ERROR] Kein API-Schlüssel konfiguriert"
        } else if !isValidFormat {
            return "[WARN] API-Schlüssel Format ungültig"
        } else {
            let masked = maskAPIKey(apiKey!)
            return "[OK] API-Schlüssel konfiguriert: \(masked)"
        }
    }
    
    /// Maskiert API-Schlüssel für Debug-Ausgabe
    private static func maskAPIKey(_ key: String) -> String {
        let components = key.split(separator: ":")
        if components.count == 2 {
            let uid = String(components[0])
            let secret = String(components[1])
            let maskedSecret = String(secret.prefix(4)) + "****" + String(secret.suffix(4))
            return "\(uid):\(maskedSecret)"
        }
        return "****"
    }
}

// MARK: - Extensions

extension ERA5Config {
    /// Erstellt URLRequest mit korrekter Authentifizierung
    static func createAuthenticatedRequest(url: URL) -> URLRequest? {
        guard let apiKey = apiKey else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // ERA5 API verwendet HTTP Basic Auth mit API-Schlüssel als Username
        let components = apiKey.split(separator: ":")
        if components.count == 2 {
            let uid = String(components[0])
            let key = String(components[1])
            let credentials = "\(uid):\(key)"
            let base64Credentials = Data(credentials.utf8).base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
}
