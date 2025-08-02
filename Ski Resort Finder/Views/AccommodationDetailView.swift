import SwiftUI
import Foundation

class AccommodationDetailViewModel: ObservableObject {
    @Published var hasPool = false
    @Published var hasJacuzzi = false
    @Published var hasSpa = false
    @Published var hasSauna = false
    @Published var email: String? = nil
    @Published var isLoadingEmail = false
    @Published var isLoadingWellness = false
    
    init(accommodation: Accommodation) {
        self.hasPool = accommodation.hasPool
        self.hasJacuzzi = accommodation.hasJacuzzi
        self.hasSpa = accommodation.hasSpa
        self.hasSauna = accommodation.hasSauna
        self.email = accommodation.email
    }
    
    func updateSpaFeatures(pool: Bool, jacuzzi: Bool, spa: Bool, sauna: Bool) {
        print("🔄 ViewModel updating spa features: Pool=\(pool), Jacuzzi=\(jacuzzi), Spa=\(spa), Sauna=\(sauna)")
        DispatchQueue.main.async {
            self.hasPool = pool
            self.hasJacuzzi = jacuzzi
            self.hasSpa = spa
            self.hasSauna = sauna
        }
    }
    
    func updateEmail(_ newEmail: String?) {
        print("🔄 ViewModel updating email: \(newEmail ?? "nil")")
        DispatchQueue.main.async {
            self.email = newEmail
        }
    }
    
    var hasSpaFeatures: Bool {
        return hasPool || hasJacuzzi || hasSpa || hasSauna
    }
}

struct AccommodationDetailView: View {
    let accommodation: Accommodation
    let onAccommodationUpdated: ((Accommodation) -> Void)?
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localization = LocalizationService.shared
    @StateObject private var screenshotService = WebsiteScreenshotService.shared
    @ObservedObject private var emailService = AdvancedEmailService.shared
    @StateObject private var uiViewModel: AccommodationDetailViewModel
    @State private var currentAccommodation: Accommodation
    @State private var websiteScreenshot: UIImage?
    @State private var isLoadingScreenshot = false
    @State private var selectedAccommodation: Accommodation?
    @State private var refreshTrigger = UUID()
    
    init(accommodation: Accommodation, onAccommodationUpdated: ((Accommodation) -> Void)? = nil) {
        self.accommodation = accommodation
        self.onAccommodationUpdated = onAccommodationUpdated
        self._currentAccommodation = State(initialValue: accommodation)
        self._uiViewModel = StateObject(wrappedValue: AccommodationDetailViewModel(accommodation: accommodation))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    
                    // Website Screenshot Section
                    if let website = currentAccommodation.website, !website.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("hotel_website".localized)
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 250)
                                    .cornerRadius(DesignSystem.CornerRadius.md)
                                
                                if isLoadingScreenshot {
                                    VStack(spacing: DesignSystem.Spacing.sm) {
                                        ProgressView()
                                            .scaleEffect(1.2)
                                        Text("loading_website_screenshot".localized)
                                            .font(DesignSystem.Typography.caption1)
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                } else if let screenshot = websiteScreenshot {
                                    Image(uiImage: screenshot)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 250)
                                        .cornerRadius(DesignSystem.CornerRadius.md)
                                        .clipped()
                                } else {
                                    VStack(spacing: DesignSystem.Spacing.sm) {
                                        Image(systemName: "globe")
                                            .font(.largeTitle)
                                            .foregroundColor(DesignSystem.Colors.primary)
                                        
                                        Button(action: {
                                            loadWebsiteScreenshot()
                                        }) {
                                            Text("load_website_screenshot".localized)
                                                .font(DesignSystem.Typography.callout)
                                                .foregroundColor(DesignSystem.Colors.primary)
                                                .padding(.horizontal, DesignSystem.Spacing.md)
                                                .padding(.vertical, DesignSystem.Spacing.sm)
                                                .background(DesignSystem.Colors.primary.opacity(0.1))
                                                .cornerRadius(DesignSystem.CornerRadius.sm)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Accommodation Info
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        
                        // Basic Info
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text(currentAccommodation.name)
                                .font(DesignSystem.Typography.title2)
                                .fontWeight(.bold)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            HStack(spacing: DesignSystem.Spacing.md) {
                                Label(String(format: "distance_to_lift".localized, currentAccommodation.distanceToLift), systemImage: "figure.skiing.downhill")
                                    .font(DesignSystem.Typography.subheadline)
                                    .foregroundColor(DesignSystem.Colors.primary)
                                
                                // Only show rating if available (NO FAKE DATA policy)
                                if let rating = currentAccommodation.rating {
                                    HStack(spacing: DesignSystem.Spacing.xs) {
                                        Image(systemName: "star.fill")
                                            .font(DesignSystem.Typography.subheadline)
                                            .foregroundColor(DesignSystem.Colors.accent)
                                        Text(String(format: "%.1f", rating))
                                            .font(DesignSystem.Typography.subheadline)
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(currentAccommodation.priceCategory.rawValue)
                                    .font(DesignSystem.Typography.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(colorForPriceCategory(currentAccommodation.priceCategory))
                            }
                        }
                        
                        Divider()
                        
                        // Amenities
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("amenities".localized)
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            if uiViewModel.isLoadingWellness {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("loading_wellness_features".localized)
                                        .font(DesignSystem.Typography.subheadline)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                    Spacer()
                                }
                                .padding(.vertical, DesignSystem.Spacing.sm)
                            } else if uiViewModel.hasSpaFeatures {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignSystem.Spacing.sm) {
                                    if uiViewModel.hasPool {
                                        AmenityRow(icon: "drop.fill", text: "pool".localized, color: .cyan)
                                    }
                                    if uiViewModel.hasJacuzzi {
                                        AmenityRow(icon: "sparkles", text: "jacuzzi".localized, color: .purple)
                                    }
                                    if uiViewModel.hasSpa {
                                        AmenityRow(icon: "leaf.fill", text: "spa".localized, color: .green)
                                    }
                                    if uiViewModel.hasSauna {
                                        AmenityRow(icon: "thermometer.sun.fill", text: "sauna".localized, color: .orange)
                                    }
                                }
                            } else {
                                Text("no_spa_features".localized)
                                    .font(DesignSystem.Typography.subheadline)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .padding(.vertical, DesignSystem.Spacing.sm)
                            }
                        }
                        
                        Divider()
                        
                        // Contact Information
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("contact_information".localized)
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            // Email section with on-demand loading
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                if let email = uiViewModel.email, !email.isEmpty {
                                    ContactRow(icon: "envelope.fill", text: email, type: .email)
                                } else {
                                    HStack {
                                        Image(systemName: "envelope")
                                            .font(DesignSystem.Typography.subheadline)
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                            .frame(width: 20)
                                        
                                        if uiViewModel.isLoadingEmail {
                                            HStack(spacing: DesignSystem.Spacing.xs) {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                                Text("email_searching".localized)
                                                    .font(DesignSystem.Typography.subheadline)
                                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                            }
                                        } else {
                                            Button(action: {
                                                loadEmailForAccommodation()
                                            }) {
                                                Text("search_email".localized)
                                                    .font(DesignSystem.Typography.subheadline)
                                                    .foregroundColor(DesignSystem.Colors.primary)
                                                    .padding(.horizontal, DesignSystem.Spacing.sm)
                                                    .padding(.vertical, DesignSystem.Spacing.xs)
                                                    .background(DesignSystem.Colors.primary.opacity(0.1))
                                                    .cornerRadius(DesignSystem.CornerRadius.sm)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                }
                            }
                            
                            if let phone = currentAccommodation.phone, !phone.isEmpty {
                                ContactRow(icon: "phone.fill", text: phone, type: .phone)
                            }
                            
                            if let website = currentAccommodation.website, !website.isEmpty {
                                ContactRow(icon: "globe", text: website, type: .website)
                            }
                        }
                        
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
            .id(refreshTrigger) // Force refresh when this changes
            .navigationTitle("accommodation_details".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close".localized) { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Booking Request Button
                Button(action: {
                    selectedAccommodation = currentAccommodation
                }) {
                    Text("make_booking_request".localized)
                        .font(DesignSystem.Typography.calloutEmphasized)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hasCurrentEmailAvailable ? DesignSystem.Colors.primary : DesignSystem.Colors.quaternaryText)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                }
                .disabled(!hasCurrentEmailAvailable)
                .padding()
                .background(DesignSystem.Colors.background)
            }
        }
        .sheet(item: $selectedAccommodation) { _ in
            BookingRequestView(accommodation: currentAccommodation)
        }
        .onAppear {
            // Sync viewModel with the passed accommodation first
            currentAccommodation = accommodation
            print("🏨 Detail view appeared for \(currentAccommodation.name)")
            print("🏨 Initial spa features: Pool=\(currentAccommodation.hasPool), Jacuzzi=\(currentAccommodation.hasJacuzzi), Spa=\(currentAccommodation.hasSpa), Sauna=\(currentAccommodation.hasSauna)")
            // Auto-load all data when view appears
            loadAllDataOnAppear()
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadAllDataOnAppear() {
        // 1. Auto-load email if not available
        if currentAccommodation.email == nil || currentAccommodation.email!.isEmpty {
            loadEmailForAccommodation()
        }
        
        // 2. Always auto-load wellness features to ensure we have the most complete data
        loadWellnessFeaturesForAccommodation()
        
        // 3. Auto-load website screenshot if website is available
        if let website = currentAccommodation.website, !website.isEmpty, websiteScreenshot == nil {
            loadWebsiteScreenshot()
        }
    }
    
    private func loadWebsiteScreenshot() {
        guard let website = currentAccommodation.website, !website.isEmpty else { return }
        
        isLoadingScreenshot = true
        
        Task {
            let screenshot = await screenshotService.generateScreenshot(
                from: website,
                accommodationName: currentAccommodation.name
            )
            
            await MainActor.run {
                self.websiteScreenshot = screenshot
                self.isLoadingScreenshot = false
            }
        }
    }
    
    private var hasCurrentEmailAvailable: Bool {
        return uiViewModel.email != nil && !uiViewModel.email!.isEmpty
    }
    
    private func loadEmailForAccommodation() {
        uiViewModel.isLoadingEmail = true
        
        emailService.findBestEmail(for: currentAccommodation) { result in
            DispatchQueue.main.async {
                self.uiViewModel.isLoadingEmail = false
                
                if let emailResult = result, emailResult.isValid {
                    // Update UI ViewModel first for immediate UI feedback
                    self.uiViewModel.updateEmail(emailResult.email)
                    
                    // Update currentAccommodation with found email (preserve ID)
                    self.currentAccommodation = Accommodation(
                        id: self.currentAccommodation.id,
                        name: self.currentAccommodation.name,
                        distanceToLift: self.currentAccommodation.distanceToLift,
                        hasPool: self.currentAccommodation.hasPool,
                        hasJacuzzi: self.currentAccommodation.hasJacuzzi,
                        hasSpa: self.currentAccommodation.hasSpa,
                        hasSauna: self.currentAccommodation.hasSauna,
                        pricePerNight: self.currentAccommodation.pricePerNight,
                        rating: self.currentAccommodation.rating,
                        imageUrl: self.currentAccommodation.imageUrl,
                        imageUrls: self.currentAccommodation.imageUrls,
                        resort: self.currentAccommodation.resort,
                        isRealData: self.currentAccommodation.isRealData,
                        email: emailResult.email,
                        phone: self.currentAccommodation.phone,
                        website: self.currentAccommodation.website,
                        coordinate: self.currentAccommodation.coordinate
                    )
                    
                    // Notify parent about the update
                    self.onAccommodationUpdated?(self.currentAccommodation)
                    
                    print("✅ E-Mail gefunden für \(self.currentAccommodation.name): \(emailResult.email) (Qualität: \(emailResult.quality.description))")
                } else {
                    print("❌ Keine E-Mail gefunden für \(self.currentAccommodation.name)")
                }
            }
        }
    }
    
    private func loadWellnessFeaturesForAccommodation() {
        print("🏊‍♀️ Auto-loading wellness features for \(currentAccommodation.name)")
        uiViewModel.isLoadingWellness = true
        
        emailService.processEmailsAndWellnessFeatures(for: [currentAccommodation]) { emailResults, wellnessResults in
            DispatchQueue.main.async {
                print("🏊‍♀️ Wellness search completed for \(self.currentAccommodation.name)")
                print("🏊‍♀️ Found \(wellnessResults.count) wellness results")
                
                // Update wellness features if found
                if let wellnessResult = wellnessResults[self.currentAccommodation.name], wellnessResult.confidence > 0.5 {
                    print("🏊‍♀️ Using wellness result with confidence \(wellnessResult.confidence)")
                    
                    // Update UI ViewModel FIRST for immediate UI feedback
                    let newPool = self.currentAccommodation.hasPool || wellnessResult.hasPool
                    let newJacuzzi = self.currentAccommodation.hasJacuzzi || wellnessResult.hasJacuzzi
                    let newSpa = self.currentAccommodation.hasSpa || wellnessResult.hasSpa
                    let newSauna = self.currentAccommodation.hasSauna || wellnessResult.hasSauna
                    
                    self.uiViewModel.updateSpaFeatures(pool: newPool, jacuzzi: newJacuzzi, spa: newSpa, sauna: newSauna)
                    
                    // Update backing data (preserve ID)
                    self.currentAccommodation = Accommodation(
                        id: self.currentAccommodation.id,
                        name: self.currentAccommodation.name,
                        distanceToLift: self.currentAccommodation.distanceToLift,
                        hasPool: newPool,
                        hasJacuzzi: newJacuzzi,
                        hasSpa: newSpa,
                        hasSauna: newSauna,
                        pricePerNight: self.currentAccommodation.pricePerNight,
                        rating: self.currentAccommodation.rating,
                        imageUrl: self.currentAccommodation.imageUrl,
                        imageUrls: self.currentAccommodation.imageUrls,
                        resort: self.currentAccommodation.resort,
                        isRealData: self.currentAccommodation.isRealData,
                        email: self.currentAccommodation.email,
                        phone: self.currentAccommodation.phone,
                        website: self.currentAccommodation.website,
                        coordinate: self.currentAccommodation.coordinate
                    )
                    
                    print("✅ Wellness features updated for \(self.currentAccommodation.name): Pool=\(wellnessResult.hasPool), Jacuzzi=\(wellnessResult.hasJacuzzi), Spa=\(wellnessResult.hasSpa), Sauna=\(wellnessResult.hasSauna)")
                    print("✅ UI ViewModel spa features: \(self.uiViewModel.hasSpaFeatures)")
                    
                    // Notify parent about the wellness features update
                    self.onAccommodationUpdated?(self.currentAccommodation)
                } else {
                    print("🏊‍♀️ No wellness features found or confidence too low for \(self.currentAccommodation.name)")
                    if let wellnessResult = wellnessResults[self.currentAccommodation.name] {
                        print("🏊‍♀️ Confidence was \(wellnessResult.confidence), required > 0.5")
                    }
                }
                
                // Also update email if found and not already available
                if self.currentAccommodation.email == nil || self.currentAccommodation.email!.isEmpty,
                   let emailResult = emailResults[self.currentAccommodation.name], emailResult.isValid {
                    self.currentAccommodation = Accommodation(
                        id: self.currentAccommodation.id,
                        name: self.currentAccommodation.name,
                        distanceToLift: self.currentAccommodation.distanceToLift,
                        hasPool: self.currentAccommodation.hasPool,
                        hasJacuzzi: self.currentAccommodation.hasJacuzzi,
                        hasSpa: self.currentAccommodation.hasSpa,
                        hasSauna: self.currentAccommodation.hasSauna,
                        pricePerNight: self.currentAccommodation.pricePerNight,
                        rating: self.currentAccommodation.rating,
                        imageUrl: self.currentAccommodation.imageUrl,
                        imageUrls: self.currentAccommodation.imageUrls,
                        resort: self.currentAccommodation.resort,
                        isRealData: self.currentAccommodation.isRealData,
                        email: emailResult.email,
                        phone: self.currentAccommodation.phone,
                        website: self.currentAccommodation.website,
                        coordinate: self.currentAccommodation.coordinate
                    )
                    
                    print("✅ Email also updated for \(self.currentAccommodation.name): \(emailResult.email)")
                    
                    // Force UI refresh
                    self.refreshTrigger = UUID()
                    
                    // Notify parent about the email update
                    self.onAccommodationUpdated?(self.currentAccommodation)
                }
                
                print("🏊‍♀️ Wellness loading completed. Loading state: false")
                self.uiViewModel.isLoadingWellness = false
            }
        }
    }
    
    private func colorForPriceCategory(_ category: Accommodation.PriceCategory) -> Color {
        switch category {
        case .budget:
            return DesignSystem.Colors.success
        case .mid:
            return DesignSystem.Colors.warning
        case .luxury:
            return DesignSystem.Colors.error
        }
    }
}

// MARK: - Supporting Views

struct AmenityRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Spacer()
        }
    }
}

enum ContactType {
    case email, phone, website
}

struct ContactRow: View {
    let icon: String
    let text: String
    let type: ContactType
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 20)
            
            Text(text)
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(1)
            
            Spacer()
            
            Button(action: {
                handleContact()
            }) {
                Image(systemName: "arrow.up.right.square")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.primary)
            }
        }
    }
    
    private func handleContact() {
        switch type {
        case .email:
            if let url = URL(string: "mailto:\\(text)") {
                UIApplication.shared.open(url)
            }
        case .phone:
            if let url = URL(string: "tel:\\(text)") {
                UIApplication.shared.open(url)
            }
        case .website:
            if let url = URL(string: text) {
                UIApplication.shared.open(url)
            }
        }
    }
}

#Preview {
    AccommodationDetailView(
        accommodation: Accommodation(
            name: "Alpine Wellness Hotel",
            distanceToLift: 150,
            hasPool: true,
            hasJacuzzi: true,
            hasSpa: true,
            hasSauna: false,
            pricePerNight: 280,
            rating: 4.5,
            imageUrl: "",
            imageUrls: [],
            resort: SkiResort(
                name: "Test Resort",
                country: "Austria",
                region: "Tyrol",
                totalSlopes: 100,
                maxElevation: 3000,
                minElevation: 1000,
                coordinate: .init(latitude: 47.0, longitude: 10.0),
                liftCount: 20
            ),
            isRealData: true,
            email: "info@alpine-wellness.com",
            phone: "+43 1234567890",
            website: "https://www.alpine-wellness.com",
            coordinate: .init(latitude: 47.0, longitude: 10.0)
        )
    )
}