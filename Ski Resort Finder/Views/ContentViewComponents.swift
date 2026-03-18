import SwiftUI

// MARK: - Header View
struct HeaderView: View {
    let onAboutTap: () -> Void
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text("ski_resort_finder".localized)
                    .font(DesignSystem.Typography.title1)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("find_perfect_resort".localized)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            Button(action: onAboutTap) {
                Image(systemName: "info.circle.fill")
                    .font(.title2)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .frame(width: DesignSystem.Layout.minTouchTarget, height: DesignSystem.Layout.minTouchTarget)
            }
        }
        .sectionContainer()
    }
}

// MARK: - Favorites Quick Access View
struct FavoritesQuickAccessView: View {
    let favorites: [SkiResort]
    let selectedResort: SkiResort?
    let onResortSelected: (SkiResort) -> Void
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("favorites_star".localized)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(favorites) { resort in
                        FavoriteResortChip(
                            resort: resort,
                            isSelected: selectedResort == resort,
                            onTap: { onResortSelected(resort) }
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.xs)
            }
        }
        .sectionContainer()
    }
}

// MARK: - Favorite Resort Chip
struct FavoriteResortChip: View {
    let resort: SkiResort
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DesignSystem.Spacing.xxs) {
                Text(resort.name)
                    .font(DesignSystem.Typography.caption1)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(resort.country.localizedCountryName())
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .frame(minWidth: 80)
            .background(
                isSelected ? 
                DesignSystem.Colors.primary.opacity(0.1) : 
                DesignSystem.Colors.tertiaryBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous)
                    .stroke(
                        isSelected ? DesignSystem.Colors.primary : Color.clear,
                        lineWidth: isSelected ? 2 : 0
                    )
            )
        }
        .foregroundColor(DesignSystem.Colors.primaryText)
        .buttonStyle(PlainButtonStyle())
        .animation(DesignSystem.Animation.fast, value: isSelected)
    }
}

// MARK: - Resort Selection Card
struct ResortSelectionCard: View {
    let selectedResort: SkiResort?
    let onTap: () -> Void
    @ObservedObject private var localization = LocalizationService.shared
    @ObservedObject private var accommodationDB = AccommodationDatabase.shared
    
    private var isResortsAvailable: Bool {
        !SkiResortDatabase.shared.allSkiResorts.isEmpty
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundColor(isResortsAvailable ? DesignSystem.Colors.primary : DesignSystem.Colors.quaternaryText)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text("select_resort".localized)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(isResortsAvailable ? DesignSystem.Colors.secondaryText : DesignSystem.Colors.quaternaryText)
                    
                    Text(selectedResort?.name ?? "tap_to_select".localized)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(isResortsAvailable ? DesignSystem.Colors.primaryText : DesignSystem.Colors.quaternaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(isResortsAvailable ? DesignSystem.Colors.tertiaryText : DesignSystem.Colors.quaternaryText)
                    .fontWeight(.medium)
            }
            .padding(DesignSystem.Spacing.md)
        }
        .disabled(!isResortsAvailable)
        .buttonStyle(PlainButtonStyle())
        .secondaryCard()
        .animation(DesignSystem.Animation.fast, value: selectedResort)
        .animation(DesignSystem.Animation.fast, value: isResortsAvailable)
    }
}

// MARK: - Date Selection Card
struct DateSelectionCard: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(DesignSystem.Colors.primary)
                    .font(DesignSystem.Typography.callout)
                
                Text("travel_period".localized)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                DatePicker("from".localized, selection: $startDate, displayedComponents: .date)
                    .font(DesignSystem.Typography.body)
                
                Divider()
                    .background(DesignSystem.Colors.separator)
                
                DatePicker("to".localized, selection: $endDate, displayedComponents: .date)
                    .font(DesignSystem.Typography.body)
            }
            .padding(DesignSystem.Spacing.sm)
            .secondaryCard()
        }
        .sectionContainer()
    }
}

// MARK: - Guest Details Card
struct GuestDetailsCard: View {
    @Binding var numberOfGuests: Int
    @Binding var numberOfRooms: Int
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(DesignSystem.Colors.primary)
                    .font(DesignSystem.Typography.callout)
                
                Text("guest_details".localized)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
            }
            
            HStack(spacing: DesignSystem.Spacing.xl) {
                // Guests Counter
                CounterView(
                    title: "number_of_guests".localized,
                    value: $numberOfGuests,
                    range: 1...10,
                    color: DesignSystem.Colors.primary
                )
                
                Spacer()
                
                // Rooms Counter
                CounterView(
                    title: "number_of_rooms".localized,
                    value: $numberOfRooms,
                    range: 1...5,
                    color: DesignSystem.Colors.success
                )
            }
            .padding(DesignSystem.Spacing.sm)
            .secondaryCard()
        }
        .sectionContainer()
    }
}

// MARK: - Counter View
struct CounterView: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                Button(action: {
                    if value > range.lowerBound {
                        HapticFeedback.impact(.light)
                        withAnimation(DesignSystem.Animation.fast) {
                            value -= 1
                        }
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(value > range.lowerBound ? color : DesignSystem.Colors.quaternaryText)
                }
                .disabled(value <= range.lowerBound)
                
                Text("\(value)")
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .frame(minWidth: 30)
                    .animation(DesignSystem.Animation.fast, value: value)
                
                Button(action: {
                    if value < range.upperBound {
                        HapticFeedback.impact(.light)
                        withAnimation(DesignSystem.Animation.fast) {
                            value += 1
                        }
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(value < range.upperBound ? color : DesignSystem.Colors.quaternaryText)
                }
                .disabled(value >= range.upperBound)
            }
        }
    }
}

// MARK: - Search Radius Selector
struct SearchRadiusSelector: View {
    @ObservedObject private var searchSettings = SearchSettings.shared
    @ObservedObject private var localization = LocalizationService.shared
    @State private var showingRadiusOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text("search_radius".localized)
                    .font(DesignSystem.Typography.caption1)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                Button(action: { showingRadiusOptions.toggle() }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text(searchSettings.radiusDisplayText)
                            .font(DesignSystem.Typography.caption1)
                            .fontWeight(.medium)
                        
                        Image(systemName: showingRadiusOptions ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(DesignSystem.Colors.accent)
                    .padding(.horizontal, DesignSystem.Spacing.xs)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if showingRadiusOptions {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(SearchSettings.availableRadii, id: \.self) { radius in
                        RadiusOptionRow(
                            radius: radius,
                            isSelected: searchSettings.searchRadius == radius
                        ) {
                            withAnimation(DesignSystem.Animation.medium) {
                                searchSettings.searchRadius = radius
                                showingRadiusOptions = false
                            }
                        }
                    }
                }
                .padding(.top, DesignSystem.Spacing.xs)
            }
        }
        .padding(.horizontal, DesignSystem.Layout.screenPadding)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(DesignSystem.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .animation(DesignSystem.Animation.medium, value: showingRadiusOptions)
    }
}

struct RadiusOptionRow: View {
    let radius: Double
    let isSelected: Bool
    let onTap: () -> Void
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(radius == 1.0 ? "search_radius_1km".localized : String(format: "search_radius_km".localized, Int(radius)))
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.primaryText)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.accent)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            isSelected ? 
            DesignSystem.Colors.accent.opacity(0.1) : 
            Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
    }
}

// MARK: - Search Button Card
struct SearchButtonCard: View {
    let isEnabled: Bool
    let onSearch: () -> Void
    @ObservedObject private var localization = LocalizationService.shared

    var body: some View {
        Button(action: onSearch) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "building.2.fill")
                    .font(DesignSystem.Typography.callout)

                Text("search_accommodations".localized)
                    .font(DesignSystem.Typography.calloutEmphasized)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
            .foregroundColor(isEnabled ? DesignSystem.Colors.primary : DesignSystem.Colors.quaternaryText)
        }
        .glassEffect(.regular.interactive(), in: .capsule)
        .tint(isEnabled ? DesignSystem.Colors.primary : nil)
        .disabled(!isEnabled)
        .animation(DesignSystem.Animation.medium, value: isEnabled)
    }
}

// MARK: - Error Message Card
struct ErrorMessageCard: View {
    let message: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(DesignSystem.Colors.error)
                .font(DesignSystem.Typography.callout)
            
            Text(message)
                .font(DesignSystem.Typography.footnote)
                .foregroundColor(DesignSystem.Colors.error)
                .multilineTextAlignment(.leading)
            
            Spacer(minLength: 0)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.error.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous)
                .stroke(DesignSystem.Colors.error.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Accommodation Database Progress View
struct AccommodationDatabaseProgressView: View {
    let loadingStatus: AccommodationLoadingStatus
    let statistics: AccommodationStatistics
    @ObservedObject private var localization = LocalizationService.shared
    @ObservedObject private var accommodationDB = AccommodationDatabase.shared
    
    var body: some View {
        Group {
            switch loadingStatus {
            case .idle:
                // Zeige idle-Karte immer an (für manuelle Ladung)
                idleLoadingCard
                
            case .loading:
                activeLoadingCard
                
            case .completed:
                if statistics.lastFullUpdate == nil || Calendar.current.isDateInToday(statistics.lastFullUpdate!) {
                    // Zeige Completed-Status nur am Tag der Aktualisierung
                    completedCard
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    // Zeige idle-Karte für erneute Ladung
                    idleLoadingCard
                }
                
            case .error(let errorMessage):
                errorCard(message: errorMessage)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: loadingStatus)
    }
    
    @ViewBuilder
    private var idleLoadingCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: statistics.totalAccommodations == 0 ? 
                      "square.and.arrow.down" : 
                      "cylinder.fill")
                    .foregroundColor(DesignSystem.Colors.primary)
                    .font(DesignSystem.Typography.callout)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(statistics.totalAccommodations == 0 ? 
                         "initializing_accommodation_database".localized : 
                         "accommodation_database_ready".localized)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text(statistics.totalAccommodations == 0 ? 
                         "preparing_accommodation_data".localized :
                         "database_statistics".localized(with: statistics.totalAccommodations, statistics.resortsWithAccommodations))
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
            }
            
        }
        .sectionContainer()
    }
    
    @ViewBuilder
    private var activeLoadingCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(DesignSystem.Colors.primary)
                    .font(DesignSystem.Typography.callout)
                    .rotationEffect(.degrees(statistics.processedResorts > 0 ? 360 : 0))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: statistics.processedResorts)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("loading_accommodations".localized)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    if !statistics.currentResort.isEmpty {
                        Text("current_resort_loading".localized(with: statistics.currentResort))
                            .font(DesignSystem.Typography.footnote)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(statistics.processedResorts)/\(statistics.totalResorts)")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text("\(statistics.totalAccommodations) " + "accommodations_found_short".localized)
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                // Stop Button
                Button(action: {
                    accommodationDB.stopLoading()
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundColor(DesignSystem.Colors.error)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Progress Bar
            ProgressView(value: progressValue, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.primary))
                .scaleEffect(x: 1, y: 0.8, anchor: .center)
            
            HStack {
                Text("progress_percentage".localized(with: Int(progressValue * 100)))
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Spacer()
                
                if statistics.resortsWithAccommodations > 0 {
                    Text("resorts_with_data".localized(with: statistics.resortsWithAccommodations))
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                // Stop Button Label (small)
                Text("tap_to_stop".localized)
                    .font(.caption2)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .opacity(0.7)
            }
        }
        .sectionContainer()
    }
    
    @ViewBuilder
    private var completedCard: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(DesignSystem.Colors.success)
                .font(DesignSystem.Typography.callout)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("database_updated".localized)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("total_accommodations_loaded".localized(with: statistics.totalAccommodations, statistics.resortsWithAccommodations))
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            // Auto-hide after 5 seconds
            Button(action: {}) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .disabled(true)
            .opacity(0) // Versteckt, aber behält Layout
        }
        .sectionContainer()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                // Card wird automatisch durch Animation ausgeblendet
            }
        }
    }
    
    @ViewBuilder
    private func errorCard(message: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(DesignSystem.Colors.error)
                .font(DesignSystem.Typography.callout)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("database_error".localized)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.error)
                
                Text(message)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .sectionContainer()
    }
    
    private var progressValue: Double {
        guard statistics.totalResorts > 0 else { return 0 }
        return Double(statistics.processedResorts) / Double(statistics.totalResorts)
    }
}

// MARK: - Content Scanning Progress View
struct ContentScanningProgressView: View {
    let processingStatus: EmailProcessingStatus
    let statistics: EmailProcessingStatistics
    @ObservedObject private var localization = LocalizationService.shared
    @ObservedObject private var emailService = AdvancedEmailService.shared
    
    var body: some View {
        Group {
            switch processingStatus {
            case .idle:
                EmptyView() // Don't show anything when idle
                
            case .processing:
                activeScanningCard
                
            case .completed:
                completedScanningCard
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                
            case .error(let errorMessage):
                errorScanningCard(message: errorMessage)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: processingStatus)
    }
    
    @ViewBuilder
    private var activeScanningCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.primary)
                    .font(DesignSystem.Typography.callout)
                    .rotationEffect(.degrees(statistics.processedAccommodations > 0 ? 360 : 0))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: statistics.processedAccommodations)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("content_scanning_in_progress".localized)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    if !statistics.currentAccommodation.isEmpty {
                        Text("current_accommodation_processing".localized(with: statistics.currentAccommodation))
                            .font(DesignSystem.Typography.footnote)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(statistics.processedAccommodations)/\(statistics.totalAccommodations)")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text("\(statistics.foundEmails)")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundColor(DesignSystem.Colors.primary)
                        Image(systemName: "at")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.primary)
                        
                        Text("\(statistics.foundWellnessFeatures)")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundColor(DesignSystem.Colors.accent)
                        Image(systemName: "drop.fill")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                }
                
                // Stop Button
                Button(action: {
                    emailService.stopProcessing()
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundColor(DesignSystem.Colors.error)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Progress Bar
            ProgressView(value: progressValue, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.primary))
                .scaleEffect(x: 1, y: 0.8, anchor: .center)
            
            HStack {
                Text("progress_percentage".localized(with: Int(progressValue * 100)))
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Spacer()
                
                // Content scanning breakdown
                HStack(spacing: DesignSystem.Spacing.sm) {
                    if statistics.foundEmails > 0 {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            if statistics.verifiedEmails > 0 {
                                Label("\(statistics.verifiedEmails)", systemImage: "checkmark.seal.fill")
                                    .font(.caption2)
                                    .foregroundColor(DesignSystem.Colors.success)
                            }
                            if statistics.scrapedEmails > 0 {
                                Label("\(statistics.scrapedEmails)", systemImage: "globe")
                                    .font(.caption2)
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                            if statistics.inferredEmails > 0 {
                                Label("\(statistics.inferredEmails)", systemImage: "brain")
                                    .font(.caption2)
                                    .foregroundColor(DesignSystem.Colors.accent)
                            }
                        }
                    }
                    
                    // Wellness features breakdown
                    if statistics.foundWellnessFeatures > 0 {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            if statistics.foundPools > 0 {
                                Label("\(statistics.foundPools)", systemImage: "drop.fill")
                                    .font(.caption2)
                                    .foregroundColor(.cyan)
                            }
                            if statistics.foundSpas > 0 {
                                Label("\(statistics.foundSpas)", systemImage: "leaf.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                            if statistics.foundSaunas > 0 {
                                Label("\(statistics.foundSaunas)", systemImage: "thermometer.sun.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                // Stop Button Label (small)
                Text("tap_to_stop".localized)
                    .font(.caption2)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .opacity(0.7)
            }
        }
        .sectionContainer()
    }
    
    @ViewBuilder
    private var completedScanningCard: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(DesignSystem.Colors.success)
                .font(DesignSystem.Typography.callout)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("content_scanning_completed".localized)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text("\(statistics.foundEmails) " + "emails_found_short".localized)
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Text("\(statistics.foundWellnessFeatures) " + "wellness_features_found".localized)
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.accent)
                }
            }
            
            Spacer()
            
            // Quality breakdown
            VStack(alignment: .trailing, spacing: 1) {
                if statistics.verifiedEmails > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(DesignSystem.Colors.success)
                            .font(.caption2)
                        Text("\(statistics.verifiedEmails) verified".localized)
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                if statistics.scrapedEmails > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .foregroundColor(DesignSystem.Colors.primary)
                            .font(.caption2)
                        Text("\(statistics.scrapedEmails) scanned".localized)
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }
        }
        .sectionContainer()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                // Card will be automatically hidden by animation
            }
        }
    }
    
    @ViewBuilder
    private func errorScanningCard(message: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(DesignSystem.Colors.error)
                .font(DesignSystem.Typography.callout)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("content_scanning_error".localized)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.error)
                
                Text(message)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .sectionContainer()
    }
    
    private var progressValue: Double {
        return statistics.progressPercentage
    }
}

// MARK: - Resort Selection for Accommodation Loading View
struct ResortSelectionForLoadingView: View {
    @ObservedObject private var accommodationDB = AccommodationDatabase.shared
    @ObservedObject private var skiResortDB = SkiResortDatabase.shared
    @ObservedObject private var localization = LocalizationService.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedResorts: Set<UUID> = []
    @State private var searchText: String = ""
    
    private var filteredResorts: [SkiResort] {
        return skiResortDB.searchResorts(query: searchText)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Spacing.md) {
                // Header Info
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("select_resorts_to_load".localized)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Search Bar
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    TextField("search_placeholder".localized, text: $searchText)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            HapticFeedback.impact(.light)
                            withAnimation(DesignSystem.Animation.fast) {
                                searchText = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.tertiaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous)
                        .stroke(DesignSystem.Colors.separator.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal)
                
                // Selection Controls
                HStack {
                    Button("select_all_resorts".localized) {
                        selectedResorts = Set(filteredResorts.map { $0.id })
                    }
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(DesignSystem.Colors.primary)
                    
                    Spacer()
                    
                    Button("deselect_all_resorts".localized) {
                        selectedResorts.removeAll()
                    }
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(DesignSystem.Colors.error)
                }
                .padding(.horizontal)
                
                // Resort List
                List(filteredResorts) { resort in
                    ResortSelectionRow(
                        resort: resort,
                        isSelected: selectedResorts.contains(resort.id),
                        hasAccommodationData: !accommodationDB.getAccommodations(for: resort).isEmpty
                    ) {
                        if selectedResorts.contains(resort.id) {
                            selectedResorts.remove(resort.id)
                        } else {
                            selectedResorts.insert(resort.id)
                        }
                    }
                }
                
                // Load Button
                VStack(spacing: DesignSystem.Spacing.sm) {
                    if selectedResorts.isEmpty {
                        Text("no_resorts_selected".localized)
                            .font(DesignSystem.Typography.footnote)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    } else {
                        Text("loading_resorts_selected".localized(with: selectedResorts.count))
                            .font(DesignSystem.Typography.footnote)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Button(action: {
                        startLoadingSelectedResorts()
                    }) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "arrow.clockwise")
                                .font(DesignSystem.Typography.callout)
                            
                            Text("load_accommodation_data".localized)
                                .font(DesignSystem.Typography.calloutEmphasized)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(DesignSystem.Spacing.md)
                        .background(
                            selectedResorts.isEmpty ? 
                            DesignSystem.Colors.quaternaryText : 
                            DesignSystem.Colors.primary
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
                        .shadow(
                            color: selectedResorts.isEmpty ? Color.clear : DesignSystem.Shadow.medium.color,
                            radius: DesignSystem.Shadow.medium.radius,
                            x: DesignSystem.Shadow.medium.x,
                            y: DesignSystem.Shadow.medium.y
                        )
                    }
                    .disabled(selectedResorts.isEmpty)
                    .buttonStyle(PlainButtonStyle())
                    .animation(DesignSystem.Animation.medium, value: selectedResorts.isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("resort_selection".localized)
            .navigationBarItems(
                trailing: Button("done".localized) { dismiss() }
            )
        }
    }
    
    private func startLoadingSelectedResorts() {
        let resortsToLoad = skiResortDB.allSkiResorts.filter { selectedResorts.contains($0.id) }
        
        if resortsToLoad.count == 1 {
            accommodationDB.loadAccommodationsForSingleResort(resortsToLoad.first!)
        } else {
            accommodationDB.loadAccommodationsForSelectedResorts(resortsToLoad)
        }
        
        dismiss()
    }
}

// MARK: - Resort Selection Row
struct ResortSelectionRow: View {
    let resort: SkiResort
    let isSelected: Bool
    let hasAccommodationData: Bool
    let onTap: () -> Void
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.tertiaryText)
                    .animation(DesignSystem.Animation.fast, value: isSelected)
                
                // Resort Info
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text(resort.name)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .lineLimit(1)
                    
                    Text("\(resort.country.localizedCountryName())")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Label("\(resort.totalSlopes)", systemImage: "figure.skiing.downhill")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.primary)
                        
                        Label("\(resort.maxElevation)m", systemImage: "mountain.2")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                // Data Status Indicator
                VStack(alignment: .trailing, spacing: 2) {
                    if hasAccommodationData {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.success)
                        Text("loaded".localized)
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.success)
                    } else {
                        Image(systemName: "circle.dashed")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                        Text("not_loaded".localized)
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Database Reload Button

struct DatabaseReloadButton: View {
    @ObservedObject private var accommodationDB = AccommodationDatabase.shared
    @ObservedObject private var localization = LocalizationService.shared
    @State private var showingResortSelection = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Button(action: {
                HapticFeedback.impact(.light)
                accommodationDB.loadAllAccommodations()
            }) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Text("load_all_resorts".localized)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(DesignSystem.Colors.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: DesignSystem.CornerRadius.continuous))
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                HapticFeedback.impact(.light)
                showingResortSelection = true
            }) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "list.bullet.circle.fill")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Text("load_selected_resorts".localized)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(DesignSystem.Colors.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: DesignSystem.CornerRadius.continuous))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingResortSelection) {
            ResortSelectionForLoadingView()
        }
    }
}

// MARK: - Compact Search Icon Button

struct CompactSearchButton: View {
    let resort: SkiResort?
    let onSearch: () -> Void
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        if resort != nil {
            Button(action: {
                HapticFeedback.impact(.light)
                onSearch()
            }) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Text("search_again".localized)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(DesignSystem.Colors.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: DesignSystem.CornerRadius.continuous))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

