import SwiftUI
import MapKit

struct Top3SkiResortsCard: View {
    @ObservedObject private var localization = LocalizationService.shared
    @ObservedObject private var accommodationDB = AccommodationDatabase.shared
    @State private var selectedCategory: TopCategory = .snowfall
    @State private var topResorts: [SkiResort] = []
    @State private var isLoadingData: Bool = true
    @State private var showFullChart: Bool = false
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
        case avgElevation
        case maxElevation
        case hotelRating

        var title: String {
            switch self {
            case .snowfall:
                return "top3_snowfall".localized
            case .totalSlopes:
                return "top3_slope_kilometers".localized
            case .avgElevation:
                return "top3_avg_elevation".localized
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
            case .avgElevation:
                return "chart.line.flattrend.xyaxis"
            case .maxElevation:
                return "arrow.up.to.line"
            case .hotelRating:
                return "star.fill"
            }
        }

        var shortTitle: String {
            switch self {
            case .snowfall: return "Schnee"
            case .totalSlopes: return "Pisten"
            case .avgElevation: return "Ø Höhe"
            case .maxElevation: return "Max"
            case .hotelRating: return "Hotels"
            }
        }

        var color: Color {
            switch self {
            case .snowfall:
                return .blue
            case .totalSlopes:
                return .green
            case .avgElevation:
                return .cyan
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
                
                // Category Picker - compact icon row
                HStack(spacing: 0) {
                    ForEach(TopCategory.allCases, id: \.self) { category in
                        Button {
                            HapticFeedback.selection()
                            withAnimation(DesignSystem.Animation.medium) {
                                selectedCategory = category
                            }
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 14))
                                Text(category.shortTitle)
                                    .font(.system(size: 9, weight: .medium))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.xs)
                            .foregroundColor(selectedCategory == category ? .white : DesignSystem.Colors.secondaryText)
                            .background(
                                selectedCategory == category ? category.color : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: .continuous))
                        }
                    }
                }
                .padding(3)
                .glassEffect(in: .rect(cornerRadius: DesignSystem.CornerRadius.sm + 3, style: .continuous))
                
                // Info Text für Hotel-Bewertungen
                if selectedCategory == .hotelRating {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "info.circle")
                            .foregroundColor(DesignSystem.Colors.accent)
                            .font(DesignSystem.Typography.caption1)
                        Text("top3_hotel_rating_info".localized)
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                            .fill(DesignSystem.Colors.accent.opacity(0.1))
                    )
                }
            }
            
            // Top 3 List
            VStack(spacing: DesignSystem.Spacing.sm) {
                if isLoadingData {
                    // Loading State
                    ForEach(0..<3, id: \.self) { index in
                        HStack(spacing: DesignSystem.Spacing.md) {
                            // Rank Badge
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 36, height: 36)
                                
                                Text("\(index + 1)")
                                    .font(DesignSystem.Typography.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                            }
                            
                            // Loading Content
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 16)
                                    .cornerRadius(4)
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 12)
                                    .cornerRadius(4)
                            }
                            
                            Spacer()
                            
                            // Loading Value
                            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxxs) {
                                if selectedCategory == .snowfall {
                                    HStack(spacing: DesignSystem.Spacing.xs) {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .progressViewStyle(CircularProgressViewStyle(tint: selectedCategory.color))
                                        Text("loading_snow_data".localized)
                                            .font(DesignSystem.Typography.caption2)
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                } else {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .progressViewStyle(CircularProgressViewStyle(tint: selectedCategory.color))
                                }
                            }
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                        .redacted(reason: .placeholder)
                    }
                } else {
                    // Actual Data
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

                // "Alle anzeigen" Button
                if !topResorts.isEmpty {
                    Button {
                        HapticFeedback.impact(.light)
                        showFullChart = true
                    } label: {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .font(DesignSystem.Typography.caption1)
                            Text("show_all_rankings".localized)
                                .font(DesignSystem.Typography.caption1)
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(DesignSystem.Typography.caption2)
                        }
                        .foregroundColor(selectedCategory.color)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                    }
                }
            }
        }
        .sectionContainer()
        .sheet(isPresented: $showFullChart) {
            FullRankingChartView(
                category: selectedCategory,
                onResortSelected: onResortSelected
            )
        }
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: DesignSystem.CornerRadius.continuous)
                .fill(selectedCategory.color.opacity(0.05))
                .allowsHitTesting(false)
        )
        .animation(DesignSystem.Animation.medium, value: selectedCategory)
        .task(id: selectedCategory) {
            isLoadingData = true
            topResorts = await getTop3Resorts()
            isLoadingData = false
        }
    }
    
    private func getTop3Resorts() async -> [SkiResort] {
        let allResorts = SkiResortDatabase.shared.allSkiResorts
        
        print("[DEBUG] Total resorts available: \(allResorts.count)")
        print("[DEBUG] Selected category: \(selectedCategory)")
        
        let result: [SkiResort]
        switch selectedCategory {
        case .snowfall:
            result = await getTop3BySnowfall(resorts: allResorts)
        case .totalSlopes:
            // Sort by total slope area/distance (usually in km)
            let sortedResorts = allResorts
                .filter { $0.totalSlopes > 0 }  // Only include resorts with valid slope data
                .sorted { $0.totalSlopes > $1.totalSlopes }
                print("[DEBUG] Top slope resorts: \(sortedResorts.prefix(5).map { "\($0.name): \($0.totalSlopes)km" })")
            result = Array(sortedResorts.prefix(3))
        case .avgElevation:
            // Sort by average elevation (midpoint of min/max) - higher = more snow-reliable
            let sortedResorts = allResorts
                .filter { $0.maxElevation > 0 && $0.minElevation > 0 }
                .sorted { ($0.maxElevation + $0.minElevation) > ($1.maxElevation + $1.minElevation) }
                print("[DEBUG] Top avg elevation: \(sortedResorts.prefix(5).map { "\($0.name): \(($0.maxElevation + $0.minElevation) / 2)m" })")
            result = Array(sortedResorts.prefix(3))
        case .maxElevation:
            // Sort by maximum elevation
            let sortedResorts = allResorts
                .filter { $0.maxElevation > 0 }
                .sorted { $0.maxElevation > $1.maxElevation }
                print("[DEBUG] Top elevation resorts: \(sortedResorts.prefix(5).map { "\($0.name): \($0.maxElevation)m" })")
            result = Array(sortedResorts.prefix(3))
        case .hotelRating:
            result = await getTop3ByHotelRating(resorts: allResorts)
        }
        
        print("[DEBUG] Result count for \(selectedCategory): \(result.count)")
        return result
    }
    
    private func getTop3BySnowfall(resorts: [SkiResort]) async -> [SkiResort] {
        print("[DEBUG] Getting top 3 by snowfall data...")

        // Phase 1: Verwende nur bereits gecachte Daten (sofort, kein API-Call)
        var resortSnowData: [(resort: SkiResort, snowfall: Double)] = []

        for resort in resorts {
            if SnowDataCache.shared.hasCachedData(for: resort.coordinate) {
                if let snowData = await SnowDataCache.shared.getHistoricalSnowData(for: resort.coordinate) {
                    resortSnowData.append((resort: resort, snowfall: snowData.averageSnowfall))
                    print("[DEBUG] \(resort.name): \(Int(snowData.averageSnowfall))cm (cached)")
                }
            }
        }

        // Wenn mindestens 3 gecachte Resorts vorhanden, verwende diese sofort
        if resortSnowData.count >= 3 {
            let sorted = resortSnowData.sorted { $0.snowfall > $1.snowfall }
            let top3 = Array(sorted.prefix(3).map { $0.resort })
            print("[DEBUG] Top 3 by cached snowfall: \(sorted.prefix(3).map { "\($0.resort.name): \(Int($0.snowfall))cm" })")
            return top3
        }

        // Phase 2: Nicht genug gecachte Daten - Fallback auf Höhenlage
        // und starte Preloading im Hintergrund für den nächsten Aufruf
        print("[DEBUG] Not enough cached snow data (\(resortSnowData.count)/3), using elevation fallback")

        let fallback = resorts
            .sorted { $0.maxElevation > $1.maxElevation }
            .prefix(3)

        // Starte Preloading für Top-Resorts im Hintergrund (für nächstes Mal)
        let topResortsByElevation = Array(resorts.sorted { $0.maxElevation > $1.maxElevation }.prefix(10))
        Task.detached {
            SnowDataCache.shared.preloadSnowData(for: topResortsByElevation.map { $0.coordinate })
        }

        return Array(fallback)
    }
    
    // KEINE FAKE DATEN: Echte Schneedaten aus ERA5/OpenMeteo API verwenden
    static func getRealSnowfallData(for resort: SkiResort) async -> Double? {
        let snowData = await SnowDataCache.shared.getHistoricalSnowData(for: resort.coordinate)
        return snowData?.averageSnowfall // in cm aus echten API-Daten
    }
    
    private func getTop3ByHotelRating(resorts: [SkiResort]) async -> [SkiResort] {
        print("[DEBUG] Getting top 3 resorts by hotel rating (LAZY LOADING)...")
        
        // LAZY LOADING: Nur Resort-basierte Bewertung, KEINE Hotel-Daten laden!
        // Hotels werden nur geladen wenn User ein Skigebiet auswählt
        var resortRatings: [(resort: SkiResort, avgRating: Double, accommodationCount: Int)] = []
        
        for resort in resorts {
            // Prüfe nur ob bereits geladene/gecachte Accommodations vorhanden sind
            let cachedAccommodations = accommodationDB.getAccommodations(for: resort)
            
            if !cachedAccommodations.isEmpty {
                // Verwende bereits geladene Daten (OHNE neue API-Calls)
                print("[DEBUG] \(resort.name): Using \(cachedAccommodations.count) cached accommodations")
                
                var ratedAccommodations: [(cached: CachedAccommodation, accommodation: Accommodation)] = []
                
                // Convert all accommodations once and filter rated ones
                for cachedAccommodation in cachedAccommodations {
                    let accommodation = await cachedAccommodation.toAccommodation(resort: resort)
                    if accommodation.rating != nil {
                        ratedAccommodations.append((cached: cachedAccommodation, accommodation: accommodation))
                    }
                }
                
                if !ratedAccommodations.isEmpty {
                    // Calculate average rating from already converted accommodations
                    var totalRating: Double = 0
                    for (_, accommodation) in ratedAccommodations {
                        if let rating = accommodation.rating {
                            totalRating += rating
                        }
                    }
                    
                    let avgRating = totalRating / Double(ratedAccommodations.count)
                    resortRatings.append((resort: resort, avgRating: avgRating, accommodationCount: ratedAccommodations.count))
                    
                    print("[DEBUG] \(resort.name): \(String(format: "%.2f", avgRating)) (\(ratedAccommodations.count) hotels)")
                }
            } else {
                // FALLBACK: Resort-basierte Schätzung OHNE API-Calls
                let resortScore = calculateResortBasedRating(for: resort)
                resortRatings.append((resort: resort, avgRating: resortScore, accommodationCount: 0))
                
                print("[DEBUG] \(resort.name): Using resort-based rating \(String(format: "%.2f", resortScore)) (no hotel data)")
            }
        }
        
        // Sort by average rating (descending)
        let sortedResorts = resortRatings
            .sorted { $0.avgRating > $1.avgRating }
            .prefix(3)
            .map { $0.resort }
        
            print("[DEBUG] Top 3 by hotel rating (LAZY): \(sortedResorts.map { $0.name })")
        return Array(sortedResorts)
    }
    
    private func calculateResortBasedRating(for resort: SkiResort) -> Double {
        // Fallback-Bewertung basierend auf Resort-Eigenschaften (OHNE Hotel-Daten)
        var score: Double = 2.5 // Konservativer Basis-Score
        
        // 1. Skigebiet-Qualität (40% Gewichtung)
        let resortQuality = calculateResortQualityScore(for: resort)
        score += resortQuality * 1.0
        
        // 2. Höhenlage-Bonus (30% Gewichtung) 
        let elevationScore = calculateElevationScore(for: resort)
        score += elevationScore * 0.75
        
        // 3. Länder-Bonus (30% Gewichtung)
        let countryBonus = calculateCountryBonus(for: resort)
        score += countryBonus * 0.75
        
        return min(score, 5.0)
    }
    
    private func calculateResortQualityScore(for resort: SkiResort) -> Double {
        var score: Double = 0.3 // Basis
        
        // Pistenlänge
        switch resort.totalSlopes {
        case 0...50:        score += 0.1
        case 51...150:      score += 0.2
        case 151...300:     score += 0.3
        case 301...500:     score += 0.4
        default:            score += 0.5  // 500+ km
        }
        
        // Höhenunterschied
        let elevation = resort.maxElevation - resort.minElevation
        switch elevation {
        case 0...500:       score += 0.05
        case 501...1000:    score += 0.1
        case 1001...1500:   score += 0.15
        default:            score += 0.2  // 1500+ m
        }
        
        return min(score, 1.0)
    }
    
    private func calculateElevationScore(for resort: SkiResort) -> Double {
        let avgElevation = (resort.maxElevation + resort.minElevation) / 2
        
        switch avgElevation {
        case 0...800:       return 0.3
        case 801...1200:    return 0.5
        case 1201...1800:   return 0.7
        case 1801...2500:   return 0.9
        default:            return 1.0  // 2500m+
        }
    }
    
    private func calculateCountryBonus(for resort: SkiResort) -> Double {
        // Länder mit traditionell hohen Hotel-Standards
        let premiumCountries = ["Schweiz", "Switzerland", "Österreich", "Austria"]
        let goodCountries = ["Frankreich", "France", "Italien", "Italy", "Deutschland", "Germany"]
        
        if premiumCountries.contains(resort.country) {
            return 1.0  // Premium-Standards
        } else if goodCountries.contains(resort.country) {
            return 0.7  // Gute Standards
        } else {
            return 0.4  // Durchschnittliche Standards
        }
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
    @State private var realSnowfall: String = "N/A"
    @State private var isLoadingSnowData: Bool = false
    
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
                    if category == .snowfall && isLoadingSnowData {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            ProgressView()
                                .scaleEffect(0.7)
                                .progressViewStyle(CircularProgressViewStyle(tint: category.color))
                            Text("loading_snow_data".localized)
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    } else {
                        Text(getCategoryValue())
                            .font(DesignSystem.Typography.title3)
                            .fontWeight(.bold)
                            .foregroundColor(category.color)
                        
                        Text(getCategoryUnit())
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .glassEffect(in: .rect(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
        }
        .disabled(!isEnabled)
        .task(id: category) {
            if category == .hotelRating {
                await calculateHotelRating()
            } else if category == .snowfall {
                await loadRealSnowfallData()
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
            return realSnowfall
        case .totalSlopes:
            return "\(resort.totalSlopes)"
        case .avgElevation:
            return "\((resort.maxElevation + resort.minElevation) / 2)"
        case .maxElevation:
            return "\(resort.maxElevation)"
        case .hotelRating:
            return hotelRating
        }
    }
    
    private func getCategoryUnit() -> String {
        switch category {
        case .snowfall:
            return "cm"
        case .totalSlopes:
            return "km"
        case .avgElevation:
            return "m Ø"
        case .maxElevation:
            return "m"
        case .hotelRating:
            return ""
        }
    }
    
    @MainActor
    private func loadRealSnowfallData() async {
        isLoadingSnowData = true
        
        if let snowfallData = await Top3SkiResortsCard.getRealSnowfallData(for: resort) {
            realSnowfall = "\(Int(snowfallData))"
            print("[DEBUG] Loaded real snowfall for \(resort.name): \(Int(snowfallData))cm")
        } else {
            realSnowfall = "N/A"
            print("[ERROR] [DEBUG] No snow data available for \(resort.name) - KEINE FAKE-DATEN POLICY")
        }
        
        isLoadingSnowData = false
    }
    
    @MainActor
    private func calculateHotelRating() async {
        // LAZY LOADING: Verwende nur bereits gecachte Daten
        let cachedAccommodations = accommodationDB.getAccommodations(for: resort)
        
        print("[DEBUG] calculateHotelRating for \(resort.name): \(cachedAccommodations.count) cached accommodations found")
        
        if !cachedAccommodations.isEmpty {
            // Verwende bereits geladene Daten (OHNE neue API-Calls)
            var ratedAccommodations: [Accommodation] = []
            
            // Convert all accommodations once and filter rated ones
            for cachedAccommodation in cachedAccommodations {
                let accommodation = await cachedAccommodation.toAccommodation(resort: resort)
                if accommodation.rating != nil {
                    ratedAccommodations.append(accommodation)
                }
            }
            
            if !ratedAccommodations.isEmpty {
                // Calculate average rating from already converted accommodations
                var totalRating: Double = 0
                for accommodation in ratedAccommodations {
                    if let rating = accommodation.rating {
                        totalRating += rating
                    }
                }
                
                let avgRating = totalRating / Double(ratedAccommodations.count)
                hotelRating = String(format: "%.1f", avgRating)
                print("[DEBUG] Calculated hotel rating for \(resort.name): \(hotelRating) from \(ratedAccommodations.count) hotels")
                return
            }
        }
        
        // FALLBACK: Resort-basierte Schätzung OHNE API-Calls
        let resortScore = calculateResortBasedRating(for: resort)
        hotelRating = String(format: "%.1f", resortScore)
        print("[DEBUG] Using resort-based rating for \(resort.name): \(hotelRating) (no hotel data)")
    }
    
    private func calculateResortBasedRating(for resort: SkiResort) -> Double {
        // Fallback-Bewertung basierend auf Resort-Eigenschaften (OHNE Hotel-Daten)
        var score: Double = 2.5 // Konservativer Basis-Score
        
        // 1. Skigebiet-Qualität (40% Gewichtung)
        let resortQuality = calculateResortQualityScore(for: resort)
        score += resortQuality * 1.0
        
        // 2. Höhenlage-Bonus (30% Gewichtung) 
        let elevationScore = calculateElevationScore(for: resort)
        score += elevationScore * 0.75
        
        // 3. Länder-Bonus (30% Gewichtung)
        let countryBonus = calculateCountryBonus(for: resort)
        score += countryBonus * 0.75
        
        return min(score, 5.0)
    }
    
    private func calculateResortQualityScore(for resort: SkiResort) -> Double {
        var score: Double = 0.3 // Basis
        
        // Pistenlänge
        switch resort.totalSlopes {
        case 0...50:        score += 0.1
        case 51...150:      score += 0.2
        case 151...300:     score += 0.3
        case 301...500:     score += 0.4
        default:            score += 0.5  // 500+ km
        }
        
        // Höhenunterschied
        let elevation = resort.maxElevation - resort.minElevation
        switch elevation {
        case 0...500:       score += 0.05
        case 501...1000:    score += 0.1
        case 1001...1500:   score += 0.15
        default:            score += 0.2  // 1500+ m
        }
        
        return min(score, 1.0)
    }
    
    private func calculateElevationScore(for resort: SkiResort) -> Double {
        let avgElevation = (resort.maxElevation + resort.minElevation) / 2
        
        switch avgElevation {
        case 0...800:       return 0.3
        case 801...1200:    return 0.5
        case 1201...1800:   return 0.7
        case 1801...2500:   return 0.9
        default:            return 1.0  // 2500m+
        }
    }
    
    private func calculateCountryBonus(for resort: SkiResort) -> Double {
        // Länder mit traditionell hohen Hotel-Standards
        let premiumCountries = ["Schweiz", "Switzerland", "Österreich", "Austria"]
        let goodCountries = ["Frankreich", "France", "Italien", "Italy", "Deutschland", "Germany"]
        
        if premiumCountries.contains(resort.country) {
            return 1.0  // Premium-Standards
        } else if goodCountries.contains(resort.country) {
            return 0.7  // Gute Standards
        } else {
            return 0.4  // Durchschnittliche Standards
        }
    }
    
}

// MARK: - Full Ranking Chart View

struct FullRankingChartView: View {
    let category: Top3SkiResortsCard.TopCategory
    let onResortSelected: ((SkiResort) -> Void)?
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localization = LocalizationService.shared
    @State private var rankedResorts: [(resort: SkiResort, value: Double)] = []
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            ZStack {
                MountainBackgroundView()
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.sm) {
                        // Header with category info
                        HStack {
                            Image(systemName: category.icon)
                                .font(DesignSystem.Typography.title3)
                                .foregroundColor(category.color)
                            VStack(alignment: .leading) {
                                Text(category.title)
                                    .font(DesignSystem.Typography.headline)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                Text("\(rankedResorts.count) \("ski_resorts".localized)")
                                    .font(DesignSystem.Typography.caption1)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            Spacer()
                        }
                        .padding(DesignSystem.Spacing.md)
                        .glassEffect(in: .rect(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous))

                        if isLoading {
                            ProgressView()
                                .padding(DesignSystem.Spacing.xxl)
                        } else {
                            ForEach(Array(rankedResorts.enumerated()), id: \.offset) { index, item in
                                RankingRow(
                                    resort: item.resort,
                                    rank: index + 1,
                                    value: item.value,
                                    maxValue: rankedResorts.first?.value ?? 1,
                                    category: category
                                ) {
                                    dismiss()
                                    onResortSelected?(item.resort)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Layout.screenPadding)
                    .padding(.vertical, DesignSystem.Spacing.md)
                }
            }
            .navigationTitle("ranking_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close".localized) { dismiss() }
                }
            }
        }
        .task {
            await loadRankings()
        }
    }

    private func loadRankings() async {
        let allResorts = SkiResortDatabase.shared.allSkiResorts

        switch category {
        case .snowfall:
            var results: [(SkiResort, Double)] = []
            for resort in allResorts {
                if SnowDataCache.shared.hasCachedData(for: resort.coordinate),
                   let data = await SnowDataCache.shared.getHistoricalSnowData(for: resort.coordinate) {
                    results.append((resort, data.averageSnowfall))
                }
            }
            rankedResorts = results.sorted { $0.1 > $1.1 }

        case .totalSlopes:
            rankedResorts = allResorts
                .filter { $0.totalSlopes > 0 }
                .sorted { $0.totalSlopes > $1.totalSlopes }
                .map { ($0, Double($0.totalSlopes)) }

        case .avgElevation:
            rankedResorts = allResorts
                .filter { $0.maxElevation > 0 && $0.minElevation > 0 }
                .sorted { ($0.maxElevation + $0.minElevation) > ($1.maxElevation + $1.minElevation) }
                .map { ($0, Double(($0.maxElevation + $0.minElevation) / 2)) }

        case .maxElevation:
            rankedResorts = allResorts
                .filter { $0.maxElevation > 0 }
                .sorted { $0.maxElevation > $1.maxElevation }
                .map { ($0, Double($0.maxElevation)) }

        case .hotelRating:
            rankedResorts = allResorts.map { ($0, 0.0) }
        }

        isLoading = false
    }
}

// MARK: - Ranking Row

struct RankingRow: View {
    let resort: SkiResort
    let rank: Int
    let value: Double
    let maxValue: Double
    let category: Top3SkiResortsCard.TopCategory
    let onTap: () -> Void

    private var barFraction: CGFloat {
        guard maxValue > 0 else { return 0 }
        return CGFloat(value / maxValue)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color.brown
        default: return DesignSystem.Colors.quaternaryText
        }
    }

    private var unitString: String {
        switch category {
        case .snowfall: return "cm"
        case .totalSlopes: return "km"
        case .avgElevation: return "m"
        case .maxElevation: return "m"
        case .hotelRating: return ""
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                // Rank number
                Text("\(rank)")
                    .font(DesignSystem.Typography.caption1)
                    .fontWeight(.bold)
                    .foregroundColor(rank <= 3 ? rankColor : DesignSystem.Colors.tertiaryText)
                    .frame(width: 28, alignment: .trailing)

                // Resort info
                VStack(alignment: .leading, spacing: 2) {
                    Text(resort.name)
                        .font(DesignSystem.Typography.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .lineLimit(1)

                    // Bar chart
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [category.color, category.color.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * barFraction)
                    }
                    .frame(height: 6)
                }

                // Value
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(Int(value))")
                        .font(DesignSystem.Typography.footnoteEmphasized)
                        .foregroundColor(category.color)
                    if !unitString.isEmpty {
                        Text(unitString)
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }
                .frame(width: 50, alignment: .trailing)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
        .glassEffect(in: .rect(cornerRadius: DesignSystem.CornerRadius.sm, style: .continuous))
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