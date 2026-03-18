import SwiftUI
import MapKit

struct ResortDetailView: View {
    let resort: SkiResort
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localization = LocalizationService.shared
    @StateObject private var viewModel = SkiResortViewModel()
    @State private var showingWeatherDetail = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Resort Header
                    ResortHeaderCard(resort: resort)
                    
                    // Current Weather
                    if let weather = viewModel.weatherData {
                        WeatherCard(
                            weather: weather,
                            openMeteoData: viewModel.openMeteoData,
                            onTap: {
                                HapticFeedback.impact(.light)
                                showingWeatherDetail = true
                            }
                        )
                    }
                    
                    // Lift Information - Only show if data available
                    if resort.liftCount != nil {
                        LiftInformationCard(resort: resort)
                    }
                    
                    // Slope Breakdown - Only show if data available
                    if resort.slopeBreakdown != nil {
                        SlopeBreakdownCard(slopeBreakdown: resort.slopeBreakdown!)
                    }
                    
                    // Resort Maps Section
                    ResortMapsCard(resort: resort)
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("resort_details".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close".localized) { dismiss() }
                }
            }
            .sheet(isPresented: $showingWeatherDetail) {
                if let weather = viewModel.weatherData {
                    WeatherDetailView(
                        weather: weather,
                        openMeteoData: viewModel.openMeteoData
                    )
                }
            }
            .onAppear {
                viewModel.selectedResort = resort
                Task {
                    await viewModel.fetchWeatherData()
                }
            }
        }
    }
}

// MARK: - Resort Header Card

struct ResortHeaderCard: View {
    let resort: SkiResort
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(resort.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("\(resort.country.localizedCountryName()), \(resort.region)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Location Icon
                VStack {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                }
            }
            
            // Elevation Range
            HStack {
                VStack(alignment: .leading) {
                    Text("elevation_range".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(resort.minElevation) - \(resort.maxElevation) m")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("total_slopes".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(resort.totalSlopes) km")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(15)
    }
}

// MARK: - Lift Information Card

struct LiftInformationCard: View {
    let resort: SkiResort
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "cable.car")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("lift_information".localized)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("total_lifts".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(resort.liftCount ?? 0)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("lift_capacity".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("estimated_capacity".localized(with: (resort.liftCount ?? 0) * 2500))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(15)
    }
}

// MARK: - Slope Breakdown Card

struct SlopeBreakdownCard: View {
    let slopeBreakdown: SlopeBreakdown
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "figure.skiing.downhill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("slope_breakdown".localized)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                
                // Green Slopes (Beginner)
                SlopeStatCard(
                    icon: "circle.fill",
                    title: "beginner_slopes".localized,
                    count: slopeBreakdown.greenSlopes,
                    color: .green
                )
                
                // Blue Slopes (Easy/Intermediate)
                SlopeStatCard(
                    icon: "circle.fill",
                    title: "easy_slopes".localized,
                    count: slopeBreakdown.blueSlopes,
                    color: .blue
                )
                
                // Red Slopes (Intermediate/Advanced)
                SlopeStatCard(
                    icon: "circle.fill",
                    title: "intermediate_slopes".localized,
                    count: slopeBreakdown.redSlopes,
                    color: .red
                )
                
                // Black Slopes (Expert/Difficult)
                SlopeStatCard(
                    icon: "circle.fill",
                    title: "expert_slopes".localized,
                    count: slopeBreakdown.blackSlopes,
                    color: .black
                )
            }
            
            // Total Slopes Summary
            HStack {
                Text("total_slopes_summary".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(slopeBreakdown.totalSlopes) km")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(15)
    }
}


// MARK: - Helper Components

struct SlopeStatCard: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Resort Maps Card

struct ResortMapsCard: View {
    let resort: SkiResort
    @ObservedObject private var localization = LocalizationService.shared
    @State private var showingFullScreenMap = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "figure.skiing.downhill")
                    .foregroundColor(.red)
                    .font(.title2)
                Text("trail_map".localized)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                
                // Fullscreen button
                Button(action: { showingFullScreenMap = true }) {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // Vereinheitlichte MapView Preview (Resort-only)
            ZStack {
                // Preview der besseren MapView
                MapView_ResortPreview(resort: resort)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .clipped()
                    .disabled(true) // Verhindert Interaktion im Preview
                
                // Vollbild-Button Overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingFullScreenMap = true }) {
                            Image(systemName: "plus.magnifyingglass")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 8)
                        .padding(.bottom, 8)
                    }
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(15)
        .sheet(isPresented: $showingFullScreenMap) {
            // Verwende die bessere MapView für Vollbild
            MapView(resort: resort)
        }
    }
}


