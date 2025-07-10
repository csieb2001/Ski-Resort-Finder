import SwiftUI

// MARK: - Spa Filter Options
enum SpaFilterOption: String, CaseIterable {
    case pool = "pool"
    case jacuzzi = "jacuzzi"
    case spa = "spa"
    case sauna = "sauna"
    case noSpaFeatures = "no_spa_features"
    
    var displayName: String {
        switch self {
        case .pool:
            return "pool".localized
        case .jacuzzi:
            return "jacuzzi".localized
        case .spa:
            return "spa".localized
        case .sauna:
            return "sauna".localized
        case .noSpaFeatures:
            return "no_spa_features".localized
        }
    }
    
    var icon: String {
        switch self {
        case .pool:
            return "drop.fill"
        case .jacuzzi:
            return "sparkles"
        case .spa:
            return "leaf.fill"
        case .sauna:
            return "thermometer.sun.fill"
        case .noSpaFeatures:
            return "xmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .pool:
            return .cyan
        case .jacuzzi:
            return .purple
        case .spa:
            return .green
        case .sauna:
            return .orange
        case .noSpaFeatures:
            return DesignSystem.Colors.quaternaryText
        }
    }
}

// MARK: - Spa Wellness Filter Card
struct SpaWellnessFilterCard: View {
    @Binding var selectedSpaFeatures: Set<SpaFilterOption>
    @ObservedObject private var localization = LocalizationService.shared
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Collapsible Header
            Button(action: {
                HapticFeedback.impact(.light)
                withAnimation(DesignSystem.Animation.medium) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "drop.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                        .font(DesignSystem.Typography.callout)
                    
                    Text("spa_wellness_features".localized)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    // Selection indicator when collapsed
                    if !isExpanded && !selectedSpaFeatures.isEmpty {
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            Text("\(selectedSpaFeatures.count)")
                                .font(DesignSystem.Typography.caption1)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, DesignSystem.Spacing.xs)
                                .padding(.vertical, DesignSystem.Spacing.xxs)
                                .background(DesignSystem.Colors.primary)
                                .clipShape(Circle())
                            
                            Text("selected".localized)
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    // Clear all button (when expanded and items are selected)
                    if isExpanded && !selectedSpaFeatures.isEmpty {
                        Button(action: {
                            HapticFeedback.impact(.light)
                            withAnimation(DesignSystem.Animation.medium) {
                                selectedSpaFeatures.removeAll()
                            }
                        }) {
                            Text("clear_all".localized)
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.error)
                        }
                                            }
                    
                    // Chevron indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .animation(DesignSystem.Animation.fast, value: isExpanded)
                }
            }
                        
            // Expandable Content
            if isExpanded {
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Spa Feature Toggle Switches - Compact Layout
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        ForEach(SpaFilterOption.allCases, id: \.self) { option in
                            SpaFeatureToggleSwitch(
                                option: option,
                                isSelected: selectedSpaFeatures.contains(option),
                                onToggle: {
                                    HapticFeedback.impact(.light)
                                    withAnimation(DesignSystem.Animation.fast) {
                                        toggleSpaFeature(option)
                                    }
                                }
                            )
                        }
                    }
                    
                    // Selection summary
                    if !selectedSpaFeatures.isEmpty {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.success)
                            
                            Text(String(format: "spa_features_selected".localized, selectedSpaFeatures.count))
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Spacer()
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .sectionContainer()
    }
    
    private func toggleSpaFeature(_ option: SpaFilterOption) {
        // Handle special case: "No Spa Features" is exclusive
        if option == .noSpaFeatures {
            if selectedSpaFeatures.contains(.noSpaFeatures) {
                selectedSpaFeatures.remove(.noSpaFeatures)
            } else {
                selectedSpaFeatures = [.noSpaFeatures]
            }
        } else {
            // Remove "No Spa Features" when selecting actual features
            selectedSpaFeatures.remove(.noSpaFeatures)
            
            if selectedSpaFeatures.contains(option) {
                selectedSpaFeatures.remove(option)
            } else {
                selectedSpaFeatures.insert(option)
            }
        }
    }
}

// MARK: - Spa Feature Toggle Switch
struct SpaFeatureToggleSwitch: View {
    let option: SpaFilterOption
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
            // Feature Icon - Fixed width for alignment
            ZStack {
                Circle()
                    .fill(option.color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: option.icon)
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(option.color)
            }
            .frame(width: 32, height: 32) // Fixed frame for consistent alignment
            
            // Feature Name and Description - Fixed height for alignment
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(option.displayName)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if option == .noSpaFeatures {
                    Text("basic_accommodation".localized)
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                } else {
                    // Empty spacer for consistent height
                    Text("")
                        .font(DesignSystem.Typography.caption2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Toggle Switch - Fixed positioning
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { _ in onToggle() }
            ))
            .toggleStyle(SwitchToggleStyle(tint: option.color))
            .scaleEffect(0.8)
            .frame(width: 44, height: 28) // Fixed frame for toggle
        }
        .frame(height: 44) // Fixed row height for perfect alignment
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .background(
            isSelected ? 
            option.color.opacity(0.05) : 
            Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: DesignSystem.CornerRadius.continuous))
        .animation(DesignSystem.Animation.fast, value: isSelected)
    }
}

#Preview {
    VStack {
        SpaWellnessFilterCard(selectedSpaFeatures: .constant([.pool, .spa]))
            .padding()
    }
    .background(Color.gray.opacity(0.1))
}