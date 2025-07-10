import SwiftUI
import Foundation

struct ResortPickerView: View {
    @ObservedObject var viewModel: SkiResortViewModel
    @ObservedObject var favoritesManager = FavoritesManager.shared
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar with modern design
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    TextField("search_placeholder".localized, text: $viewModel.searchText)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            HapticFeedback.impact(.light)
                            withAnimation(DesignSystem.Animation.fast) {
                                viewModel.searchText = ""
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
                .padding(DesignSystem.Spacing.md)
                
                // Resort List with modern design
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.xs) {
                        ForEach(viewModel.filteredResorts) { resort in
                            ResortRowView(
                                resort: resort,
                                isFavorite: favoritesManager.isFavorite(resort),
                                onResortTap: {
                                    HapticFeedback.impact(.light)
                                    viewModel.selectedResort = resort
                                    dismiss()
                                },
                                onFavoriteTap: {
                                    HapticFeedback.impact(.light)
                                    withAnimation(DesignSystem.Animation.medium) {
                                        favoritesManager.toggleFavorite(resort)
                                    }
                                }
                            )
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.sm)
                }
            }
            .navigationTitle("select_ski_resort".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close".localized) {
                        HapticFeedback.impact(.light)
                        dismiss()
                    }
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
        }
    }
}

// MARK: - Resort Row View
struct ResortRowView: View {
    let resort: SkiResort
    let isFavorite: Bool
    let onResortTap: () -> Void
    let onFavoriteTap: () -> Void
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        Button(action: onResortTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Resort Icon
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "mountain.2.fill")
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                // Resort Information
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(resort.name)
                        .font(DesignSystem.Typography.calloutEmphasized)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .lineLimit(1)
                    
                    Text("\(resort.country.localizedCountryName()), \(resort.region)")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .lineLimit(1)
                    
                    // Resort Stats
                    HStack(spacing: DesignSystem.Spacing.md) {
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            Image(systemName: "figure.skiing.downhill")
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(DesignSystem.Colors.primary)
                            Text("\(resort.totalSlopes) km")
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                        
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            Image(systemName: "mountain.2")
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(DesignSystem.Colors.success)
                            Text("\(resort.maxElevation) m")
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(DesignSystem.Colors.success)
                        }
                    }
                }
                
                Spacer()
                
                // Favorite Button
                Button(action: onFavoriteTap) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(isFavorite ? DesignSystem.Colors.accent : DesignSystem.Colors.quaternaryText)
                        .frame(width: DesignSystem.Layout.minTouchTarget, height: DesignSystem.Layout.minTouchTarget)
                }
                                .scaleEffect(isFavorite ? 1.1 : 1.0)
                .animation(DesignSystem.Animation.spring, value: isFavorite)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous)
                    .stroke(DesignSystem.Colors.separator.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(
                color: DesignSystem.Shadow.small.color,
                radius: DesignSystem.Shadow.small.radius,
                x: DesignSystem.Shadow.small.x,
                y: DesignSystem.Shadow.small.y
            )
        }
            }
}

struct ResortInfoCard: View {
    let resort: SkiResort
    let onTap: (() -> Void)?
    @StateObject private var weatherService = OpenMeteoService()
    @State private var historicalSnowData: HistoricalSnowData?
    @State private var showingHistoricalSnow = false
    @ObservedObject private var localization = LocalizationService.shared
    
    init(resort: SkiResort, onTap: (() -> Void)? = nil) {
        self.resort = resort
        self.onTap = onTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header mit Gradient Background
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🎿")
                        .font(.title)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(resort.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("\(resort.country.localizedCountryName()), \(resort.region)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    Spacer()
                    
                    // Chevron Icon für Detail-Ansicht
                    if onTap != nil {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16, corners: [.topLeft, .topRight])
            
            // Statistiken - Größer und prominenter
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                
                // Pisten Kilometer - Größer dargestellt
                StatisticCard(
                    icon: "figure.skiing.downhill",
                    value: "\(resort.totalSlopes)",
                    unit: "km",
                    title: "slopes".localized,
                    color: .blue,
                    isHighlighted: true
                )
                
                // Höhe - Größer dargestellt
                StatisticCard(
                    icon: "mountain.2.fill",
                    value: "\(resort.maxElevation)",
                    unit: "m",
                    title: "max_height".localized,
                    color: .green,
                    isHighlighted: true
                )
                
                // Historischer Schneefall - Neu und prominent
                StatisticCard(
                    icon: "cloud.snow.fill",
                    value: historicalSnowData?.averageSnowfall != nil ? String(format: "%.0f", historicalSnowData!.averageSnowfall) : "---",
                    unit: "cm",
                    title: "avg_snow_5y".localized,
                    color: .cyan,
                    isHighlighted: true
                )
            }
            .padding(.horizontal, 20)
            
            // Link zu detaillierten historischen Schneedaten
            if historicalSnowData != nil {
                Button(action: {
                    showingHistoricalSnow = true
                }) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.blue)
                        Text("detailed_snow_statistics".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .sheet(isPresented: $showingHistoricalSnow) {
                    if let historicalData = historicalSnowData {
                        HistoricalSnowView(historicalData: historicalData)
                    } else {
                        // In case of error, show error view
                        HistoricalSnowView(error: OpenMeteoError.networkError("Schneedaten konnten nicht geladen werden"))
                    }
                }
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onTapGesture {
            onTap?()
        }
        .onAppear {
            loadHistoricalSnowData()
        }
    }
    
    private func loadHistoricalSnowData() {
        Task {
            do {
                let snowData = try await weatherService.fetchHistoricalSnowData(for: resort.coordinate)
                await MainActor.run {
                    self.historicalSnowData = snowData
                }
            } catch {
                print("Fehler beim Laden der historischen Schneedaten: \(error)")
            }
        }
    }
}

struct StatisticCard: View {
    let icon: String
    let value: String
    let unit: String
    let title: String
    let color: Color
    let isHighlighted: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Icon mit farbigem Hintergrund
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: isHighlighted ? 56 : 48, height: isHighlighted ? 56 : 48)
                
                Image(systemName: icon)
                    .font(isHighlighted ? DesignSystem.Typography.title2 : DesignSystem.Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            // Großer Wert
            HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.xxs) {
                Text(value)
                    .font(isHighlighted ? DesignSystem.Typography.largeTitle : DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                Text(unit)
                    .font(isHighlighted ? DesignSystem.Typography.body : DesignSystem.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            // Titel
            Text(title)
                .font(isHighlighted ? DesignSystem.Typography.caption1 : DesignSystem.Typography.caption2)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
    }
}

// Extension für custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}