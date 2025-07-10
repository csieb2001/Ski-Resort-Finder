import SwiftUI

struct SnowDataErrorView: View {
    let error: Error
    let onRetry: () -> Void
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Error Icon
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.error.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: errorIcon)
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(DesignSystem.Colors.error)
            }
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(errorTitle)
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(errorMessage)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.md)
            }
            
            if showRetryButton {
                Button(action: {
                    HapticFeedback.impact(.medium)
                    onRetry()
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "arrow.clockwise")
                            .font(DesignSystem.Typography.callout)
                        
                        Text("retry".localized)
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
                }
            }
            
            if showSetupInstructions {
                setupInstructionsView
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .primaryCard()
    }
    
    // MARK: - Error Analysis
    
    private var errorIcon: String {
        if let era5Error = error as? ERA5Error {
            switch era5Error {
            case .missingAPIKey:
                return "key.slash"
            case .unauthorized:
                return "person.crop.circle.badge.xmark"
            case .rateLimitExceeded:
                return "clock.badge.exclamationmark"
            case .dataParsingFailed:
                return "gearshape.2"
            default:
                return "wifi.slash"
            }
        }
        return "exclamationmark.triangle"
    }
    
    private var errorTitle: String {
        if let era5Error = error as? ERA5Error {
            switch era5Error {
            case .missingAPIKey:
                return "era5_api_key_missing_title".localized
            case .unauthorized:
                return "era5_unauthorized_title".localized
            case .rateLimitExceeded:
                return "era5_rate_limit_title".localized
            case .dataParsingFailed:
                return "era5_parsing_not_implemented_title".localized
            case .noDataAvailable:
                return "era5_no_data_title".localized
            default:
                return "era5_connection_error_title".localized
            }
        }
        return "snow_data_error_title".localized
    }
    
    private var errorMessage: String {
        if let era5Error = error as? ERA5Error {
            switch era5Error {
            case .missingAPIKey:
                return "era5_api_key_missing_message".localized
            case .unauthorized:
                return "era5_unauthorized_message".localized
            case .rateLimitExceeded:
                return "era5_rate_limit_message".localized
            case .dataParsingFailed:
                return "era5_parsing_not_implemented_message".localized
            case .noDataAvailable:
                return "era5_no_data_message".localized
            default:
                return "era5_connection_error_message".localized
            }
        }
        return "snow_data_error_message".localized
    }
    
    private var showRetryButton: Bool {
        if let era5Error = error as? ERA5Error {
            switch era5Error {
            case .missingAPIKey, .dataParsingFailed:
                return false // Keine Retry-Option bei Setup-Problemen
            default:
                return true
            }
        }
        return true
    }
    
    private var showSetupInstructions: Bool {
        if let era5Error = error as? ERA5Error {
            switch era5Error {
            case .missingAPIKey, .dataParsingFailed:
                return true
            default:
                return false
            }
        }
        return false
    }
    
    @ViewBuilder
    private var setupInstructionsView: some View {
        if let era5Error = error as? ERA5Error {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text("setup_instructions".localized)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                switch era5Error {
                case .missingAPIKey:
                    era5APIKeyInstructions
                case .dataParsingFailed:
                    netCDFSetupInstructions
                default:
                    EmptyView()
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.info.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous)
                    .stroke(DesignSystem.Colors.info.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var era5APIKeyInstructions: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("era5_setup_step_1".localized)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Text("era5_setup_step_2".localized)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Text("era5_setup_step_3".localized)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Button(action: {
                if let url = URL(string: "https://cds.climate.copernicus.eu/api-how-to") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text("era5_setup_guide".localized)
                        .font(DesignSystem.Typography.caption1)
                        .fontWeight(.medium)
                    
                    Image(systemName: "arrow.up.right.square")
                        .font(DesignSystem.Typography.caption2)
                }
                .foregroundColor(DesignSystem.Colors.primary)
            }
            .padding(.top, DesignSystem.Spacing.xs)
        }
    }
    
    private var netCDFSetupInstructions: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("netcdf_setup_message".localized)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Text("netcdf_setup_note".localized)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .italic()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SnowDataErrorView(error: ERA5Error.missingAPIKey) {
            print("Retry tapped")
        }
        
        SnowDataErrorView(error: ERA5Error.rateLimitExceeded) {
            print("Retry tapped")
        }
        
        SnowDataErrorView(error: ERA5Error.dataParsingFailed) {
            print("Retry tapped")
        }
    }
    .padding()
    .background(DesignSystem.Colors.background)
}