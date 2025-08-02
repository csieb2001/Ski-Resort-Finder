import SwiftUI
import MapKit

struct Top3SkiResortsCard: View {
    @ObservedObject private var localization = LocalizationService.shared
    @ObservedObject private var accommodationDB = AccommodationDatabase.shared
    @State private var selectedCategory: TopCategory = .snowfall
    @State private var topResorts: [SkiResort] = []
    let onResortSelected: ((SkiResort) -> Void)?
    
    init(onResortSelected: ((SkiResort) -> Void)? = nil) {
        self.onResortSelected = onResortSelected
    }
    
    private var isSkiResortsAvailable: Bool {
        !SkiResortDatabase.shared.allSkiResorts.isEmpty
    }
    
    enum TopCategory: CaseIterable {
        case snowfall
        case totalSlopes
        case maxElevation
        case hotelRating
        
        var title: String {
            switch self {
            case .snowfall:
                return "top3_snowfall".localized
            case .totalSlopes:
                return "top3_slope_kilometers".localized
            case .maxElevation:
                return "top3_max_elevation".localized
            case .hotelRating:
                return "top3_hotel_rating".localized
            }
        }
        
        var icon: String {
            switch self {
            case .snowfall:
                return "snow"
            case .totalSlopes:
                return "mountain.2.fill"
            case .maxElevation:
                return "arrow.up.to.line"
            case .hotelRating:
                return "star.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .snowfall:
                return .blue
            case .totalSlopes:
                return .green
            case .maxElevation:
                return .purple
            case .hotelRating:
                return .orange
            }
        }
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Header with category selector
            VStack(spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(DesignSystem.Colors.accent)
                        .font(DesignSystem.Typography.title3)
                    Text("top3_ski_resorts".localized)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    Spacer()
                }
                
                // Category Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        ForEach(TopCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                HapticFeedback.selection()
                                withAnimation(DesignSystem.Animation.medium) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xs)
                }
            }
            
            // Top 3 List
            VStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(Array(topResorts.enumerated()), id: \.offset) { index, resort in
                    Top3ResortRow(
                        resort: resort,
                        rank: index + 1,
                        category: selectedCategory,
                        isEnabled: isSkiResortsAvailable
                    ) {
                        if isSkiResortsAvailable {
                            HapticFeedback.impact(.light)
                            onResortSelected?(resort)
                        }
                    }
                }
            }
        }
        .sectionContainer()
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: DesignSystem.CornerRadius.continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            selectedCategory.color.opacity(0.08),
                            selectedCategory.color.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .animation(DesignSystem.Animation.medium, value: selectedCategory)
        .task(id: selectedCategory) {
            topResorts = await getTop3Resorts()
        }
    }
    
    private func getTop3Resorts() async -> [SkiResort] {
        let allResorts = SkiResortDatabase.shared.allSkiResorts
        
        print("🏔️ [DEBUG] Total resorts available: \(allResorts.count)")
        print("🏔️ [DEBUG] Selected category: \(selectedCategory)")
        
        let result: [SkiResort]
        switch selectedCategory {
        case .snowfall:
            result = getTop3BySnowfall(resorts: allResorts)
        case .totalSlopes:
            // Sort by total slope area/distance (usually in km)
            let sortedResorts = allResorts
                .filter { $0.totalSlopes > 0 }  // Only include resorts with valid slope data
                .sorted { $0.totalSlopes > $1.totalSlopes }
            print("🏔️ [DEBUG] Top slope resorts: \(sortedResorts.prefix(5).map { "\($0.name): \($0.totalSlopes)km" })")
            result = Array(sortedResorts.prefix(3))
        case .maxElevation:
            // Sort by maximum elevation
            let sortedResorts = allResorts
                .filter { $0.maxElevation > 0 }  // Only include resorts with valid elevation data
                .sorted { $0.maxElevation > $1.maxElevation }
            print("🏔️ [DEBUG] Top elevation resorts: \(sortedResorts.prefix(5).map { "\($0.name): \($0.maxElevation)m" })")
            result = Array(sortedResorts.prefix(3))
        case .hotelRating:
            result = await getTop3ByHotelRating(resorts: allResorts)
        }
        
        print("🏔️ [DEBUG] Result count for \(selectedCategory): \(result.count)")
        return result
    }
    
    private func getTop3BySnowfall(resorts: [SkiResort]) -> [SkiResort] {
        // TODO: Implement real 3-year snowfall data using OpenMeteoService.HistoricalSnowData
        // For now, use elevation + alpine location as proxy for snowfall
        // Higher elevation + alpine location = more snowfall typically
        return resorts
            .filter { $0.maxElevation > 1800 } // High altitude resorts typically get more snow
            .sorted { resort1, resort2 in
                let elevation1 = resort1.maxElevation
                let elevation2 = resort2.maxElevation
                
                // Give bonus points for Alpine countries (better snowfall)
                let alpineBonus1 = isAlpineCountry(resort1.country) ? 500 : 0
                let alpineBonus2 = isAlpineCountry(resort2.country) ? 500 : 0
                
                let score1 = elevation1 + alpineBonus1
                let score2 = elevation2 + alpineBonus2
                
                return score1 > score2
            }
            .prefix(3)
            .compactMap { $0 }
    }
    
    private func getTop3ByHotelRating(resorts: [SkiResort]) async -> [SkiResort] {
        print("🏨 [DEBUG] Getting top 3 resorts by hotel rating...")
        
        // Get all accommodations with ratings from the database
        var resortRatings: [(resort: SkiResort, avgRating: Double, accommodationCount: Int)] = []
        
        for resort in resorts {
            let accommodations = accommodationDB.getAccommodations(for: resort)
            var ratedAccommodations: [CachedAccommodation] = []
            for cachedAccommodation in accommodations {
                let accommodation = await cachedAccommodation.toAccommodation(resort: resort)
                if accommodation.rating != nil {
                    ratedAccommodations.append(cachedAccommodation)
                }
            }
            
            guard !ratedAccommodations.isEmpty else { continue }
            
            var totalRating: Double = 0
            for cachedAccommodation in ratedAccommodations {
                let accommodation = await cachedAccommodation.toAccommodation(resort: resort)
                if let rating = accommodation.rating {
                    totalRating += rating
                }
            }
            
            let avgRating = totalRating / Double(ratedAccommodations.count)
            resortRatings.append((resort: resort, avgRating: avgRating, accommodationCount: ratedAccommodations.count))
            
            print("🏨 [DEBUG] \(resort.name): \(String(format: "%.2f", avgRating)) ⭐ (\(ratedAccommodations.count) hotels)")
            print("🔍 [DEBUG] Hotel Details für \(resort.name):")
            for (index, cachedAccommodation) in ratedAccommodations.prefix(3).enumerated() {
                let accommodation = await cachedAccommodation.toAccommodation(resort: resort)
                print("🏨   \(index+1). \(accommodation.name): \(accommodation.rating?.description ?? "nil")")
                print("📊     Distance: \(accommodation.distanceToLift)m, Spa: \(accommodation.hasSpaFeatures)")
            }
        }
        
        // Sort by average rating (descending) and minimum 3 accommodations
        let sortedResorts = resortRatings
            .filter { $0.accommodationCount >= 3 } // Mindestens 3 bewertete Hotels
            .sorted { $0.avgRating > $1.avgRating }
            .prefix(3)
            .map { $0.resort }
        
        print("🏨 [DEBUG] Top 3 by hotel rating: \(sortedResorts.map { $0.name })")
        return Array(sortedResorts)
    }
    
    private func isAlpineCountry(_ country: String) -> Bool {
        let alpineCountries = ["Schweiz", "Switzerland", "Österreich", "Austria", "Frankreich", "France", "Italien", "Italy"]
        return alpineCountries.contains(country)
    }
    
}

struct CategoryButton: View {
    let category: Top3SkiResortsCard.TopCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: category.icon)
                    .font(DesignSystem.Typography.caption1)
                Text(category.title)
                    .font(DesignSystem.Typography.caption1)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                isSelected ? category.color : DesignSystem.Colors.tertiaryBackground
            )
            .foregroundColor(
                isSelected ? .white : DesignSystem.Colors.primaryText
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: DesignSystem.CornerRadius.continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: DesignSystem.CornerRadius.continuous)
                    .stroke(
                        isSelected ? category.color : DesignSystem.Colors.separator,
                        lineWidth: isSelected ? 0 : 0.5
                    )
            )
        }
                .animation(DesignSystem.Animation.fast, value: isSelected)
    }
}

struct Top3ResortRow: View {
    let resort: SkiResort
    let rank: Int
    let category: Top3SkiResortsCard.TopCategory
    let isEnabled: Bool
    let onTap: () -> Void
    @ObservedObject private var localization = LocalizationService.shared
    @ObservedObject private var accommodationDB = AccommodationDatabase.shared
    @State private var hotelRating: String = "0.0"
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Rank Badge
                ZStack {
                    Circle()
                        .fill(rankColor)
                        .frame(width: 36, height: 36)
                        .shadow(
                            color: rankColor.opacity(0.3),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                    
                    Text("\(rank)")
                        .font(DesignSystem.Typography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // Resort Info
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text(resort.name)
                        .font(DesignSystem.Typography.calloutEmphasized)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .lineLimit(1)
                    
                    Text("\(resort.country.localizedCountryName()), \(resort.region)")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Category-specific value
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxxs) {
                    Text(getCategoryValue())
                        .font(DesignSystem.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(category.color)
                    
                    Text(getCategoryUnit())
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous)
                    .stroke(DesignSystem.Colors.separator.opacity(0.5), lineWidth: 0.5)
            )
            .shadow(
                color: DesignSystem.Shadow.small.color,
                radius: DesignSystem.Shadow.small.radius,
                x: DesignSystem.Shadow.small.x,
                y: DesignSystem.Shadow.small.y
            )
        }
        .disabled(!isEnabled)
        .task(id: category) {
            if category == .hotelRating {
                await calculateHotelRating()
            }
        }
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color.brown
        default: return .gray
        }
    }
    
    private func getCategoryValue() -> String {
        switch category {
        case .snowfall:
            // For snowfall, we use elevation as proxy for snow (higher = more snow)
            return "\(resort.maxElevation)"
        case .totalSlopes:
            return "\(resort.totalSlopes)"
        case .maxElevation:
            return "\(resort.maxElevation)"
        case .hotelRating:
            return hotelRating
        }
    }
    
    private func getCategoryUnit() -> String {
        switch category {
        case .snowfall:
            return "m"  // Using elevation as proxy
        case .totalSlopes:
            return "km"
        case .maxElevation:
            return "m"
        case .hotelRating:
            return "" // No unit for hotel rating
        }
    }
    
    @MainActor
    private func calculateHotelRating() async {
        let accommodations = accommodationDB.getAccommodations(for: resort)
        
        print("🔍 [DEBUG] calculateHotelRating for \(resort.name): \(accommodations.count) accommodations found")
        
        // Falls keine Accommodations in der Datenbank vorhanden sind, verwende eine geschätzte Bewertung
        guard !accommodations.isEmpty else {
            // Verwende eine grobe Schätzung basierend auf Resort-Qualität als Fallback
            let resortScore = calculateResortBasedRating()
            hotelRating = String(format: "%.1f", resortScore)
            print("🏔️ [DEBUG] Using resort-based rating for \(resort.name): \(hotelRating)")
            return
        }
        
        var ratedAccommodations: [CachedAccommodation] = []
        
        for cachedAccommodation in accommodations {
            let accommodation = await cachedAccommodation.toAccommodation(resort: resort)
            if accommodation.rating != nil {
                ratedAccommodations.append(cachedAccommodation)
            }
        }
        
        guard !ratedAccommodations.isEmpty else {
            // Fallback wenn keine Bewertungen vorhanden
            let resortScore = calculateResortBasedRating()
            hotelRating = String(format: "%.1f", resortScore)
            print("🏔️ [DEBUG] No rated accommodations, using resort-based rating for \(resort.name): \(hotelRating)")
            return
        }
        
        var totalRating: Double = 0
        for cachedAccommodation in ratedAccommodations {
            let accommodation = await cachedAccommodation.toAccommodation(resort: resort)
            if let rating = accommodation.rating {
                totalRating += rating
            }
        }
        
        let avgRating = totalRating / Double(ratedAccommodations.count)
        hotelRating = String(format: "%.1f", avgRating)
        print("⭐ [DEBUG] Calculated hotel rating for \(resort.name): \(hotelRating) from \(ratedAccommodations.count) hotels")
    }
    
    private func calculateResortBasedRating() -> Double {
        // Grobe Schätzung basierend auf Resort-Eigenschaften
        var score: Double = 3.0 // Basis-Score
        
        // Bonus für große Skigebiete
        if resort.totalSlopes > 200 { score += 0.5 }
        else if resort.totalSlopes > 100 { score += 0.3 }
        
        // Bonus für hohe Lagen
        if resort.maxElevation > 2500 { score += 0.5 }
        else if resort.maxElevation > 2000 { score += 0.3 }
        
        // Bekannte Premium-Destinationen
        let premiumResorts = ["St. Moritz", "Verbier", "Zermatt", "Courchevel", "Val d'Isère", "Kitzbühel"]
        if premiumResorts.contains(where: { resort.name.contains($0) }) {
            score += 0.8
        }
        
        return min(score, 5.0)
    }
    
}

#Preview {
    VStack {
        Top3SkiResortsCard()
        Spacer()
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}