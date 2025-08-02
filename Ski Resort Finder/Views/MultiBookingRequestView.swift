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
                contactDataSection
                travelPeriodSection
                guestDetailsSection
                messageSection
                accommodationsSection
                summarySection
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
                Text(safeLocalizedString("multi_booking_success_message", count: accommodations.count))
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
    
    // MARK: - View Components
    
    @ViewBuilder
    private var contactDataSection: some View {
        Section("contact_data".localized) {
            TextField("name".localized, text: $name)
            TextField("email".localized, text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            TextField("mobile_phone".localized, text: $phone)
                .keyboardType(.phonePad)
        }
    }
    
    @ViewBuilder
    private var travelPeriodSection: some View {
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
    }
    
    @ViewBuilder
    private var guestDetailsSection: some View {
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
    }
    
    @ViewBuilder
    private var messageSection: some View {
        Section("message".localized) {
            TextEditor(text: $message)
                .frame(minHeight: 100)
        }
    }
    
    @ViewBuilder
    private var accommodationsSection: some View {
        Section(safeLocalizedString("selected_accommodations", count: accommodations.count)) {
            ForEach(accommodations) { accommodation in
                accommodationRow(for: accommodation)
            }
        }
    }
    
    @ViewBuilder
    private func accommodationRow(for accommodation: Accommodation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(accommodation.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                // Only show rating if available (NO FAKE DATA policy)
                if let rating = accommodation.rating {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
    
    @ViewBuilder
    private var summarySection: some View {
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
                    // Only show average if we have ratings (NO FAKE DATA policy)
                    if let avgRating = averageRating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", avgRating))
                                .fontWeight(.semibold)
                        }
                    } else {
                        Text("—") // No ratings available
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var averageRating: Double? {
        let ratingsOnly = accommodations.compactMap { $0.rating }
        return ratingsOnly.isEmpty ? nil : ratingsOnly.reduce(0, +) / Double(ratingsOnly.count)
    }
    
    // MARK: - Methods
    
    private func setupUserData() {
        updateMessage()
    }
    
    private func updateMessage() {
        let startDateString = localization.formatDate(startDate)
        let endDateString = localization.formatDate(endDate)
        
        message = String(format: "booking_message_multi".localized, startDateString, endDateString, numberOfGuests, numberOfRooms)
    }
    
    private func loadSavedContactData() {
        loadOwnerContactInfo()
        
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
        case .denied, .restricted, .limited:
            print("Contacts access denied - using saved data only")
        @unknown default:
            break
        }
    }
    
    private func fetchOwnerContact(from store: CNContactStore) {
        do {
            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            
            try store.enumerateContacts(with: request) { contact, stop in
                let hasName = !contact.givenName.isEmpty || !contact.familyName.isEmpty
                let hasEmail = !contact.emailAddresses.isEmpty
                let hasPhone = !contact.phoneNumbers.isEmpty
                
                if hasName && (hasEmail || hasPhone) {
                    DispatchQueue.main.async {
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
                    stop.pointee = true
                }
            }
        } catch {
            print("Error fetching contacts: \(error.localizedDescription)")
        }
    }
    
    private func saveContactData() {
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
    
    private func sendMultipleRequests() {
        guard !accommodations.isEmpty else {
            print("ERROR: No accommodations to send requests to")
            return
        }
        
        isSending = true
        saveContactData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isSending = false
            self.showingAlert = true
        }
    }
    
    private func safeLocalizedString(_ key: String, count: Int) -> String {
        let localizedKey = "\(key)_count"
        let localized = NSLocalizedString(localizedKey, comment: "")
        
        if localized == localizedKey {
            switch key {
            case "selected_accommodations":
                return "Selected Accommodations (\(count))"
            case "multi_booking_success_message":
                return "Your booking requests have been sent to \(count) accommodations."
            default:
                return "\(key) (\(count))"
            }
        }
        
        return String.localizedStringWithFormat(localized, count)
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
                     pricePerNight: 195, rating: nil, 
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