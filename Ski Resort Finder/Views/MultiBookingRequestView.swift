import SwiftUI
import Foundation
import MapKit
import Contacts

struct MultiBookingRequestView: View {
    let accommodations: [Accommodation]
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var numberOfGuests: Int
    @State private var numberOfRooms: Int
    
    // Initializer um Default-Werte zu setzen
    init(accommodations: [Accommodation]) {
        self.accommodations = accommodations
        self._startDate = State(initialValue: Date())
        self._endDate = State(initialValue: Date().addingTimeInterval(7 * 24 * 60 * 60)) // 7 Tage später
        self._numberOfGuests = State(initialValue: 2)
        self._numberOfRooms = State(initialValue: 1)
    }
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localization = LocalizationService.shared
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var message = ""
    @State private var showingAlert = false
    @State private var isSending = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("contact_data".localized) {
                    TextField("name".localized, text: $name)
                    TextField("email".localized, text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("mobile_phone".localized, text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("travel_period".localized) {
                    DatePicker("from".localized, selection: $startDate, displayedComponents: .date)
                        .onChange(of: startDate) { _, _ in
                            updateMessage()
                        }
                    DatePicker("to".localized, selection: $endDate, displayedComponents: .date)
                        .onChange(of: endDate) { _, _ in
                            updateMessage()
                        }
                }
                
                Section("guest_details".localized) {
                    Stepper("guests_count".localized(with: numberOfGuests), value: $numberOfGuests, in: 1...10)
                        .onChange(of: numberOfGuests) { _, _ in
                            updateMessage()
                        }
                    Stepper("rooms_count".localized(with: numberOfRooms), value: $numberOfRooms, in: 1...5)
                        .onChange(of: numberOfRooms) { _, _ in
                            updateMessage()
                        }
                }
                
                Section("message".localized) {
                    TextEditor(text: $message)
                        .frame(minHeight: 100)
                }
                
                Section("selected_accommodations_count".localized(with: accommodations.count)) {
                    ForEach(accommodations) { accommodation in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(accommodation.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f", accommodation.rating))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Label("distance_to_lift_m".localized(with: accommodation.distanceToLift), 
                                  systemImage: "figure.skiing.downhill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            HStack {
                                Text(accommodation.priceCategory.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Text("per_night".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                // Wellness Features
                                HStack(spacing: 4) {
                                    if accommodation.hasPool {
                                        Image(systemName: "drop.fill")
                                            .foregroundColor(.cyan)
                                            .font(.caption)
                                    }
                                    if accommodation.hasJacuzzi {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(.purple)
                                            .font(.caption)
                                    }
                                    if accommodation.hasSpa {
                                        Image(systemName: "leaf.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    }
                                }
                            }
                            
                            if !accommodation.isRealData {
                                Text("demo_data".localized)
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("summary".localized)
                            .font(.headline)
                        
                        HStack {
                            Text("total_requests".localized)
                            Spacer()
                            Text("\(accommodations.count)")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("price_categories".localized)
                            Spacer()
                            let categories = Set(accommodations.map({ $0.priceCategory.rawValue })).sorted()
                            Text(categories.joined(separator: " "))
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("average_rating".localized)
                            Spacer()
                            let avgRating = accommodations.map({ $0.rating }).reduce(0, +) / Double(accommodations.count)
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", avgRating))
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .navigationTitle("multi_booking_request".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        sendMultipleRequests()
                    }) {
                        if isSending {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("sending".localized)
                            }
                        } else {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("send_all".localized)
                            }
                        }
                    }
                    .disabled(name.isEmpty || email.isEmpty || phone.isEmpty || isSending)
                }
            }
            .alert("requests_sent".localized, isPresented: $showingAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("multi_booking_success_message".localized(with: accommodations.count))
            }
        }
        .onAppear {
            setupUserData()
            loadSavedContactData()
        }
        .onDisappear {
            saveContactData()
        }
    }
    
    private func setupUserData() {
        // Update the message with current values
        updateMessage()
    }
    
    private func updateMessage() {
        // Vorformulierte Nachricht mit Reisezeitraum und Gästeinformationen für mehrere Hotels
        let startDateString = localization.formatDate(startDate)
        let endDateString = localization.formatDate(endDate)
        
        message = String(format: "booking_message_multi".localized, startDateString, endDateString, numberOfGuests, numberOfRooms)
    }
    
    private func generateEmailBody(for accommodation: Accommodation) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = Locale(identifier: "de_DE")
        
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        return """
        Sehr geehrte Damen und Herren,
        
        ich interessiere mich für eine Buchung in Ihrem Hotel \(accommodation.name) für den Zeitraum vom \(startDateString) bis \(endDateString).
        
        Buchungsdetails:
        - Anzahl Gäste: \(numberOfGuests)
        - Anzahl Zimmer: \(numberOfRooms)
        
        Meine Kontaktdaten:
        Name: \(name)
        E-Mail: \(email)
        Mobiltelefon: \(phone)
        
        Nachricht:
        \(message)
        
        Hoteldetails:
        - Entfernung zur Liftstation: \(accommodation.distanceToLift) Meter
        - Preiskategorie: \(accommodation.priceCategory.rawValue)
        - Skigebiet: \(accommodation.resort.name), \(accommodation.resort.country.localizedCountryName())
        
        Ich freue mich auf Ihre Antwort.
        
        Mit freundlichen Grüßen
        \(name)
        """
    }
    
    private func loadSavedContactData() {
        // Erst versuchen iPhone-Besitzer Kontaktdaten zu laden
        loadOwnerContactInfo()
        
        // Dann gespeicherte Kontaktdaten laden (überschreibt nur wenn sie existieren)
        if let savedName = UserDefaults.standard.string(forKey: "SavedContactName"), !savedName.isEmpty {
            name = savedName
        }
        if let savedEmail = UserDefaults.standard.string(forKey: "SavedContactEmail"), !savedEmail.isEmpty {
            email = savedEmail
        }
        if let savedPhone = UserDefaults.standard.string(forKey: "SavedContactPhone"), !savedPhone.isEmpty {
            phone = savedPhone
        }
    }
    
    private func loadOwnerContactInfo() {
        let store = CNContactStore()
        
        // Berechtigung prüfen und anfordern falls nötig
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        switch authStatus {
        case .authorized:
            fetchOwnerContact(from: store)
        case .notDetermined:
            store.requestAccess(for: .contacts) { [self] granted, error in
                DispatchQueue.main.async {
                    if granted {
                        self.fetchOwnerContact(from: store)
                    }
                }
            }
        case .denied, .restricted:
            // Keine Berechtigung - verwende leere Felder oder gespeicherte Daten
            print("Contacts access denied - using saved data only")
        @unknown default:
            break
        }
    }
    
    private func fetchOwnerContact(from store: CNContactStore) {
        // Versuche den "Mich"-Kontakt zu finden (Owner des iPhones)
        do {
            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            
            // Alle Kontakte durchsuchen und den ersten mit vollständigen Informationen nehmen
            // Dies ist ein Fallback-Ansatz, da der "Me"-Kontakt nicht immer verfügbar ist
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            
            try store.enumerateContacts(with: request) { contact, stop in
                // Prüfe ob der Kontakt vollständige Informationen hat
                let hasName = !contact.givenName.isEmpty || !contact.familyName.isEmpty
                let hasEmail = !contact.emailAddresses.isEmpty
                let hasPhone = !contact.phoneNumbers.isEmpty
                
                if hasName && (hasEmail || hasPhone) {
                    DispatchQueue.main.async {
                        // Nur setzen wenn die Felder noch leer sind
                        if self.name.isEmpty {
                            let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
                            if !fullName.isEmpty {
                                self.name = fullName
                            }
                        }
                        
                        if self.email.isEmpty && !contact.emailAddresses.isEmpty {
                            self.email = contact.emailAddresses.first?.value as String? ?? ""
                        }
                        
                        if self.phone.isEmpty && !contact.phoneNumbers.isEmpty {
                            let phoneNumber = contact.phoneNumbers.first?.value.stringValue ?? ""
                            self.phone = phoneNumber
                        }
                    }
                    stop.pointee = true // Stoppe nach dem ersten brauchbaren Kontakt
                }
            }
        } catch {
            print("Error fetching contacts: \(error.localizedDescription)")
        }
    }
    
    private func saveContactData() {
        // Kontaktdaten speichern (nur wenn sie nicht leer sind)
        if !name.isEmpty {
            UserDefaults.standard.set(name, forKey: "SavedContactName")
        }
        if !email.isEmpty {
            UserDefaults.standard.set(email, forKey: "SavedContactEmail")
        }
        if !phone.isEmpty {
            UserDefaults.standard.set(phone, forKey: "SavedContactPhone")
        }
    }
    
    private func getUserEmail() -> String? {
        // Versuche E-Mail vom System zu holen - in einer echten App würde man
        // Contacts Framework verwenden, aber das erfordert Permissions
        return nil
    }
    
    private func sendMultipleRequests() {
        isSending = true
        
        // Simulate sending requests to all accommodations
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isSending = false
            showingAlert = true
        }
    }
}

#Preview {
    let sampleAccommodations = [
        Accommodation(name: "Alpine Wellness Hotel", distanceToLift: 50, 
                     hasPool: true, hasJacuzzi: true, hasSpa: true,
                     pricePerNight: 280, rating: 4.8, 
                     imageUrl: "hotel1", resort: SkiResort(
                        name: "St. Anton",
                        country: "Austria", 
                        region: "Tirol",
                        totalSlopes: 305,
                        maxElevation: 2811,
                        minElevation: 1304,
                        coordinate: CLLocationCoordinate2D(latitude: 47.1296, longitude: 10.2686),
                        liftCount: 88,
                        slopeBreakdown: SlopeBreakdown(greenSlopes: 22, blueSlopes: 123, redSlopes: 85, blackSlopes: 75)
                     ), isRealData: true),
        Accommodation(name: "Ski Lodge Deluxe", distanceToLift: 200, 
                     hasPool: true, hasJacuzzi: false, hasSpa: true,
                     pricePerNight: 195, rating: 4.5, 
                     imageUrl: "hotel2", resort: SkiResort(
                        name: "St. Anton",
                        country: "Austria", 
                        region: "Tirol",
                        totalSlopes: 305,
                        maxElevation: 2811,
                        minElevation: 1304,
                        coordinate: CLLocationCoordinate2D(latitude: 47.1296, longitude: 10.2686),
                        liftCount: 88,
                        slopeBreakdown: SlopeBreakdown(greenSlopes: 22, blueSlopes: 123, redSlopes: 85, blackSlopes: 75)
                     ), isRealData: false)
    ]
    
    MultiBookingRequestView(accommodations: sampleAccommodations)
}