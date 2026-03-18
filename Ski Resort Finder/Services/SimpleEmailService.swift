import Foundation

/// Vereinfachter Email Service für Hotel-Kontaktdaten
class SimpleEmailService: ObservableObject {
    nonisolated(unsafe) static let shared = SimpleEmailService()
    
    private init() {}
    
    /// Einfache Email-Suche für Unterkünfte
    func findEmail(for accommodation: Accommodation, completion: @escaping (String?) -> Void) {
        print("Finding email for: \(accommodation.name)")
        
        // 1. Existierende Email verwenden falls vorhanden
        if let existingEmail = accommodation.email, 
           !existingEmail.isEmpty,
           isValidEmail(existingEmail) {
               print("[OK] Using existing email: \(existingEmail)")
            completion(existingEmail)
            return
        }
        
        // 2. Fallback Email generieren
        let generatedEmail = generateFallbackEmail(for: accommodation)
        print("Generated fallback email: \(generatedEmail)")
        completion(generatedEmail)
    }
    
    /// Generiert eine Fallback-Email basierend auf dem Hotel-Namen
    private func generateFallbackEmail(for accommodation: Accommodation) -> String {
        let hotelName = accommodation.name.lowercased()
        
        // Hotel-Namen bereinigen
        var cleanName = hotelName
            .replacingOccurrences(of: "hotel ", with: "")
            .replacingOccurrences(of: "resort ", with: "")
            .replacingOccurrences(of: "lodge ", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "&", with: "and")
        
        // Umlaute ersetzen
        cleanName = cleanName
            .replacingOccurrences(of: "ä", with: "ae")
            .replacingOccurrences(of: "ö", with: "oe")
            .replacingOccurrences(of: "ü", with: "ue")
            .replacingOccurrences(of: "ß", with: "ss")
        
        // Nur Buchstaben und Zahlen behalten
        cleanName = cleanName.filter { $0.isLetter || $0.isNumber }
        
        // Länge begrenzen
        if cleanName.count > 20 {
            cleanName = String(cleanName.prefix(20))
        }
        
        // Fallback falls zu kurz
        if cleanName.count < 3 {
            cleanName = "hotel\(abs(accommodation.name.hashValue))"
        }
        
        return "info@\(cleanName).com"
    }
    
    /// Einfache Email-Validierung
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}