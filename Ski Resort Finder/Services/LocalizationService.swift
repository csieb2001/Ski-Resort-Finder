import Foundation
import SwiftUI

class LocalizationService: ObservableObject {
    nonisolated(unsafe) static let shared = LocalizationService()

    @Published var currentLanguage: SupportedLanguage = .system {
        didSet {
            updateLanguage()
        }
    }
    
    private init() {
        // Automatische Spracherkennung beim Start
        detectSystemLanguage()
    }
    
    /// Verfügbare Sprachen
    enum SupportedLanguage: String, CaseIterable {
        case system = "system"
        case german = "de"
        case english = "en"
        case french = "fr"
        case spanish = "es"
        case italian = "it"
        case portuguese = "pt"
        case russian = "ru"
        case ukrainian = "uk"
        
        var displayName: String {
            switch self {
            case .system:
                return "System"
            case .german:
                return "Deutsch"
            case .english:
                return "English"
            case .french:
                return "Français"
            case .spanish:
                return "Español"
            case .italian:
                return "Italiano"
            case .portuguese:
                return "Português"
            case .russian:
                return "Русский"
            case .ukrainian:
                return "Українська"
            }
        }
        
        var code: String {
            switch self {
            case .system:
                return Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
            case .german:
                return "de"
            case .english:
                return "en"
            case .french:
                return "fr"
            case .spanish:
                return "es"
            case .italian:
                return "it"
            case .portuguese:
                return "pt"
            case .russian:
                return "ru"
            case .ukrainian:
                return "uk"
            }
        }
    }
    
    /// Erkennt die Systemsprache automatisch
    private func detectSystemLanguage() {
        let systemLanguageCode = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
        
        // Prüfe ob eine manuelle Spracheinstellung gespeichert ist
        let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage")
        
        if let savedLanguage = savedLanguage,
           let language = SupportedLanguage(rawValue: savedLanguage) {
            currentLanguage = language
        } else {
            // Automatische Erkennung basierend auf Systemsprache
            switch systemLanguageCode {
            case "de":
                currentLanguage = .german
            case "en":
                currentLanguage = .english
            case "fr":
                currentLanguage = .french
            case "es":
                currentLanguage = .spanish
            case "it":
                currentLanguage = .italian
            case "pt":
                currentLanguage = .portuguese
            case "ru":
                currentLanguage = .russian
            case "uk":
                currentLanguage = .ukrainian
            default:
                currentLanguage = .english // Fallback
            }
        }
    }
    
    /// Aktualisiert die Sprache
    private func updateLanguage() {
        // Speichere die Sprachauswahl
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage")
        
        // Sende Notification für UI-Updates
        NotificationCenter.default.post(name: .languageChanged, object: currentLanguage)
    }
    
    /// Lokalisiert einen String
    func localized(_ key: String, comment: String = "") -> String {
        let languageCode = currentLanguage.code
        
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Fallback auf Englisch
            guard let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
                  let bundle = Bundle(path: path) else {
                return key
            }
            return NSLocalizedString(key, bundle: bundle, comment: comment)
        }
        
        return NSLocalizedString(key, bundle: bundle, comment: comment)
    }
    
    /// Formatiert Datum lokalisiert
    func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.locale = Locale(identifier: currentLanguage.code)
        return formatter.string(from: date)
    }
    
    /// Formatiert Zahlen lokalisiert
    func formatNumber(_ number: Double, style: NumberFormatter.Style = .decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = style
        formatter.locale = Locale(identifier: currentLanguage.code)
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    /// Formatiert Währung lokalisiert
    func formatCurrency(_ amount: Double, currencyCode: String = "EUR") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: currentLanguage.code)
        return formatter.string(from: NSNumber(value: amount)) ?? "€\(amount)"
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let languageChanged = Notification.Name("LanguageChanged")
}

// MARK: - String Extension für einfache Lokalisierung

extension String {
    /// Lokalisiert einen String mit dem aktuellen LocalizationService
    var localized: String {
        return LocalizationService.shared.localized(self)
    }
    
    /// Lokalisiert einen String mit Parametern
    func localized(with arguments: CVarArg...) -> String {
        let localizedString = LocalizationService.shared.localized(self)
        return String(format: localizedString, arguments: arguments)
    }
}

// MARK: - SwiftUI Environment

struct LocalizationKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue = LocalizationService.shared
}

extension EnvironmentValues {
    var localization: LocalizationService {
        get { self[LocalizationKey.self] }
        set { self[LocalizationKey.self] = newValue }
    }
}