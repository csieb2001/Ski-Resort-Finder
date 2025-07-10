import SwiftUI
import MapKit

struct ResortDetailView: View {
    let resort: SkiResort
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localization = LocalizationService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Resort Header
                    ResortHeaderCard(resort: resort)
                    
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
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // Inline interactive piste map
            ResortMapViewInteractive(
                resort: resort,
                mapType: .piste,
                onFullscreenTap: { showingFullScreenMap = true }
            )
            .frame(height: 200)
            .cornerRadius(12)
            .clipped()
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(15)
        .sheet(isPresented: $showingFullScreenMap) {
            ResortMapFullScreenView(
                resort: resort,
                mapType: .piste,
                dismiss: { showingFullScreenMap = false }
            )
        }
    }
}


// MARK: - Full Screen Map View

struct ResortMapFullScreenView: View {
    let resort: SkiResort
    let mapType: MapType
    let dismiss: () -> Void
    @ObservedObject private var localization = LocalizationService.shared
    
    enum MapType {
        case lift
        case piste
        
        var title: String {
            switch self {
            case .lift:
                return "lift_map".localized
            case .piste:
                return "trail_map".localized
            }
        }
        
        var webSearchQuery: String {
            switch self {
            case .lift:
                return "lift map"
            case .piste:
                return "piste map trail map"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Real Interactive Map
                ResortMapViewInteractive(
                    resort: resort,
                    mapType: mapType
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .cornerRadius(15)
                .padding()
            }
            .navigationTitle(mapType.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close".localized) { dismiss() }
                }
            }
        }
    }
}

// MARK: - Interactive Resort Map View

struct ResortMapViewInteractive: View {
    let resort: SkiResort
    let mapType: ResortMapFullScreenView.MapType
    let onFullscreenTap: (() -> Void)?
    @State private var region: MKCoordinateRegion
    @State private var skiLifts: [SkiLift] = []
    @State private var skiPistes: [SkiPiste] = []
    @State private var isLoadingLifts = false
    @State private var isLoadingPistes = false
    @State private var showMapTypeSelector = false
    @State private var selectedMapType: MKMapType = .standard
    @ObservedObject private var localization = LocalizationService.shared
    
    init(resort: SkiResort, mapType: ResortMapFullScreenView.MapType, onFullscreenTap: (() -> Void)? = nil) {
        self.resort = resort
        self.mapType = mapType
        self.onFullscreenTap = onFullscreenTap
        
        // Initialize map region around the resort
        self._region = State(initialValue: MKCoordinateRegion(
            center: resort.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    var body: some View {
        ZStack {
            // Interactive Map
            ResortMapViewContent(
                region: $region,
                mapType: selectedMapType,
                resort: resort,
                skiLifts: mapType == .lift ? skiLifts : [],
                skiPistes: mapType == .piste ? skiPistes : []
            )
            .ignoresSafeArea()
            
            // Map Controls Overlay
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        // Fullscreen Button (only show if callback is provided)
                        if onFullscreenTap != nil {
                            Button(action: {
                                onFullscreenTap?()
                            }) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                    .frame(width: 44, height: 44)
                                    .background(.regularMaterial)
                                    .clipShape(Circle())
                                    .shadow(color: DesignSystem.Shadow.medium.color, radius: DesignSystem.Shadow.medium.radius)
                            }
                        }
                        
                        // Map Type Selector
                        Button(action: {
                            showMapTypeSelector = true
                        }) {
                            Image(systemName: "map")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                .frame(width: 44, height: 44)
                                .background(.regularMaterial)
                                .clipShape(Circle())
                                .shadow(color: DesignSystem.Shadow.medium.color, radius: DesignSystem.Shadow.medium.radius)
                        }
                        
                        // Info Badge
                        HStack(spacing: 8) {
                            Image(systemName: mapType == .lift ? "cable.car" : "figure.skiing.downhill")
                                .font(.caption)
                            Text(mapType.title)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: DesignSystem.Shadow.small.color, radius: DesignSystem.Shadow.small.radius)
                    }
                }
                .padding(.trailing, 16)
                .padding(.top, 16)
                
                Spacer()
                
                // Loading Indicator
                if isLoadingLifts || isLoadingPistes {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(isLoadingLifts ? "Loading lifts..." : "Loading pistes...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.bottom, 20)
                }
            }
        }
        .confirmationDialog("choose_map_style".localized, isPresented: $showMapTypeSelector) {
            Button("Standard") { selectedMapType = .standard }
            Button("Satellite") { selectedMapType = .satellite }
            Button("Hybrid") { selectedMapType = .hybrid }
            Button("cancel".localized, role: .cancel) { }
        }
        .onAppear {
            loadMapData()
        }
    }
    
    private func loadMapData() {
        switch mapType {
        case .lift:
            loadSkiLifts()
        case .piste:
            loadSkiPistes()
        }
    }
    
    private func loadSkiLifts() {
        guard !isLoadingLifts else { return }
        isLoadingLifts = true
        
        Task {
            do {
                let lifts = try await fetchSkiLiftsFromOverpass(resort: resort)
                await MainActor.run {
                    self.skiLifts = lifts
                    self.isLoadingLifts = false
                    print("🚡 Loaded \(lifts.count) ski lifts for resort detail map")
                }
            } catch {
                print("🚡 Error loading ski lifts for resort detail: \(error)")
                await MainActor.run {
                    self.isLoadingLifts = false
                }
            }
        }
    }
    
    private func loadSkiPistes() {
        guard !isLoadingPistes else { return }
        isLoadingPistes = true
        
        Task {
            do {
                let pistes = try await OverpassService.shared.searchSkiPistes(
                    around: resort.coordinate,
                    radius: 8000 // 8km radius for detail view
                )
                await MainActor.run {
                    self.skiPistes = pistes
                    self.isLoadingPistes = false
                    print("🎿 Loaded \(pistes.count) ski pistes for resort detail map")
                }
            } catch {
                print("🎿 Error loading ski pistes for resort detail: \(error)")
                await MainActor.run {
                    self.isLoadingPistes = false
                }
            }
        }
    }
    
    // Fetch real ski lifts from Overpass API (same as MapView)
    private func fetchSkiLiftsFromOverpass(resort: SkiResort) async throws -> [SkiLift] {
        let lat = resort.coordinate.latitude
        let lon = resort.coordinate.longitude
        let radius = 8000 // 8km radius for detail view
        
        let query = """
        [out:json][timeout:25];
        (
          way["aerialway"]["aerialway"!="j-bar"]["aerialway"!="t-bar"]["aerialway"!="magic_carpet"](around:\(radius),\(lat),\(lon));
          relation["aerialway"]["aerialway"!="j-bar"]["aerialway"!="t-bar"]["aerialway"!="magic_carpet"](around:\(radius),\(lat),\(lon));
        );
        out geom;
        """
        
        guard let url = URL(string: "https://overpass-api.de/api/interpreter"),
              let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "data=\(encodedQuery)".data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let elements = jsonResponse["elements"] as? [[String: Any]] else {
            return []
        }
        
        return elements.compactMap { element in
            guard let id = element["id"] as? Int,
                  let tags = element["tags"] as? [String: String],
                  let aerialwayType = tags["aerialway"],
                  let name = tags["name"],
                  let geometry = element["geometry"] as? [[String: Any]],
                  geometry.count >= 2 else {
                return Optional.none
            }
            
            let coordinates = geometry.compactMap { geoPoint -> CLLocationCoordinate2D? in
                guard let lat = geoPoint["lat"] as? Double,
                      let lon = geoPoint["lon"] as? Double else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
            
            guard coordinates.count >= 2 else { return nil }
            
            return SkiLift(
                id: Int64(id),
                name: name,
                type: aerialwayType,
                bottomStation: coordinates.first!,
                topStation: coordinates.last!,
                coordinates: coordinates
            )
        }
    }
}

// MARK: - Resort Map View Content

struct ResortMapViewContent: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let mapType: MKMapType
    let resort: SkiResort
    let skiLifts: [SkiLift]
    let skiPistes: [SkiPiste]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = mapType
        mapView.setRegion(region, animated: false)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update map type
        if mapView.mapType != mapType {
            mapView.mapType = mapType
        }
        
        // Update region if needed
        if !mapView.region.isEqual(to: region) {
            mapView.setRegion(region, animated: true)
        }
        
        // Clear existing annotations and overlays
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        // Add resort marker
        let resortAnnotation = MKPointAnnotation()
        resortAnnotation.coordinate = resort.coordinate
        resortAnnotation.title = resort.name
        resortAnnotation.subtitle = "Resort"
        mapView.addAnnotation(resortAnnotation)
        
        // Add lift annotations
        for lift in skiLifts {
            let liftAnnotation = MKPointAnnotation()
            liftAnnotation.coordinate = lift.bottomStation
            liftAnnotation.title = lift.name
            liftAnnotation.subtitle = "Lift"
            mapView.addAnnotation(liftAnnotation)
            
            // Add lift line
            let liftLine = MKPolyline(coordinates: lift.coordinates, count: lift.coordinates.count)
            liftLine.title = "lift"
            mapView.addOverlay(liftLine)
        }
        
        // Add piste overlays
        for piste in skiPistes {
            if piste.coordinates.count >= 2 {
                let polyline = MKPolyline(coordinates: piste.coordinates, count: piste.coordinates.count)
                polyline.title = piste.name
                polyline.subtitle = piste.difficulty.rawValue
                mapView.addOverlay(polyline)
                
                // Piste names will be rendered as overlay labels instead of annotations
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        let parent: ResortMapViewContent
        
        init(_ parent: ResortMapViewContent) {
            self.parent = parent
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let pointAnnotation = annotation as? MKPointAnnotation else { return nil }
            
            // Handle piste name labels
            if pointAnnotation.subtitle == "piste_label".localized {
                let identifier = "PisteLabel"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                }
                
                annotationView?.annotation = annotation
                
                // Create a label view for the piste name
                let label = UILabel()
                label.text = pointAnnotation.title
                label.font = UIFont.boldSystemFont(ofSize: 12)
                label.textColor = UIColor.white
                label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
                label.textAlignment = .center
                label.layer.cornerRadius = 4
                label.clipsToBounds = true
                label.sizeToFit()
                
                // Add padding
                label.frame = CGRect(
                    x: 0, y: 0,
                    width: label.frame.width + 8,
                    height: label.frame.height + 4
                )
                
                annotationView?.frame = label.frame
                annotationView?.addSubview(label)
                annotationView?.canShowCallout = false
                
                return annotationView
            }
            
            // Handle regular annotations
            let identifier = pointAnnotation.subtitle ?? "default"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            if let markerView = annotationView as? MKMarkerAnnotationView {
                switch pointAnnotation.subtitle {
                case "Resort":
                    markerView.markerTintColor = .systemBlue
                    markerView.glyphImage = UIImage(systemName: "mountain.2.fill")
                case "Lift":
                    markerView.markerTintColor = .systemOrange
                    markerView.glyphImage = UIImage(systemName: "cable.car")
                default:
                    markerView.markerTintColor = .systemGray
                }
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                if polyline.title == "lift" {
                    // Lift lines - use standard renderer
                    let renderer = MKPolylineRenderer(polyline: polyline)
                    renderer.strokeColor = UIColor.systemOrange
                    renderer.lineWidth = 3.0
                    renderer.alpha = 0.8
                    return renderer
                } else {
                    // Piste lines - use custom renderer with labels
                    let renderer = PistePolylineRenderer(polyline: polyline)
                    
                    if let difficultyString = polyline.subtitle {
                        let difficulty = PisteDifficulty(rawValue: difficultyString) ?? .easy
                        renderer.strokeColor = difficulty.mapColor
                    } else {
                        renderer.strokeColor = UIColor.systemBlue
                    }
                    renderer.lineWidth = 4.0
                    renderer.alpha = 0.8
                    return renderer
                }
            }
            
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

#Preview {
    let sampleSlopes = SlopeBreakdown(
        greenSlopes: 15,
        blueSlopes: 45,
        redSlopes: 35,
        blackSlopes: 12
    )
    
    
    let sampleResort = SkiResort(
        name: "St. Anton am Arlberg",
        country: "Österreich",
        region: "Tirol",
        totalSlopes: 107,
        maxElevation: 2811,
        minElevation: 1304,
        coordinate: CLLocationCoordinate2D(latitude: 47.1296, longitude: 10.2686),
        liftCount: 24,
        slopeBreakdown: sampleSlopes
    )
    
    ResortDetailView(resort: sampleResort)
}