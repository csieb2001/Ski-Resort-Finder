import SwiftUI

struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localization = LocalizationService.shared
    
    @State private var showingConsentForm = false
    @State private var showingPrivacyPolicy = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "shield.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("privacy_protection".localized)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text("privacy_description".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        
                        Text("privacy_detailed_info".localized)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("ad_preferences".localized) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("personalized_ads".localized)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("personalized_ads_description".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer()
                            
                            Text(consentStatusText)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(consentStatusColor.opacity(0.2))
                                .foregroundColor(consentStatusColor)
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            // No consent form needed - app doesn't use ads
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                Text("manage_ad_preferences".localized)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("data_usage".localized) {
                    VStack(alignment: .leading, spacing: 12) {
                        PrivacyDataRow(
                            icon: "location.fill",
                            title: "location_data".localized,
                            description: "location_data_description".localized,
                            isUsed: true
                        )
                        
                        PrivacyDataRow(
                            icon: "person.fill",
                            title: "contact_data".localized,
                            description: "contact_data_description".localized,
                            isUsed: true
                        )
                        
                        PrivacyDataRow(
                            icon: "chart.bar.fill",
                            title: "usage_analytics".localized,
                            description: "usage_analytics_description".localized,
                            isUsed: true
                        )
                        
                        PrivacyDataRow(
                            icon: "ad.fill",
                            title: "advertising_data".localized,
                            description: "advertising_data_description".localized,
                            isUsed: true
                        )
                    }
                }
                
                Section("legal".localized) {
                    Button(action: {
                        showingPrivacyPolicy = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("privacy_policy".localized)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: {
                        openURL("https://policies.google.com/privacy")
                    }) {
                        HStack {
                            Image(systemName: "globe")
                            Text("google_privacy_policy".localized)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("privacy_settings".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close".localized) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
        }
    }
    
    private var consentStatusText: String {
        return "consent_not_required".localized
    }

    private var consentStatusColor: Color {
        return .blue
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

struct PrivacyDataRow: View {
    let icon: String
    let title: String
    let description: String
    let isUsed: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if isUsed {
                        Text("in_use".localized)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("privacy_policy_content".localized)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
            }
            .navigationTitle("privacy_policy".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#if DEBUG
struct PrivacySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacySettingsView()
    }
}
#endif