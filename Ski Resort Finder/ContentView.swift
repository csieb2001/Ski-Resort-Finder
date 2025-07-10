//
//  ContentView.swift
//  Ski Resort Finder
//
//  Created by Christopher Siebert on 10.07.25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SkiResortViewModel()
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @ObservedObject private var localization = LocalizationService.shared
    @ObservedObject private var accommodationDB = AccommodationDatabase.shared
    @ObservedObject private var emailService = AdvancedEmailService.shared
    @State private var showingResortPicker = false
    @State private var showingAccommodations = false
    @State private var showingAbout = false
    @State private var showingWeatherDetail = false
    @State private var showingResortDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Mountain background
                MountainBackgroundView()
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.lg) {
                    // Header Section
                    HeaderView(onAboutTap: { showingAbout = true })
                    
                    // Favorites Quick Access
                    if !favoritesManager.favoriteResortIDs.isEmpty {
                        FavoritesQuickAccessView(
                            favorites: favoritesManager.getFavoriteResorts(from: SkiResortDatabase.shared.allSkiResorts),
                            selectedResort: viewModel.selectedResort
                        ) { resort in
                            HapticFeedback.selection()
                            withAnimation(DesignSystem.Animation.medium) {
                                viewModel.selectedResort = resort
                            }
                        }
                    }
                    
                    // Resort Selection Card (now first)
                    ResortSelectionCard(
                        selectedResort: viewModel.selectedResort,
                        onTap: { 
                            HapticFeedback.impact(.light)
                            showingResortPicker = true 
                        }
                    )
                    
                    // Resort Info and Weather
                    if let resort = viewModel.selectedResort {
                        ModernResortInfoCard(resort: resort) {
                            showingResortDetail = true
                        }
                        .onAppear {
                            Task {
                                await viewModel.fetchWeatherData()
                            }
                        }
                        
                        // Search Accommodations Button (moved below resort details)
                        SearchButtonCard(
                            isEnabled: true,
                            onSearch: {
                                HapticFeedback.impact(.medium)
                                viewModel.searchAccommodations()
                                showingAccommodations = true
                            }
                        )
                        
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
                        
                    }
                    
                    // Top 3 Ski Resorts Card (moved to bottom below Current Weather)
                    Top3SkiResortsCard { selectedResort in
                        HapticFeedback.selection()
                        withAnimation(DesignSystem.Animation.medium) {
                            viewModel.selectedResort = selectedResort
                        }
                    }
                    
                    // Error Messages
                    if let errorMessage = viewModel.errorMessage {
                        ErrorMessageCard(message: errorMessage)
                    }
                    
                    // Database Progress (moved to bottom)
                    AccommodationDatabaseProgressView(
                        loadingStatus: accommodationDB.loadingStatus,
                        statistics: accommodationDB.statistics
                    )
                }
                .padding(.horizontal, DesignSystem.Layout.screenPadding)
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .sheet(isPresented: $showingResortPicker) {
                ResortPickerView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAccommodations) {
                AccommodationListView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingWeatherDetail) {
                if let weather = viewModel.weatherData {
                    WeatherDetailView(
                        weather: weather,
                        openMeteoData: viewModel.openMeteoData
                    )
                }
            }
            .sheet(isPresented: $showingResortDetail) {
                if let resort = viewModel.selectedResort {
                    ResortDetailView(resort: resort)
                }
            }
            }
        }
    }
}

#Preview {
    ContentView()
}
