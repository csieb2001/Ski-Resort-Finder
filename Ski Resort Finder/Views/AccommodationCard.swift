import SwiftUI
import Foundation

struct AccommodationCard: View {
    let accommodation: Accommodation // Simplified: direct reference
    let isSelectionMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onAccommodationUpdated: ((Accommodation) -> Void)?
    @ObservedObject private var localization = LocalizationService.shared
    @State private var selectedAccommodationForDetail: Accommodation? = nil
    @State private var selectedAccommodationForBooking: Accommodation? = nil
    
    init(accommodation: Accommodation, isSelectionMode: Bool = false, isSelected: Bool = false, onTap: @escaping () -> Void, onAccommodationUpdated: ((Accommodation) -> Void)? = nil) {
        self.accommodation = accommodation
        self.isSelectionMode = isSelectionMode
        self.isSelected = isSelected
        self.onTap = onTap
        self.onAccommodationUpdated = onAccommodationUpdated
    }
    
    var body: some View {
        // Compact list item without image
        Button(action: {
            HapticFeedback.impact(.light)
            if isSelectionMode {
                onTap() // Selection mode: use onTap for selection
            } else {
                selectedAccommodationForDetail = accommodation // Normal mode: open detail view
            }
        }) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Selection Checkbox
                if isSelectionMode {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundColor(isSelected ? DesignSystem.Colors.success : .gray)
                    }
                }
                
                // Accommodation content
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    // Header with name and essential info
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                            Text(accommodation.name)
                                .font(DesignSystem.Typography.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                .lineLimit(1)
                            
                            // Distance to lift and rating in one line
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                Label("\(accommodation.distanceToLift)m", systemImage: "figure.skiing.downhill")
                                    .font(DesignSystem.Typography.caption1)
                                    .foregroundColor(DesignSystem.Colors.primary)
                                
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundColor(DesignSystem.Colors.accent)
                                    Text(String(format: "%.1f", accommodation.rating))
                                        .font(DesignSystem.Typography.caption1)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Price and action
                        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxs) {
                            Text(accommodation.priceCategory.rawValue)
                                .font(DesignSystem.Typography.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(colorForPriceCategory(accommodation.priceCategory))
                            
                            if !isSelectionMode {
                                Button(action: {
                                    selectedAccommodationForBooking = accommodation
                                }) {
                                    Text("contact".localized)
                                        .font(DesignSystem.Typography.caption1)
                                        .foregroundColor(DesignSystem.Colors.primary)
                                }
                            }
                        }
                    }
                    
                    // Compact amenities and email status on one line
                    HStack {
                        // Wellness amenity icons
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            if accommodation.hasPool {
                                WellnessFeatureIcon(
                                    icon: "drop.fill",
                                    color: .cyan,
                                    feature: "pool".localized
                                )
                            }
                            if accommodation.hasJacuzzi {
                                WellnessFeatureIcon(
                                    icon: "sparkles",
                                    color: .purple,
                                    feature: "jacuzzi".localized
                                )
                            }
                            if accommodation.hasSpa {
                                WellnessFeatureIcon(
                                    icon: "leaf.fill",
                                    color: .green,
                                    feature: "spa".localized
                                )
                            }
                            if accommodation.hasSauna {
                                WellnessFeatureIcon(
                                    icon: "thermometer.sun.fill",
                                    color: .orange,
                                    feature: "sauna".localized
                                )
                            }
                            
                            // Show "spa pending" indicator if none are available
                            if !hasWellnessFeatures {
                                HStack(spacing: DesignSystem.Spacing.xxs) {
                                    Circle()
                                        .fill(DesignSystem.Colors.secondaryText)
                                        .frame(width: 6, height: 6)
                                    
                                    Text("spa_pending".localized)
                                        .font(DesignSystem.Typography.caption2)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Email status (compact)
                        emailStatusIndicator
                    }
                }
                .padding(DesignSystem.Spacing.sm)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(DesignSystem.Spacing.md)
        .glassCard()
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: DesignSystem.CornerRadius.continuous)
                .stroke(
                    isSelected ? DesignSystem.Colors.success : Color.clear,
                    lineWidth: isSelected ? 2 : 0
                )
        )
        .animation(DesignSystem.Animation.medium, value: isSelected)
        .onAppear {
            // Keine automatische E-Mail-Suche - verwende lokale Daten
        }
        .sheet(item: $selectedAccommodationForDetail) { detailAccommodation in
            AccommodationDetailView(accommodation: detailAccommodation) { updatedAccommodation in
                // Notify parent about the update - no local state to maintain
                onAccommodationUpdated?(updatedAccommodation)
            }
        }
        .sheet(item: $selectedAccommodationForBooking) { accommodation in
            BookingRequestView(accommodation: accommodation)
        }
    }
    
    // MARK: - Helper Functions
    
    private var emailStatusIndicator: some View {
        return HStack(spacing: DesignSystem.Spacing.xxs) {
            let hasEmail = accommodation.email != nil && !accommodation.email!.isEmpty
            
            Circle()
                .fill(hasEmail ? DesignSystem.Colors.success : DesignSystem.Colors.secondaryText)
                .frame(width: 6, height: 6)
            
            Text(hasEmail ? "email_found".localized : "email_pending".localized)
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(hasEmail ? DesignSystem.Colors.success : DesignSystem.Colors.secondaryText)
        }
    }
    
    private var hasEmailAvailable: Bool {
        return accommodation.email != nil && !accommodation.email!.isEmpty
    }
    
    private var hasWellnessFeatures: Bool {
        return accommodation.hasPool || accommodation.hasJacuzzi || accommodation.hasSpa || accommodation.hasSauna
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

// MARK: - Wellness Feature Icon Component

struct WellnessFeatureIcon: View {
    let icon: String
    let color: Color
    let feature: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 20, height: 20)
            
            Image(systemName: icon)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .help(feature) // Tooltip on hover
    }
}