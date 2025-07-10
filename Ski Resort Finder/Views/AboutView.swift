import SwiftUI
import Foundation

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingDebugScreen = false
    @State private var showingPinEntry = false
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // App Info
                    VStack(spacing: 15) {
                        Text("ski_resort_finder".localized)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("version".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    
                    Divider()
                    
                    // Features
                    VStack(alignment: .leading, spacing: 15) {
                        Text("features".localized)
                            .font(.headline)
                        
                        FeatureRow(icon: "paperplane.fill", title: "multiple_booking_requests".localized, description: "send_multiple_requests".localized)
                        FeatureRow(icon: "envelope.fill", title: "direct_contact".localized, description: "automated_accommodation_contact".localized)
                        FeatureRow(icon: "mountain.2.fill", title: "worldwide_resorts".localized, description: "worldwide_countries".localized)
                        FeatureRow(icon: "building.2.fill", title: "accommodations_worldwide".localized, description: "overpass_api_accommodations".localized)
                        FeatureRow(icon: "info.circle.fill", title: "detailed_resort_info".localized, description: "lifts_slopes_info".localized)
                        FeatureRow(icon: "cloud.snow.fill", title: "live_weather".localized, description: "openweathermap_integration".localized)
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "detailed_snow_statistics".localized, description: "era5_historical_data".localized)
                        FeatureRow(icon: "globe", title: "multi_language_support".localized, description: "localized_8_languages".localized)
                        FeatureRow(icon: "star.fill", title: "favorites".localized, description: "quick_access_resorts".localized)
                        FeatureRow(icon: "map.fill", title: "map_view".localized, description: "hotels_lifts_visualized".localized)
                    }
                    .padding()
                    
                    Divider()
                    
                    // Developer Info
                    VStack(alignment: .leading, spacing: 15) {
                        Text("developed_by".localized)
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Christopher Siebert")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            
                            Text("created_for_ski_enthusiasts".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    
                    Divider()
                    
                    // APIs
                    VStack(alignment: .leading, spacing: 15) {
                        Text("data_sources".localized)
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• OpenStreetMap (Overpass API - Hotels)")
                            Text("• Website-Screenshots für Hotelbilder")
                            Text("• Open-Meteo Wetter API")
                            Text("• ERA5 Climate Data Store (Historische Schneedaten)")
                            Text("• Skigebiet-Datenbank (100+ Gebiete)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Debug Button
                    Button(action: { showingPinEntry = true }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("debug_system_info".localized)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding()
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("about_app".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close".localized) { dismiss() }
                }
            }
            .sheet(isPresented: $showingPinEntry) {
                PinEntryView {
                    showingDebugScreen = true
                }
            }
            .sheet(isPresented: $showingDebugScreen) {
                DebugView()
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}