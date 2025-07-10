//
//  Ski_Resort_FinderApp.swift
//  Ski Resort Finder
//
//  Created by Christopher Siebert on 10.07.25.
//

import SwiftUI
import MapKit

@main
struct Ski_Resort_FinderApp: App {
    @StateObject private var localizationService = LocalizationService.shared
    @StateObject private var accommodationDatabase = AccommodationDatabase.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.localization, localizationService)
                .preferredColorScheme(.dark) // Force dark mode for glassmorphism theme
                .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
                    // Force UI update when language changes
                    DispatchQueue.main.async {
                        // Trigger UI refresh
                    }
                }
                .onAppear {
                    // Starte AccommodationDatabase beim App-Start
                    print("🚀 Starting AccommodationDatabase initialization")
                }
        }
    }
}
