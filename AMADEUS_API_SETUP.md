# Amadeus API Setup Guide

## Aktueller Status
Die App zeigt "Amadeus API nicht verfügbar - OpenStreetMap Fallback wird verwendet" weil Demo-API-Schlüssel verwendet werden.

## Echte API-Schlüssel bekommen

### 1. Amadeus Developer Account erstellen
1. Gehen Sie zu: https://developers.amadeus.com
2. Klicken Sie auf "Register" (kostenlos)
3. Erstellen Sie ein Developer-Konto
4. Bestätigen Sie Ihre E-Mail-Adresse

### 2. API-Schlüssel generieren
1. Loggen Sie sich in Ihr Developer-Portal ein
2. Erstellen Sie eine neue "Application"
3. Notieren Sie sich:
   - **API Key** (Client ID)
   - **API Secret** (Client Secret)

### 3. API-Schlüssel in die App einbinden

Öffnen Sie die Datei:
```
Ski Resort Finder/Services/AmadeusHotelService.swift
```

Ersetzen Sie in Zeile 11-12:
```swift
private let apiKey = "DEMO_API_KEY_NOT_WORKING"
private let apiSecret = "DEMO_SECRET_NOT_WORKING"
```

Mit Ihren echten Schlüsseln:
```swift
private let apiKey = "HIER_IHR_ECHTER_API_KEY"
private let apiSecret = "HIER_IHR_ECHTER_SECRET"
```

## Amadeus API Limits (Test)
- **Kostenlos**: 1.000 API-Aufrufe pro Monat
- **Production**: Kostenpflichtig, aber viel höhere Limits

## Aktuell funktionierendes Fallback-System
Auch ohne Amadeus API funktioniert die App vollständig:

1. **OpenStreetMap API** - Echte Unterkunftsdaten von Hotels/Pensionen
2. **Open-Meteo API** - Kostenlose Wetterdaten
3. **Demo-Daten** - Als letzter Fallback

## Test der APIs
Verwenden Sie den Debug-Screen (ℹ️ Button) um alle APIs zu testen.

## Hinweise
- Die App funktioniert auch ohne Amadeus API vollständig
- OpenStreetMap-Daten sind oft ausreichend für Tests
- Amadeus bietet professionelle Hotel-Preise und Verfügbarkeit