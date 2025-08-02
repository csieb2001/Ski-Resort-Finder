import Foundation

/// Utility für dynamische App-Versionierung basierend auf aktuellem Datum
class AppVersion {
    
    /// Generiert Versionsnummer im Format 1.YYYY.MM.DD
    static var currentVersion: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let dateString = dateFormatter.string(from: Date())
        return "1.\(dateString)"
    }
    
    /// Vollständige Versionsinformation
    static var fullVersionInfo: String {
        let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? currentVersion
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        // Nutze dynamische Version wenn Bundle-Version nicht gesetzt oder Standard ist
        if bundleVersion == "1.0" || bundleVersion.isEmpty {
            return "\(currentVersion) (\(buildNumber))"
        }
        
        return "\(bundleVersion) (\(buildNumber))"
    }
    
    /// Build-Datum (wenn Build-Scripts es setzen)
    static var buildDate: String {
        if let buildDateString = Bundle.main.infoDictionary?["BuildDate"] as? String {
            return buildDateString
        }
        
        // Fallback: Aktuelles Datum verwenden
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: Date())
    }
    
    /// Debug-Information für Entwicklung
    static var debugInfo: String {
        """
        Version: \(fullVersionInfo)
        Build Date: \(buildDate)
        Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")
        """
    }
}