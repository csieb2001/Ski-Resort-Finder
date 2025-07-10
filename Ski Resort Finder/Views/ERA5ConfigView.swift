import SwiftUI

struct ERA5ConfigView: View {
    @State private var apiKeyInput = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                
                // Header
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "cloud.snow.fill")
                        .font(.system(size: 60))
                        .foregroundColor(DesignSystem.Colors.snowfall)
                    
                    Text("ERA5 Configuration")
                        .font(DesignSystem.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Configure your free ERA5 API key for real historical snow data")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(DesignSystem.Spacing.lg)
                
                // Current Status
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Current Status")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    HStack {
                        Image(systemName: statusIcon)
                            .foregroundColor(statusColor)
                        Text(ERA5Config.debugStatus)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(statusColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                // API Key Input
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("API Key")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        SecureField("12345:abcd-1234-efgh-5678", text: $apiKeyInput)
                            .font(DesignSystem.Typography.body)
                            .padding(DesignSystem.Spacing.md)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous)
                                    .stroke(DesignSystem.Colors.separator, lineWidth: 1)
                            )
                        
                        Text("Format: UID:API-Key (e.g., 12345:abcd-1234-efgh-5678)")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                // Action Buttons
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Save Button
                    Button(action: saveAPIKey) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save API Key")
                        }
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
                    }
                    .disabled(apiKeyInput.isEmpty)
                    
                    // Delete Button
                    if ERA5Config.isConfigured {
                        Button(action: deleteAPIKey) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete API Key")
                            }
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.error)
                            .frame(maxWidth: .infinity)
                            .padding(DesignSystem.Spacing.md)
                            .background(DesignSystem.Colors.error.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous)
                                    .stroke(DesignSystem.Colors.error, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                // Instructions
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("How to get your free ERA5 API Key:")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        instructionStep("1.", "Go to cds.climate.copernicus.eu")
                        instructionStep("2.", "Create a free account")
                        instructionStep("3.", "Go to 'Your Account' → 'API Key'")
                        instructionStep("4.", "Copy the UID and API Key")
                        instructionStep("5.", "Paste here in format: UID:API-Key")
                    }
                    
                    Button(action: openERA5Website) {
                        HStack {
                            Text("Open ERA5 Website")
                                .font(DesignSystem.Typography.callout)
                                .fontWeight(.medium)
                            Image(systemName: "arrow.up.right.square")
                                .font(DesignSystem.Typography.callout)
                        }
                        .foregroundColor(DesignSystem.Colors.primary)
                    }
                    .padding(.top, DesignSystem.Spacing.sm)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.info.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: DesignSystem.CornerRadius.continuous))
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                Spacer()
            }
            .navigationTitle("ERA5 Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss view
                    }
                }
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusIcon: String {
        if ERA5Config.isConfigured && ERA5Config.isValidFormat {
            return "checkmark.circle.fill"
        } else if ERA5Config.isConfigured {
            return "exclamationmark.triangle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        if ERA5Config.isConfigured && ERA5Config.isValidFormat {
            return DesignSystem.Colors.success
        } else if ERA5Config.isConfigured {
            return DesignSystem.Colors.warning
        } else {
            return DesignSystem.Colors.error
        }
    }
    
    // MARK: - Actions
    
    private func saveAPIKey() {
        guard !apiKeyInput.isEmpty else { return }
        
        if ERA5Config.saveAPIKey(apiKeyInput) {
            alertTitle = "Success"
            alertMessage = "ERA5 API Key has been saved securely."
            apiKeyInput = ""
        } else {
            alertTitle = "Error"
            alertMessage = "Failed to save API Key. Please try again."
        }
        showingAlert = true
    }
    
    private func deleteAPIKey() {
        if ERA5Config.deleteAPIKey() {
            alertTitle = "Deleted"
            alertMessage = "ERA5 API Key has been deleted."
        } else {
            alertTitle = "Error"
            alertMessage = "Failed to delete API Key."
        }
        showingAlert = true
    }
    
    private func openERA5Website() {
        if let url = URL(string: "https://cds.climate.copernicus.eu/") {
            UIApplication.shared.open(url)
        }
    }
    
    private func instructionStep(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            Text(number)
                .font(DesignSystem.Typography.callout)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 20, alignment: .leading)
            
            Text(text)
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.primaryText)
        }
    }
}

#Preview {
    ERA5ConfigView()
}