import SwiftUI
import Foundation

struct AccommodationListView: View {
    @ObservedObject var viewModel: SkiResortViewModel
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localization = LocalizationService.shared
    @ObservedObject private var accommodationDB = AccommodationDatabase.shared
    @ObservedObject private var emailService = AdvancedEmailService.shared
    @State private var selectedAccommodation: Accommodation?
    @State private var showingMap = false
    @State private var selectedAccommodations: Set<UUID> = []
    @State private var showingMultiBooking = false
    @State private var isSelectionMode = false
    @State private var sortOption: SortOption = .distance
    @State private var showingSortOptions = false
    @State private var showingEmailOptions = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Mountain background
                MountainBackgroundView()
                    .ignoresSafeArea()
                
                Group {
                    if isLoadingAccommodations {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                                .scaleEffect(1.2)
                            
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                Text(loadingMessage)
                                    .font(DesignSystem.Typography.callout)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                
                                Text("searching_accommodations_radius".localized)
                                    .font(DesignSystem.Typography.caption1)
                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                                
                                if viewModel.accommodations.count > 0 {
                                    Text(String(format: "accommodations_found_live".localized, viewModel.accommodations.count))
                                        .font(DesignSystem.Typography.caption1)
                                        .fontWeight(.medium)
                                        .foregroundColor(DesignSystem.Colors.primary)
                                        .animation(.easeInOut(duration: 0.3), value: viewModel.accommodations.count)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                    ZStack {
                        VStack(spacing: 0) {
                            // Sort Options Bar with glass effect
                            VStack {
                                HStack {
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                                        if let selectedResort = viewModel.selectedResort {
                                            Text(selectedResort.name)
                                                .font(DesignSystem.Typography.callout)
                                                .fontWeight(.semibold)
                                                .foregroundColor(DesignSystem.Colors.primaryText)
                                        }
                                        
                                        Text("\(viewModel.accommodations.count) \("accommodations_found".localized)")
                                            .font(DesignSystem.Typography.caption1)
                                            .fontWeight(.medium)
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                        
                                        Text("scan_tip".localized)
                                            .font(DesignSystem.Typography.caption2)
                                            .foregroundColor(DesignSystem.Colors.quaternaryText)
                                            .opacity(0.8)
                                        
                                        HStack(spacing: DesignSystem.Spacing.xs) {
                                            Image(systemName: "arrow.up.arrow.down")
                                                .font(DesignSystem.Typography.caption2)
                                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                            
                                            Text("sort_by".localized)
                                                .font(DesignSystem.Typography.caption2)
                                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: { 
                                        HapticFeedback.impact(.light)
                                        showingSortOptions = true 
                                    }) {
                                        HStack(spacing: DesignSystem.Spacing.xs) {
                                            Image(systemName: sortOption.iconName)
                                                .font(DesignSystem.Typography.caption2)
                                            
                                            Text(sortOption.displayName)
                                                .font(DesignSystem.Typography.caption1)
                                                .fontWeight(.medium)
                                            
                                            Image(systemName: "chevron.down")
                                                .font(DesignSystem.Typography.caption2)
                                        }
                                        .padding(.horizontal, DesignSystem.Spacing.sm)
                                        .padding(.vertical, DesignSystem.Spacing.xs)
                                        .background(DesignSystem.Colors.glassBackground)
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: DesignSystem.CornerRadius.continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: DesignSystem.CornerRadius.continuous)
                                                .stroke(DesignSystem.Colors.glassStroke, lineWidth: 0.5)
                                        )
                                    }
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.vertical, DesignSystem.Spacing.sm)
                            }
                            .secondaryCard()
                            
                            ScrollView {
                                LazyVStack(spacing: DesignSystem.Spacing.sm) {
                                    ForEach(sortedAccommodations) { accommodation in
                                        accommodationCard(for: accommodation)
                                    }
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.vertical, DesignSystem.Spacing.md)
                                .padding(.bottom, isSelectionMode ? 100 : 0) // Space for floating button
                            }
                        }
                        
                        // Floating Action Buttons für Multi-Selection
                        if isSelectionMode && !selectedAccommodations.isEmpty {
                            VStack {
                                Spacer()
                                VStack(spacing: DesignSystem.Spacing.sm) {
                                    // Scan Email & Spa Button (oben)
                                    Button(action: {
                                        HapticFeedback.impact(.medium)
                                        scrapeEmailsForSelectedAccommodations()
                                    }) {
                                        HStack(spacing: DesignSystem.Spacing.sm) {
                                            Image(systemName: "doc.text.magnifyingglass")
                                                .font(DesignSystem.Typography.callout)
                                            
                                            Text("scan_email_spa".localized)
                                                .font(DesignSystem.Typography.calloutEmphasized)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, DesignSystem.Spacing.lg)
                                        .padding(.vertical, DesignSystem.Spacing.md)
                                        .background(
                                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: DesignSystem.CornerRadius.continuous)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [DesignSystem.Colors.accent.opacity(0.8), DesignSystem.Colors.accent.opacity(0.6)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: DesignSystem.CornerRadius.continuous)
                                                        .stroke(DesignSystem.Colors.accent.opacity(0.8), lineWidth: 1)
                                                )
                                        )
                                        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                                    }
                                    .disabled(emailService.isProcessing)
                                    .opacity(emailService.isProcessing ? 0.6 : 1.0)
                                    
                                    // Multi-Booking Request Button (unten)
                                    Button(action: {
                                        HapticFeedback.impact(.medium)
                                        showingMultiBooking = true
                                    }) {
                                        HStack(spacing: DesignSystem.Spacing.sm) {
                                            Image(systemName: "paperplane.fill")
                                                .font(DesignSystem.Typography.callout)
                                            
                                            Text(requestButtonText)
                                                .font(DesignSystem.Typography.calloutEmphasized)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, DesignSystem.Spacing.lg)
                                        .padding(.vertical, DesignSystem.Spacing.md)
                                        .background(
                                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: DesignSystem.CornerRadius.continuous)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [DesignSystem.Colors.primary.opacity(0.8), DesignSystem.Colors.primary.opacity(0.6)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: DesignSystem.CornerRadius.continuous)
                                                        .stroke(DesignSystem.Colors.primary.opacity(0.8), lineWidth: 1)
                                                )
                                        )
                                        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                                    }
                                }
                                .scaleEffect(selectedAccommodations.isEmpty ? 0.8 : 1.0)
                                .animation(DesignSystem.Animation.spring, value: selectedAccommodations.count)
                                .padding(DesignSystem.Spacing.lg)
                            }
                        }
                    }
                }
            }
            }
            .navigationTitle(viewModel.selectedResort?.name ?? "\(viewModel.accommodations.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if showDemoWarning {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(DesignSystem.Typography.caption2)
                                Text("demo".localized)
                                    .font(DesignSystem.Typography.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(DesignSystem.Colors.warning)
                            .padding(.horizontal, DesignSystem.Spacing.xs)
                            .padding(.vertical, DesignSystem.Spacing.xxs)
                            .background(DesignSystem.Colors.warning.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs, style: DesignSystem.CornerRadius.continuous))
                        }
                        
                        if !isSelectionMode {
                            // Content Scanning Button
                            Button(action: { 
                                HapticFeedback.impact(.light)
                                showingEmailOptions = true 
                            }) {
                                Image(systemName: emailScanningIcon)
                                    .font(DesignSystem.Typography.callout)
                                    .foregroundColor(emailScanningColor)
                                    .frame(width: DesignSystem.Layout.minTouchTarget, height: DesignSystem.Layout.minTouchTarget)
                            }
                            .disabled(emailService.isProcessing)
                            
                            Button(action: { 
                                HapticFeedback.impact(.light)
                                showingMap = true 
                            }) {
                                Image(systemName: "map")
                                    .font(DesignSystem.Typography.callout)
                                    .foregroundColor(DesignSystem.Colors.primary)
                                    .frame(width: DesignSystem.Layout.minTouchTarget, height: DesignSystem.Layout.minTouchTarget)
                            }
                        }
                        
                        if isSelectionMode {
                            Button("deselect_all".localized) {
                                HapticFeedback.impact(.light)
                                withAnimation(DesignSystem.Animation.medium) {
                                    selectedAccommodations.removeAll()
                                }
                            }
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.error)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if !isSelectionMode {
                            Button(action: {
                                HapticFeedback.impact(.light)
                                withAnimation(DesignSystem.Animation.medium) {
                                    isSelectionMode = true
                                }
                            }) {
                                Image(systemName: "checkmark.circle")
                                    .font(DesignSystem.Typography.callout)
                                    .foregroundColor(DesignSystem.Colors.primary)
                                    .frame(width: DesignSystem.Layout.minTouchTarget, height: DesignSystem.Layout.minTouchTarget)
                            }
                        }
                        
                        
                        Button(trailingButtonText) {
                            HapticFeedback.impact(.light)
                            if isSelectionMode {
                                withAnimation(DesignSystem.Animation.medium) {
                                    isSelectionMode = false
                                    selectedAccommodations.removeAll()
                                }
                            } else {
                                dismiss()
                            }
                        }
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
            .sheet(item: $selectedAccommodation) { accommodation in
                BookingRequestView(accommodation: accommodation)
            }
            .sheet(isPresented: $showingMap) {
                if let resort = viewModel.selectedResort {
                    MapView(resort: resort, accommodations: viewModel.accommodations)
                }
            }
            .sheet(isPresented: $showingMultiBooking) {
                MultiBookingRequestView(accommodations: getSelectedAccommodations())
            }
            .confirmationDialog("sort_by_title".localized, isPresented: $showingSortOptions) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(option.displayName) {
                        HapticFeedback.selection()
                        withAnimation(DesignSystem.Animation.fast) {
                            sortOption = option
                        }
                    }
                }
                Button("cancel".localized, role: .cancel) { }
            } message: {
                Text("choose_sort_option".localized)
            }
            .confirmationDialog("email_search_dialog_title".localized, isPresented: $showingEmailOptions) {
                Button("search_all_emails".localized) {
                    HapticFeedback.selection()
                    scrapeEmailsForAllAccommodations()
                }
                
                if emailService.isProcessing {
                    Button("stop_email_search".localized, role: .destructive) {
                        HapticFeedback.impact(.medium)
                        emailService.stopProcessing()
                    }
                }
                
                Button("cancel".localized, role: .cancel) { }
            } message: {
                Text("email_search_description".localized)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var requestButtonText: String {
        String(format: "request_to_count".localized, selectedAccommodations.count)
    }
    
    private var showDemoWarning: Bool {
        viewModel.accommodations.contains(where: { !$0.isRealData }) && !isSelectionMode
    }
    
    private var emailScanningIcon: String {
        emailService.isProcessing ? "radar.radiowaves.left.and.right" : "doc.text.magnifyingglass"
    }
    
    private var emailScanningColor: Color {
        emailService.isProcessing ? DesignSystem.Colors.warning : DesignSystem.Colors.primary
    }
    
    
    private var trailingButtonText: String {
        isSelectionMode ? "done".localized : "close".localized
    }
    
    private var isLoadingAccommodations: Bool {
        // Show loading spinner if:
        // 1. ViewModel is explicitly loading, OR
        // 2. Database is loading AND we have no accommodations for the current resort
        return viewModel.isLoading || (accommodationDB.loadingStatus == .loading && viewModel.accommodations.isEmpty)
    }
    
    private var loadingMessage: String {
        if viewModel.isLoading {
            return "searching_accommodations".localized
        } else if accommodationDB.loadingStatus == .loading {
            return "loading_accommodations".localized
        } else {
            return "searching_accommodations".localized
        }
    }
    
    private var sortedAccommodations: [Accommodation] {
        switch sortOption {
        case .distance:
            return viewModel.accommodations.sorted { $0.distanceToLift < $1.distanceToLift }
        case .priceAscending:
            return viewModel.accommodations.sorted { $0.pricePerNight < $1.pricePerNight }
        case .priceDescending:
            return viewModel.accommodations.sorted { $0.pricePerNight > $1.pricePerNight }
        case .rating:
            return viewModel.accommodations.sorted { 
                // Sort by rating, but put accommodations without rating at the end
                let rating1 = $0.rating ?? 0.0
                let rating2 = $1.rating ?? 0.0
                if $0.rating == nil && $1.rating == nil { return false }
                if $0.rating == nil { return false } // Put nil ratings at end
                if $1.rating == nil { return true }  // Put nil ratings at end
                return rating1 > rating2
            }
        case .spaFeatures:
            return viewModel.accommodations.sorted { accommodation1, accommodation2 in
                let spa1Count = [accommodation1.hasPool, accommodation1.hasJacuzzi, accommodation1.hasSpa, accommodation1.hasSauna].filter { $0 }.count
                let spa2Count = [accommodation2.hasPool, accommodation2.hasJacuzzi, accommodation2.hasSpa, accommodation2.hasSauna].filter { $0 }.count
                return spa1Count > spa2Count
            }
        case .contactAvailable:
            return viewModel.accommodations.sorted { $0.hasContactInfo && !$1.hasContactInfo }
        }
    }
    
    private func toggleSelection(for accommodation: Accommodation) {
        if selectedAccommodations.contains(accommodation.id) {
            selectedAccommodations.remove(accommodation.id)
        } else {
            selectedAccommodations.insert(accommodation.id)
        }
    }
    
    private func getSelectedAccommodations() -> [Accommodation] {
        return viewModel.accommodations.filter { selectedAccommodations.contains($0.id) }
    }
    
    // MARK: - Email Scraping Functions
    
    private func scrapeEmailsForAllAccommodations() {
        let accommodationsWithoutEmailOrWellness = viewModel.accommodations.filter { accommodation in
            // Process if missing email or if no wellness features detected from OSM
            let missingEmail = accommodation.email == nil || accommodation.email!.isEmpty
            let noWellnessFeatures = !accommodation.hasPool && !accommodation.hasJacuzzi && !accommodation.hasSpa && !accommodation.hasSauna
            return missingEmail || noWellnessFeatures
        }
        
        guard !accommodationsWithoutEmailOrWellness.isEmpty else {
            print("📧🏊‍♀️ Alle Unterkünfte haben bereits E-Mail-Adressen und Wellness-Informationen")
            return
        }
        
        print("🔍 Starte E-Mail- und Wellness-Suche für \(accommodationsWithoutEmailOrWellness.count) Unterkünfte")
        
        emailService.processEmailsAndWellnessFeatures(for: accommodationsWithoutEmailOrWellness) { emailResults, wellnessResults in
            DispatchQueue.main.async {
                self.updateAccommodationsWithEmailsAndWellness(emailResults, wellnessResults)
                print("✅ E-Mail- und Wellness-Suche abgeschlossen. \(emailResults.count) E-Mails und \(wellnessResults.count) Wellness-Profile gefunden.")
            }
        }
    }
    
    private func scrapeEmailsForSelectedAccommodations() {
        let selectedAccommodationsList = getSelectedAccommodations()
        let accommodationsWithoutEmailOrWellness = selectedAccommodationsList.filter { accommodation in
            // Process if missing email or if no wellness features detected from OSM
            let missingEmail = accommodation.email == nil || accommodation.email!.isEmpty
            let noWellnessFeatures = !accommodation.hasPool && !accommodation.hasJacuzzi && !accommodation.hasSpa && !accommodation.hasSauna
            return missingEmail || noWellnessFeatures
        }
        
        guard !accommodationsWithoutEmailOrWellness.isEmpty else {
            print("📧🏊‍♀️ Alle ausgewählten Unterkünfte haben bereits E-Mail-Adressen und Wellness-Informationen")
            return
        }
        
        print("🔍 Starte E-Mail- und Wellness-Suche für \(accommodationsWithoutEmailOrWellness.count) ausgewählte Unterkünfte")
        
        emailService.processEmailsAndWellnessFeatures(for: accommodationsWithoutEmailOrWellness) { emailResults, wellnessResults in
            DispatchQueue.main.async {
                self.updateAccommodationsWithEmailsAndWellness(emailResults, wellnessResults)
                print("✅ E-Mail- und Wellness-Suche für ausgewählte Unterkünfte abgeschlossen. \(emailResults.count) E-Mails und \(wellnessResults.count) Wellness-Profile gefunden.")
            }
        }
    }
    
    private func updateAccommodationsWithEmails(_ emailResults: [String: EmailResult]) {
        // Update the accommodations in the view model with found emails
        viewModel.accommodations = viewModel.accommodations.map { accommodation in
            if let emailResult = emailResults[accommodation.name], emailResult.isValid {
                // Create updated accommodation with email (preserve ID)
                return Accommodation(
                    id: accommodation.id,
                    name: accommodation.name,
                    distanceToLift: accommodation.distanceToLift,
                    hasPool: accommodation.hasPool,
                    hasJacuzzi: accommodation.hasJacuzzi,
                    hasSpa: accommodation.hasSpa,
                    hasSauna: accommodation.hasSauna,
                    pricePerNight: accommodation.pricePerNight,
                    rating: accommodation.rating,
                    imageUrl: accommodation.imageUrl,
                    imageUrls: accommodation.imageUrls,
                    resort: accommodation.resort,
                    isRealData: accommodation.isRealData,
                    email: emailResult.email,
                    phone: accommodation.phone,
                    website: accommodation.website,
                    coordinate: accommodation.coordinate
                )
            }
            return accommodation
        }
    }
    
    private func updateAccommodationsWithEmailsAndWellness(_ emailResults: [String: EmailResult], _ wellnessResults: [String: WellnessScrapingResult]) {
        // Update the accommodations in the view model with found emails and wellness features
        viewModel.accommodations = viewModel.accommodations.map { accommodation in
            var updatedAccommodation = accommodation
            
            // Update email if found
            if let emailResult = emailResults[accommodation.name], emailResult.isValid {
                updatedAccommodation = Accommodation(
                    id: accommodation.id,
                    name: accommodation.name,
                    distanceToLift: accommodation.distanceToLift,
                    hasPool: accommodation.hasPool,
                    hasJacuzzi: accommodation.hasJacuzzi,
                    hasSpa: accommodation.hasSpa,
                    hasSauna: accommodation.hasSauna,
                    pricePerNight: accommodation.pricePerNight,
                    rating: accommodation.rating,
                    imageUrl: accommodation.imageUrl,
                    imageUrls: accommodation.imageUrls,
                    resort: accommodation.resort,
                    isRealData: accommodation.isRealData,
                    email: emailResult.email,
                    phone: accommodation.phone,
                    website: accommodation.website,
                    coordinate: accommodation.coordinate
                )
            }
            
            // Update wellness features if found (and if they were previously false)
            if let wellnessResult = wellnessResults[accommodation.name], wellnessResult.confidence > 0.5 {
                updatedAccommodation = Accommodation(
                    id: updatedAccommodation.id,
                    name: updatedAccommodation.name,
                    distanceToLift: updatedAccommodation.distanceToLift,
                    hasPool: updatedAccommodation.hasPool || wellnessResult.hasPool,
                    hasJacuzzi: updatedAccommodation.hasJacuzzi || wellnessResult.hasJacuzzi,
                    hasSpa: updatedAccommodation.hasSpa || wellnessResult.hasSpa,
                    hasSauna: updatedAccommodation.hasSauna || wellnessResult.hasSauna,
                    pricePerNight: updatedAccommodation.pricePerNight,
                    rating: updatedAccommodation.rating,
                    imageUrl: updatedAccommodation.imageUrl,
                    imageUrls: updatedAccommodation.imageUrls,
                    resort: updatedAccommodation.resort,
                    isRealData: updatedAccommodation.isRealData,
                    email: updatedAccommodation.email,
                    phone: updatedAccommodation.phone,
                    website: updatedAccommodation.website,
                    coordinate: updatedAccommodation.coordinate
                )
                
                print("🏊‍♀️ Updated wellness features for \(accommodation.name): Pool=\(wellnessResult.hasPool), Jacuzzi=\(wellnessResult.hasJacuzzi), Spa=\(wellnessResult.hasSpa), Sauna=\(wellnessResult.hasSauna)")
            }
            
            return updatedAccommodation
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func accommodationCard(for accommodation: Accommodation) -> some View {
        AccommodationCard(
            accommodation: accommodation,
            isSelectionMode: isSelectionMode,
            isSelected: selectedAccommodations.contains(accommodation.id),
            onTap: {
                HapticFeedback.impact(.light)
                if isSelectionMode {
                    withAnimation(DesignSystem.Animation.fast) {
                        toggleSelection(for: accommodation)
                    }
                } else {
                    selectedAccommodation = accommodation
                }
            },
            onAccommodationUpdated: { updatedAccommodation in
                viewModel.updateAccommodation(updatedAccommodation)
            }
        )
    }
}

// MARK: - Sort Options

enum SortOption: String, CaseIterable {
    case distance = "distance"
    case priceAscending = "price_asc"
    case priceDescending = "price_desc"
    case rating = "rating"
    case spaFeatures = "spa_features"
    case contactAvailable = "contact_available"
    
    var displayName: String {
        switch self {
        case .distance:
            return "sort_by_distance".localized
        case .priceAscending:
            return "sort_by_price_asc".localized
        case .priceDescending:
            return "sort_by_price_desc".localized
        case .rating:
            return "sort_by_rating".localized
        case .spaFeatures:
            return "sort_by_spa".localized
        case .contactAvailable:
            return "sort_by_contact".localized
        }
    }
    
    var iconName: String {
        switch self {
        case .distance:
            return "figure.skiing.downhill"
        case .priceAscending:
            return "arrow.up.circle"
        case .priceDescending:
            return "arrow.down.circle"
        case .rating:
            return "star.fill"
        case .spaFeatures:
            return "leaf.fill"
        case .contactAvailable:
            return "envelope.fill"
        }
    }
}