import SwiftUI

#if DEBUG
struct CacheManagementView: View {
    @State private var cacheStats: (entries: Int, totalSizeMB: Double, oldestEntry: Date?, newestEntry: Date?) = (0, 0.0, nil, nil)
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Cache Statistiken") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Einträge:")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(cacheStats.entries)")
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("Geschätzte Größe:")
                                .fontWeight(.medium)
                            Spacer()
                            Text(String(format: "%.2f MB", cacheStats.totalSizeMB))
                                .foregroundColor(.blue)
                        }
                        
                        if let oldest = cacheStats.oldestEntry {
                            HStack {
                                Text("Ältester Eintrag:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(formatDate(oldest))
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        
                        if let newest = cacheStats.newestEntry {
                            HStack {
                                Text("Neuester Eintrag:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(formatDate(newest))
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Cache Verwaltung") {
                    Button(action: {
                        SnowDataCache.shared.clearOldCache()
                        refreshStats()
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.orange)
                            Text("Veraltete Einträge löschen")
                        }
                    }
                    
                    Button(action: {
                        showingClearAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Gesamten Cache löschen")
                        }
                    }
                }
                
                Section("Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Der Schneedaten-Cache speichert historische Wetterdaten für 24 Stunden zwischen. Dies reduziert API-Aufrufe und verbessert die Performance.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Cache-Speicherort: Documents/SnowDataCache/")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Cache Verwaltung")
            .onAppear {
                refreshStats()
            }
            .alert("Cache löschen", isPresented: $showingClearAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Löschen", role: .destructive) {
                    SnowDataCache.shared.clearAllCache()
                    refreshStats()
                }
            } message: {
                Text("Möchten Sie wirklich alle gecachten Schneedaten löschen? Diese werden beim nächsten Laden der Skigebiete neu von der API abgerufen.")
            }
        }
    }
    
    private func refreshStats() {
        cacheStats = SnowDataCache.shared.getCacheStats()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
}

#if DEBUG
struct CacheManagementView_Previews: PreviewProvider {
    static var previews: some View {
        CacheManagementView()
    }
}
#endif
#endif