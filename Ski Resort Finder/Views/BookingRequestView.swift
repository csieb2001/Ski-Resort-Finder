import SwiftUI
import Foundation
import MessageUI
import Contacts

struct BookingRequestView: View {
    let accommodation: Accommodation
    @State private var startDate: Date
    @State private var endDate: Date  
    @State private var numberOfGuests: Int
    @State private var numberOfRooms: Int
    
    // Initializer um Default-Werte zu setzen
    init(accommodation: Accommodation) {
        self.accommodation = accommodation
        self._startDate = State(initialValue: Date())
        self._endDate = State(initialValue: Date().addingTimeInterval(7 * 24 * 60 * 60)) // 7 Tage später
        self._numberOfGuests = State(initialValue: 2)
        self._numberOfRooms = State(initialValue: 1)
    }
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localization = LocalizationService.shared
    // Using SimpleEmailService for basic email functionality
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var message = ""
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingMailComposer = false
    @State private var showingContactOptions = false
    @State private var currentEmailAddress: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("your_contact_data".localized) {
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
                
                Section("accommodation".localized) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(accommodation.name)
                            .font(.headline)
                        Label("distance_to_lift_m".localized(with: accommodation.distanceToLift), 
                              systemImage: "figure.skiing.downhill")
                            .font(.caption)
                        // Preisanzeige entfernt - nur Dollar-Symbole werden verwendet
                        Text(accommodation.priceCategory.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorForPriceCategory(accommodation.priceCategory))
                        
                        // Kontaktinformationen anzeigen
                        Divider()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("contact_options".localized)
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            // E-Mail Section with Status and Found Emails
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.blue)
                                        .frame(width: 12)
                                    Text("E-Mail")
                                        .font(.caption)
                                    Spacer()
                                    emailStatusIndicator
                                }
                                
                                // Show accommodation email if available
                                if let originalEmail = accommodation.email, !originalEmail.isEmpty {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Button(action: {
                                            openEmailApp(email: originalEmail, hotelName: accommodation.name)
                                        }) {
                                            HStack {
                                                Text(originalEmail)
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                                    .underline()
                                                Spacer()
                                            }
                                        }
                                        
                                        Text("OpenStreetMap / Google Places")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .italic()
                                    }
                                    .padding(.leading, 24)
                                } else {
                                    Text("no_verified_contact_data".localized)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .italic()
                                        .padding(.leading, 24)
                                }
                            }
                            
                            
                            // Other contact methods (phone, website) - skip emails as they're shown above
                            ForEach(accommodation.availableContactMethods.filter { method in
                                // Only show non-email methods here
                                switch method {
                                case .email(_):
                                    return false // Skip emails - they're shown in the E-Mail section above
                                default:
                                    return true
                                }
                            }) { method in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: method.iconName)
                                            .foregroundColor(.blue)
                                            .frame(width: 12)
                                        Text(method.displayName)
                                            .font(.caption)
                                        Spacer()
                                    }
                                    
                                    // Kontaktdaten mit Quelle darunter
                                    VStack(alignment: .leading, spacing: 2) {
                                        Button(action: {
                                            handleContactMethodAction(method: method, hotelName: accommodation.name)
                                        }) {
                                            HStack {
                                                Text(method.value)
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                                    .underline()
                                                    .multilineTextAlignment(.leading)
                                                Spacer()
                                            }
                                        }
                                        
                                        Text(getContactMethodSource(method: method))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .italic()
                                    }
                                    .padding(.leading, 24) // Einrückung unter dem Icon
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("booking_request".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("contact".localized) {
                        sendBookingRequest()
                    }
                    .disabled(name.isEmpty || email.isEmpty || phone.isEmpty || !hasAvailableContactMethod)
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { 
                    if alertTitle == "Anfrage gesendet" {
                        dismiss() 
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .confirmationDialog("Kontaktmethode wählen", isPresented: $showingContactOptions) {
                ForEach(accommodation.availableContactMethods) { method in
                    Button(method.displayName) {
                        contactAccommodation(method: method)
                    }
                }
                Button("Abbrechen", role: .cancel) { }
            } message: {
                Text("Wie möchten Sie \(accommodation.name) kontaktieren?")
            }
            .sheet(isPresented: $showingMailComposer) {
                if MFMailComposeViewController.canSendMail() && !currentEmailAddress.isEmpty {
                    MailComposeView(
                        toRecipients: [currentEmailAddress],
                        subject: "Buchungsanfrage für \(accommodation.name)",
                        body: generateEmailBody()
                    )
                }
            }
        }
        .onAppear {
            setupUserData()
            loadSavedContactData()
            
            // Email search is now handled automatically by AccommodationDatabase
        }
        .onDisappear {
            saveContactData()
        }
    }
    
    // MARK: - Setup Functions
    
    private func setupUserData() {
        // Update the message with current values
        updateMessage()
    }
    
    private func updateMessage() {
        // Vorformulierte Nachricht mit Reisezeitraum und Gästeinformationen
        let startDateString = localization.formatDate(startDate)
        let endDateString = localization.formatDate(endDate)
        
        message = String(format: "booking_message_single".localized, accommodation.name, startDateString, endDateString, numberOfGuests, numberOfRooms)
    }
    
    // MARK: - Computed Properties
    
    private var hasAvailableContactMethod: Bool {
        return availableEmail != nil || accommodation.hasContactInfo
    }
    
    private var availableEmail: String? {
        // Use accommodation email if available
        return accommodation.email
    }
    
    // MARK: - Email Scraping Contact Methods
    
    private func sendBookingRequest() {
        saveContactData()
        
        Task {
            // Priority: Use found email if available
            if let scrapedEmail = availableEmail {
                await sendEmailRequest(to: scrapedEmail)
            } else if let originalEmail = accommodation.email {
                await sendEmailRequest(to: originalEmail)
            } else if let phone = accommodation.phone {
                makePhoneCall(to: phone)
            } else if let website = accommodation.website {
                openWebsite(website)
            } else {
                await MainActor.run {
                    alertTitle = "Keine Kontaktdaten verfügbar"
                    alertMessage = "Für diese Unterkunft stehen keine Kontaktdaten zur Verfügung."
                    showingAlert = true
                }
            }
        }
    }
    
    private func sendEmailRequest(to emailAddress: String) async {
        if MFMailComposeViewController.canSendMail() {
            // Use SwiftUI sheet for mail composer
            currentEmailAddress = emailAddress
            showingMailComposer = true
        } else {
            // Fallback: Open mail app
            let subject = "Buchungsanfrage für \(accommodation.name)"
            let body = generateEmailBody()
            
            let urlString = "mailto:\(emailAddress)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            
            if let mailURL = URL(string: urlString), UIApplication.shared.canOpenURL(mailURL) {
                await UIApplication.shared.open(mailURL)
                await showSuccessAlert("E-Mail geöffnet", "Die E-Mail-App wurde geöffnet. Bitte senden Sie Ihre Anfrage von dort aus.")
            } else {
                await showErrorAlert("E-Mail nicht möglich", "E-Mail konnte nicht geöffnet werden.")
            }
        }
    }
    
    @MainActor
    private func showErrorAlert(_ title: String, _ message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showingAlert = true
    }
    
    @MainActor
    private func showSuccessAlert(_ title: String, _ message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showingAlert = true
    }
    
    
    private func makePhoneCall(to phoneNumber: String) {
        let cleanedPhone = phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        if let phoneURL = URL(string: "tel:\(cleanedPhone)"), UIApplication.shared.canOpenURL(phoneURL) {
            UIApplication.shared.open(phoneURL)
        } else {
            alertTitle = "Anruf nicht möglich"
            alertMessage = "Anrufe sind auf diesem Gerät nicht verfügbar."
            showingAlert = true
        }
    }
    
    private func openWebsite(_ websiteURL: String) {
        if let url = URL(string: websiteURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            alertTitle = "Website geöffnet"
            alertMessage = "Die Website wurde geöffnet. Sie können dort direkt eine Buchungsanfrage stellen."
            showingAlert = true
        } else {
            alertTitle = "Website nicht verfügbar"
            alertMessage = "Die Website konnte nicht geöffnet werden."
            showingAlert = true
        }
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
        Task {
            let store = CNContactStore()
            
            // Berechtigung prüfen und anfordern falls nötig
            let authStatus = CNContactStore.authorizationStatus(for: .contacts)
            
            switch authStatus {
            case .authorized:
                await fetchOwnerContact(from: store)
            case .notDetermined:
                do {
                    let granted = try await store.requestAccess(for: .contacts)
                    if granted {
                        await fetchOwnerContact(from: store)
                    }
                } catch {
                    print("Error requesting contacts access: \(error.localizedDescription)")
                }
            case .denied, .restricted, .limited:
                // Keine Berechtigung - verwende leere Felder oder gespeicherte Daten
                print("Contacts access denied - using saved data only")
            @unknown default:
                break
            }
        }
    }
    
    private func fetchOwnerContact(from store: CNContactStore) async {
        // Direkt den "Mich"-Kontakt (iPhone Owner) abfragen
        do {
            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            
            // Versuche die "Me" Karte des iPhone Besitzers zu finden
            let predicate = CNContact.predicateForContacts(matchingName: "")
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            
            // Suche nach dem ersten Kontakt mit vollständigen Informationen
            // Da iOS keine direkte "Me" Contact API hat, nehmen wir den ersten brauchbaren
            for contact in contacts.prefix(3) { // Nur die ersten 3 prüfen für Performance
                let hasName = !contact.givenName.isEmpty || !contact.familyName.isEmpty
                let hasEmail = !contact.emailAddresses.isEmpty
                let hasPhone = !contact.phoneNumbers.isEmpty
                
                if hasName && (hasEmail || hasPhone) {
                    await MainActor.run {
                        // Nur setzen wenn die Felder noch leer sind (Benutzer kann überschreiben)
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
                        
                        print("✅ Owner contact info loaded: \(self.name), \(self.email), \(self.phone)")
                    }
                    return // Stoppe nach dem ersten brauchbaren Kontakt
                }
            }
            
            print("ℹ️ No suitable contact found - user can enter manually")
        } catch {
            print("❌ Error fetching contacts: \(error.localizedDescription)")
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
        // Hier ein einfacher Fallback
        return nil
    }
    
    private func getAmenityText() -> String {
        var amenities: [String] = []
        if accommodation.hasPool { amenities.append("Pool") }
        if accommodation.hasJacuzzi { amenities.append("Jacuzzi") }
        if accommodation.hasSpa { amenities.append("Spa") }
        
        if amenities.isEmpty {
            return ""
        } else {
            return "\n- " + amenities.joined(separator: "\n- ")
        }
    }
    
    private func colorForPriceCategory(_ category: Accommodation.PriceCategory) -> Color {
        switch category {
        case .budget:
            return .green
        case .mid:
            return .orange
        case .luxury:
            return .red
        }
    }
    
    // MARK: - Helper Functions
    
    private var emailStatusIndicator: some View {
        // Show status based on accommodation email availability
        let hasAnyEmail = accommodation.email != nil && !accommodation.email!.isEmpty
        
        return HStack(spacing: 4) {
            Circle()
                .fill(hasAnyEmail ? Color.green : Color.gray)
                .frame(width: 6, height: 6)
            
            Text(hasAnyEmail ? "email_found".localized : "email_not_found".localized)
                .font(.caption2)
                .foregroundColor(hasAnyEmail ? .green : .secondary)
        }
    }
    
    private func getSourceDisplayName(from source: String) -> String {
        // Umwandlung der technischen Quellennamen in benutzerfreundliche Namen
        if source.contains("contact") || source.contains("kontakt") {
            return "Kontaktseite"
        } else if source.contains("impressum") {
            return "Impressum"
        } else if source.contains("booking") || source.contains("reservation") {
            return "Buchungsseite"
        } else if source.contains("google") {
            return "Google Places"
        } else if source.contains("website") || source.contains("http") {
            // Extrahiere Domain aus URL
            if let url = URL(string: source), let host = url.host {
                return host.replacingOccurrences(of: "www.", with: "")
            }
            return "Website"
        } else if source == "Existing Data" {
            return "Hoteldaten"
        } else if source == "Website Scraping" {
            return "Webseite"
        } else if source == "Email Pattern" {
            return "Muster"
        } else {
            return "Gefunden"
        }
    }
    
    private func getContactMethodSource(method: ContactMethod) -> String {
        // Bestimme die Quelle der Kontaktmethode - könnte aus verschiedenen Quellen stammen
        switch method {
        case .email(_):
            // E-Mails können aus verschiedenen Quellen stammen
            return "OpenStreetMap / Google Places"
        case .phone(_):
            return "OpenStreetMap / Google Places"
        case .website(let website):
            // Versuche Domain zu extrahieren
            if let url = URL(string: website), let host = url.host {
                return host.replacingOccurrences(of: "www.", with: "")
            }
            return "OpenStreetMap / Google Places"
        }
    }
    
    // MARK: - Contact Methods
    
    private func openEmailApp(email: String, hotelName: String) {
        let subject = "Buchungsanfrage für \(hotelName)"
        let body = generateEmailBody()
        
        let urlString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let mailURL = URL(string: urlString), UIApplication.shared.canOpenURL(mailURL) {
            UIApplication.shared.open(mailURL)
            alertTitle = "email_app_opened".localized
            alertMessage = "email_app_opened_message".localized
            showingAlert = true
        } else {
            alertTitle = "email_error".localized
            alertMessage = "E-Mail konnte nicht geöffnet werden."
            showingAlert = true
        }
    }
    
    private func handleContactMethodAction(method: ContactMethod, hotelName: String) {
        switch method {
        case .email(let emailAddress):
            openEmailApp(email: emailAddress, hotelName: hotelName)
            
        case .phone(let phoneNumber):
            let cleanedPhone = phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
            if let phoneURL = URL(string: "tel:\(cleanedPhone)"), UIApplication.shared.canOpenURL(phoneURL) {
                UIApplication.shared.open(phoneURL)
            } else {
                alertTitle = "call_not_possible".localized
                alertMessage = "call_not_possible_message".localized
                showingAlert = true
            }
            
        case .website(let websiteURL):
            if let url = URL(string: websiteURL), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                alertTitle = "website_opened".localized
                alertMessage = "website_opened_message".localized
                showingAlert = true
            } else {
                alertTitle = "website_not_available".localized
                alertMessage = "website_not_available_message".localized
                showingAlert = true
            }
        }
    }
    
    private func contactAccommodation(method: ContactMethod) {
        switch method {
        case .email(let emailAddress):
            if MFMailComposeViewController.canSendMail() {
                showingMailComposer = true
            } else {
                // Fallback: E-Mail-App öffnen
                let mailURL = URL(string: "mailto:\(emailAddress)?subject=Buchungsanfrage%20für%20\(accommodation.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(generateEmailBody().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!
                if UIApplication.shared.canOpenURL(mailURL) {
                    UIApplication.shared.open(mailURL)
                    alertTitle = "E-Mail geöffnet"
                    alertMessage = "Die E-Mail-App wurde geöffnet. Bitte senden Sie Ihre Anfrage von dort aus."
                    showingAlert = true
                }
            }
            
        case .phone(let phoneNumber):
            let cleanedPhone = phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
            if let phoneURL = URL(string: "tel:\(cleanedPhone)"), UIApplication.shared.canOpenURL(phoneURL) {
                UIApplication.shared.open(phoneURL)
            } else {
                alertTitle = "Anruf nicht möglich"
                alertMessage = "Anrufe sind auf diesem Gerät nicht verfügbar oder die Telefonnummer ist ungültig."
                showingAlert = true
            }
            
        case .website(let websiteURL):
            if let url = URL(string: websiteURL), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                alertTitle = "Website geöffnet"
                alertMessage = "Die Website wurde geöffnet. Sie können dort direkt eine Buchungsanfrage stellen."
                showingAlert = true
            } else {
                alertTitle = "Website nicht verfügbar"
                alertMessage = "Die Website konnte nicht geöffnet werden."
                showingAlert = true
            }
        }
    }
    
    private func generateEmailBody() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = Locale(identifier: "de_DE")
        
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        // Safely get resort information
        let resort = accommodation.resort
        let resortName = resort.name
        
        // Safely get country name with fallback
        let countryName = resort.country
        
        let regionName = resort.region
        
        // Safely get accommodation properties
        let accommodationName = accommodation.name.isEmpty ? "Unbekannt" : accommodation.name
        let distanceToLift = accommodation.distanceToLift
        let priceCategory = accommodation.priceCategory.rawValue
        
        // Safely get user input
        let userName = name.isEmpty ? "Nicht angegeben" : name
        let userEmail = email.isEmpty ? "Nicht angegeben" : email
        let userPhone = phone.isEmpty ? "Nicht angegeben" : phone
        let userMessage = message.isEmpty ? "Keine zusätzlichen Informationen" : message
        let finalName = name.isEmpty ? "Ski Resort Finder Nutzer" : name
        
        // Build email body safely
        return """
        Sehr geehrte Damen und Herren,
        
        ich interessiere mich für eine Buchung in Ihrem Hotel \(accommodationName) für den Zeitraum vom \(startDateString) bis \(endDateString).
        
        Buchungsdetails:
        - Anzahl Gäste: \(numberOfGuests)
        - Anzahl Zimmer: \(numberOfRooms)
        
        Meine Kontaktdaten:
        Name: \(userName)
        E-Mail: \(userEmail)  
        Mobiltelefon: \(userPhone)
        
        Nachricht:
        \(userMessage)
        
        Hoteldetails:
        - Entfernung zur Liftstation: \(distanceToLift) Meter
        - Preiskategorie: \(priceCategory)
        - Skigebiet: \(resortName), \(countryName), \(regionName)
        
        Ich freue mich auf Ihre Antwort.
        
        Mit freundlichen Grüßen
        \(finalName)
        """
    }
}

// MARK: - Mail Compose View

struct MailComposeView: UIViewControllerRepresentable {
    let toRecipients: [String]
    let subject: String
    let body: String
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        mailComposer.setToRecipients(toRecipients)
        mailComposer.setSubject(subject)
        mailComposer.setMessageBody(body, isHTML: false)
        return mailComposer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}