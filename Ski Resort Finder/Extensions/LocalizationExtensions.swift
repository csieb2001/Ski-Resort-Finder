import Foundation

// Note: .localized extension is now defined in LocalizationService.swift
// This file contains specialized localization methods

extension String {
    
    /// Lokalisierte Ländernamen
    func localizedCountryName() -> String {
        let countryKey = "country_\(self.lowercased().replacingOccurrences(of: " ", with: "_"))"
        let localized = NSLocalizedString(countryKey, comment: "Country name")
        
        // Falls keine Übersetzung gefunden wurde, verwende den ursprünglichen Namen
        return localized != countryKey ? localized : self
    }
    
    /// Lokalisierte Wetterbeschreibungen
    func localizedWeatherDescription() -> String {
        let weatherKey = "weather_\(self.lowercased().replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "-", with: "_"))"
        let localized = NSLocalizedString(weatherKey, comment: "Weather description")
        
        // Falls keine Übersetzung gefunden wurde, verwende die ursprüngliche Beschreibung
        return localized != weatherKey ? localized : self.capitalized
    }
}

// MARK: - Weather Description Mapping
extension String {
    
    /// Mappt API Wetterbeschreibungen zu lokalisierten Keys
    func mappedWeatherDescription() -> String {
        let lowercased = self.lowercased()
        
        // OpenWeatherMap API Beschreibungen zu lokalisierten Keys mappen
        switch lowercased {
        case "clear sky", "klarer himmel":
            return "weather_clear_sky".localized
        case "few clouds", "wenige wolken":
            return "weather_few_clouds".localized
        case "scattered clouds", "vereinzelte wolken":
            return "weather_scattered_clouds".localized
        case "broken clouds", "aufgelockerte bewölkung":
            return "weather_broken_clouds".localized
        case "overcast clouds", "bedeckt":
            return "weather_overcast_clouds".localized
        case "shower rain", "schauer":
            return "weather_shower_rain".localized
        case "rain", "regen":
            return "weather_rain".localized
        case "thunderstorm", "gewitter":
            return "weather_thunderstorm".localized
        case "snow", "schnee":
            return "weather_snow".localized
        case "mist", "nebel":
            return "weather_mist".localized
        case "partly cloudy", "teilweise bewölkt":
            return "weather_partly_cloudy".localized
        case "cloudy", "bewölkt":
            return "weather_cloudy".localized
        case "light rain", "leichter regen":
            return "weather_light_rain".localized
        case "moderate rain", "mäßiger regen":
            return "weather_moderate_rain".localized
        case "heavy rain", "starker regen":
            return "weather_heavy_rain".localized
        case "light snow", "leichter schneefall":
            return "weather_light_snow".localized
        case "moderate snow", "mäßiger schneefall":
            return "weather_moderate_snow".localized
        case "heavy snow", "starker schneefall":
            return "weather_heavy_snow".localized
        default:
            // Fallback: Versuche generische Lokalisierung
            return self.localizedWeatherDescription()
        }
    }
}