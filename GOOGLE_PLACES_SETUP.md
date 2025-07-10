# Google Places API Setup für echte Hotelbilder

## Übersicht

Die App nutzt jetzt die Google Places API, um echte Hotelfotos statt Platzhalterbilder anzuzeigen. Dies verbessert die Nutzererfahrung erheblich.

## Setup-Schritte

### 1. Google Cloud Console Setup

1. Gehe zu [Google Cloud Console](https://console.cloud.google.com/)
2. Erstelle ein neues Projekt oder wähle ein existierendes
3. Aktiviere die **Places API**:
   - Navigiere zu "APIs & Services" > "Library"
   - Suche nach "Places API"
   - Klicke "Enable"

### 2. API Key erstellen

1. Gehe zu "APIs & Services" > "Credentials"
2. Klicke "Create Credentials" > "API Key"
3. Kopiere den generierten API Key
4. **Wichtig**: Beschränke den Key auf iOS-Apps für Sicherheit

### 3. API Key in der App konfigurieren

Öffne `GooglePlacesService.swift` und ersetze:

```swift
private let apiKey = "YOUR_GOOGLE_PLACES_API_KEY"
```

Mit deinem echten API Key:

```swift
private let apiKey = "AIzaSyC..."
```

## Kosten und Limits

### Kostenlose Nutzung
- **$200 monatliches Guthaben** von Google (ausreichend für ~28.000 Foto-Requests)
- **1.000 kostenlose Requests** pro Monat für neue Nutzer

### Preise pro 1.000 Requests
- **Text Search**: $32 (zum Finden der Hotels)
- **Place Details**: $17 (für Foto-Referenzen)  
- **Place Photos**: $7 (für die eigentlichen Bilder)

**Gesamt pro Hotel-Foto**: ~$0.056 (ca. 5,6 Cent)

### Rate Limits
- **100 Requests pro Sekunde** pro API Key
- Die App nutzt intelligentes Caching um Requests zu minimieren

## Funktionsweise

1. **Hotel Search**: App sucht Hotel per Name + Location
2. **Place Details**: Holt Foto-Referenzen für das gefundene Hotel
3. **Photo Loading**: Lädt das erste verfügbare Hotelfoto
4. **Fallback**: Bei Fehlern fällt die App auf Picsum Photos zurück

## Sicherheit

### Empfohlene Einstellungen:
- **Application restrictions**: Nur iOS-Apps
- **API restrictions**: Nur Places API
- **Rate limiting**: Aktiviert
- **Referrer restrictions**: Nur deine Bundle ID

## Debugging

Die App zeigt den Google Places API Status in der Debug-Seite:
- ✅ **Grün**: API funktioniert
- ❌ **Rot**: API Key fehlt oder ungültig
- 🟡 **Orange**: Test läuft

## Alternative: Kostenlose Nutzung

Falls du die Google API nicht nutzen möchtest:

1. Lass den API Key als `"YOUR_GOOGLE_PLACES_API_KEY"`
2. Die App fällt automatisch auf **Picsum Photos** zurück
3. Du bekommst weiterhin schöne Bilder, nur nicht hotelspezifisch

## Erweiterte Features (Optional)

### Hotel-Bewertungen hinzufügen:
```swift
// In PlaceDetails struct:
let rating: Double?
let user_ratings_total: Int?
```

### Mehrere Fotos pro Hotel:
```swift
// Alle Fotos laden statt nur das erste:
return detailsResponse.result?.photos?.map { $0.photo_reference }
```

### Caching implementieren:
```swift
// Photo URLs für 24h cachen um API-Calls zu reduzieren
private static var photoCache: [String: URL] = [:]
```

## Troubleshooting

### API Key funktioniert nicht:
1. Prüfe ob Places API aktiviert ist
2. Prüfe API Key Restrictions
3. Warte 1-2 Minuten nach Key-Erstellung
4. Prüfe Debug-Seite für Fehlermeldungen

### Keine Fotos gefunden:
- Hotels in abgelegenen Gebieten haben oft keine Fotos
- App fällt automatisch auf Picsum zurück
- Normal für ~20-30% der Anfragen

### Rate Limit erreicht:
- Implementiere exponential backoff
- Reduziere gleichzeitige Requests
- Nutze mehr Caching

## Support

Bei Fragen zur Google Places API:
- [Google Places API Dokumentation](https://developers.google.com/maps/documentation/places/web-service)
- [Pricing Calculator](https://mapsplatform.google.com/pricing/)
- [API Key Best Practices](https://cloud.google.com/docs/authentication/api-keys)