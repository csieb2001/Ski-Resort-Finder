import SwiftUI
import Foundation
import MapKit

struct MapView: View {
    let resort: SkiResort
    let accommodations: [Accommodation]
    @Environment(\.dismiss) var dismiss
    @State private var region: MKCoordinateRegion
    @State private var selectedAccommodation: Accommodation?
    @State private var mapType: MKMapType = .standard
    @State private var showLifts: Bool = true
    @State private var showMapTypeSelector: Bool = false
    @State private var skiLifts: [SkiLift] = []
    @State private var isLoadingLifts: Bool = false
    @State private var skiPistes: [SkiPiste] = []
    @State private var isLoadingPistes: Bool = false
    @State private var showPistes: Bool = true
    @State private var showPisteNames: Bool = true
    @ObservedObject private var localization = LocalizationService.shared
    
    init(resort: SkiResort, accommodations: [Accommodation]) {
        self.resort = resort
        self.accommodations = accommodations
        
        // Initialisiere die Kartenregion um das Skigebiet
        self._region = State(initialValue: MKCoordinateRegion(
            center: resort.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ))
        
        // Keine Demo-Lifts mehr - nur echte OpenStreetMap Daten verwenden
        self._skiLifts = State(initialValue: [])
        self._skiPistes = State(initialValue: [])
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                mapView
                mapControlsOverlay
                accommodationBottomSheet
            }
            .navigationTitle("map".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close".localized) { 
                        dismiss() 
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .confirmationDialog("map_type".localized, isPresented: $showMapTypeSelector) {
                Button("standard_map".localized) {
                    mapType = .standard
                }
                Button("satellite_map".localized) {
                    mapType = .satellite
                }
                Button("hybrid_map".localized) {
                    mapType = .hybrid
                }
                Button("cancel".localized, role: .cancel) { }
            } message: {
                Text("choose_map_style".localized)
            }
            .onAppear {
                print("🚡 MapView appeared, loading real lift data from OpenStreetMap")
                loadSkiLifts()
                print("🎿 MapView appeared, loading real piste data from OpenStreetMap")
                loadSkiPistes()
            }
        }
    }
    
    // MARK: - View Components
    
    private var mapView: some View {
        CustomMapViewWithPistes(
            region: $region,
            mapType: mapType,
            annotations: mapAnnotations,
            skiPistes: showPistes ? skiPistes : [],
            onAnnotationTap: { annotation in
                if let accommodation = annotation.accommodation {
                    selectedAccommodation = accommodation
                }
            }
        )
        .ignoresSafeArea()
    }
    
    private var mapControlsOverlay: some View {
        VStack {
            HStack {
                Spacer()
                VStack(spacing: DesignSystem.Spacing.sm) {
                    mapTypeButton
                    skiLiftsToggle
                    skiPistesToggle
                    pisteNamesToggle
                    centerMapButton
                    zoomInButton
                    zoomOutButton
                }
                .padding(DesignSystem.Spacing.md)
            }
            Spacer()
        }
    }
    
    private var mapTypeButton: some View {
        Button(action: {
            showMapTypeSelector = true
        }) {
            Image(systemName: "map")
                .font(.callout)
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(.regularMaterial)
                .clipShape(Circle())
                .shadow(color: DesignSystem.Shadow.medium.color, radius: DesignSystem.Shadow.medium.radius)
        }
    }
    
    private var skiLiftsToggle: some View {
        Button(action: {
            withAnimation(DesignSystem.Animation.medium) {
                showLifts.toggle()
            }
            if showLifts && skiLifts.isEmpty {
                loadSkiLifts()
            }
        }) {
            Image(systemName: showLifts ? "cable.car.fill" : "cable.car")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(showLifts ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText)
                .frame(width: 44, height: 44)
                .background(.regularMaterial)
                .clipShape(Circle())
                .shadow(color: DesignSystem.Shadow.medium.color, radius: DesignSystem.Shadow.medium.radius)
        }
    }
    
    private var skiPistesToggle: some View {
        Button(action: {
            withAnimation(DesignSystem.Animation.medium) {
                showPistes.toggle()
            }
            if showPistes && skiPistes.isEmpty {
                loadSkiPistes()
            }
        }) {
            ZStack {
                if isLoadingPistes {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.accent))
                } else {
                    Image(systemName: "figure.skiing.downhill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(showPistes ? DesignSystem.Colors.accent : DesignSystem.Colors.secondaryText)
                }
            }
            .frame(width: 44, height: 44)
            .background(showPistes ? DesignSystem.Colors.accent.opacity(0.1) : Color.clear)
            .background(.regularMaterial)
            .clipShape(Circle())
            .shadow(color: DesignSystem.Shadow.medium.color, radius: DesignSystem.Shadow.medium.radius)
            .overlay(
                Circle()
                    .stroke(showPistes ? DesignSystem.Colors.accent : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private var centerMapButton: some View {
        Button(action: {
            withAnimation(DesignSystem.Animation.medium) {
                region = MKCoordinateRegion(
                    center: resort.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
            }
        }) {
            Image(systemName: "location.fill")
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 44, height: 44)
                .background(DesignSystem.Colors.background)
                .clipShape(Circle())
                .shadow(color: DesignSystem.Shadow.medium.color, radius: DesignSystem.Shadow.medium.radius)
        }
    }
    
    private var zoomInButton: some View {
        Button(action: {
            withAnimation(DesignSystem.Animation.medium) {
                let newSpan = MKCoordinateSpan(
                    latitudeDelta: max(region.span.latitudeDelta * 0.5, 0.001),
                    longitudeDelta: max(region.span.longitudeDelta * 0.5, 0.001)
                )
                region = MKCoordinateRegion(center: region.center, span: newSpan)
            }
        }) {
            Image(systemName: "plus")
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .frame(width: 44, height: 44)
                .background(DesignSystem.Colors.background)
                .clipShape(Circle())
                .shadow(color: DesignSystem.Shadow.medium.color, radius: DesignSystem.Shadow.medium.radius)
        }
    }
    
    private var pisteNamesToggle: some View {
        Button(action: {
            withAnimation(DesignSystem.Animation.medium) {
                showPisteNames.toggle()
                PistePolylineRenderer.showPisteNames = showPisteNames
                // Force refresh of map overlays
                refreshMapOverlays()
            }
        }) {
            Image(systemName: showPisteNames ? "textformat" : "textformat.alt")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(showPisteNames ? DesignSystem.Colors.accent : DesignSystem.Colors.secondaryText)
                .frame(width: 44, height: 44)
                .background(showPisteNames ? DesignSystem.Colors.accent.opacity(0.1) : Color.clear)
                .background(.regularMaterial)
                .clipShape(Circle())
                .shadow(color: DesignSystem.Shadow.medium.color, radius: DesignSystem.Shadow.medium.radius)
                .overlay(
                    Circle()
                        .stroke(showPisteNames ? DesignSystem.Colors.accent : Color.clear, lineWidth: 2)
                )
        }
    }
    
    // MARK: - Helper Methods
    
    private func refreshMapOverlays() {
        // This forces the map to re-render all overlays by triggering an update
        // We do this by temporarily changing the region by a tiny amount and then back
        let currentRegion = region
        let minimalChange = 0.0000001 // Extremely small change that won't be visible
        
        // Temporarily modify the region to trigger a map update
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: currentRegion.center.latitude + minimalChange,
                longitude: currentRegion.center.longitude + minimalChange
            ),
            span: currentRegion.span
        )
        
        // Immediately restore the original region
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.region = currentRegion
        }
    }
    
    private var zoomOutButton: some View {
        Button(action: {
            withAnimation(DesignSystem.Animation.medium) {
                let newSpan = MKCoordinateSpan(
                    latitudeDelta: min(region.span.latitudeDelta * 2.0, 1.0),
                    longitudeDelta: min(region.span.longitudeDelta * 2.0, 1.0)
                )
                region = MKCoordinateRegion(center: region.center, span: newSpan)
            }
        }) {
            Image(systemName: "minus")
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .frame(width: 44, height: 44)
                .background(DesignSystem.Colors.background)
                .clipShape(Circle())
                .shadow(color: DesignSystem.Shadow.medium.color, radius: DesignSystem.Shadow.medium.radius)
        }
    }
    
    @ViewBuilder
    private var accommodationBottomSheet: some View {
        if let accommodation = selectedAccommodation {
            VStack {
                Spacer()
                AccommodationMapCard(accommodation: accommodation) {
                    selectedAccommodation = nil
                }
                .padding()
                .transition(.move(edge: .bottom))
            }
            .animation(.easeInOut, value: selectedAccommodation)
        }
    }
    
    var mapAnnotations: [MapAnnotationItem] {
        var annotations: [MapAnnotationItem] = []
        
        print("🚡 Creating annotations - showLifts: \(showLifts), skiLifts count: \(skiLifts.count)")
        
        // Skigebiet-Marker
        annotations.append(MapAnnotationItem(
            id: "resort",
            coordinate: resort.coordinate,
            type: .resort,
            title: resort.name,
            accommodation: nil
        ))
        
        // Unterkunfts-Marker - ONLY REAL COORDINATES
        for accommodation in accommodations.prefix(20) { // Limitiere auf 20 für Performance
            // Verwende nur echte Google Places Koordinaten - keine Fake-Daten!
            if let realCoordinate = accommodation.coordinate {
                annotations.append(MapAnnotationItem(
                    id: accommodation.id.uuidString,
                    coordinate: realCoordinate,
                    type: .accommodation,
                    title: accommodation.name,
                    accommodation: accommodation
                ))
                print("✅ Using real coordinates for \(accommodation.name): \(realCoordinate.latitude), \(realCoordinate.longitude)")
            } else {
                print("❌ No real coordinates available for \(accommodation.name) - skipping marker (NO FAKE DATA policy)")
            }
        }
        
        // ECHTE LIFT-MARKER - nur wenn verfügbar und showLifts aktiv
        print("🚡 Adding REAL lift markers - showLifts: \(showLifts), lifts available: \(skiLifts.count)")
        
        if showLifts {
            for lift in skiLifts {
                // Verwende nur echte Lift-Koordinaten von OpenStreetMap
                annotations.append(MapAnnotationItem(
                    id: "lift_\(lift.id)",
                    coordinate: lift.bottomStation, // Echte GPS-Koordinaten der Talstation
                    type: .lift,
                    title: lift.name,
                    accommodation: nil
                ))
                print("🚡 Added REAL lift marker: \(lift.name) at \(lift.bottomStation.latitude), \(lift.bottomStation.longitude)")
            }
        } else {
            print("🚡 Lifts disabled - no lift markers added")
        }
        
        print("🚡 Total annotations: \(annotations.count), lift annotations: \(annotations.filter { $0.type == .lift }.count)")
        
        return annotations
    }
    
    // Note: Map style changes require using MKMapView UIViewRepresentable for full control
    
    // Load Ski Lifts from OpenStreetMap
    private func loadSkiLifts() {
        guard !isLoadingLifts else { return }
        isLoadingLifts = true
        
        Task {
            do {
                let lifts = try await fetchSkiLiftsFromOverpass(resort: resort)
                await MainActor.run {
                    // Nur echte Lifts verwenden - keine Demo-Lifts als Fallback!
                    self.skiLifts = lifts
                    self.isLoadingLifts = false
                    if lifts.isEmpty {
                        print("🚡 No real lifts found in OpenStreetMap for \(resort.name) - no lift markers will be shown")
                    } else {
                        print("🚡 Loaded \(lifts.count) REAL ski lifts from OpenStreetMap")
                    }
                }
            } catch {
                print("🚡 Error loading ski lifts: \(error)")
                await MainActor.run {
                    self.isLoadingLifts = false
                    // NO FAKE DATA - wenn OpenStreetMap fehlschlägt, keine Lift-Marker anzeigen
                    self.skiLifts = []
                    print("🚡 OpenStreetMap API failed - no lift markers will be shown (NO FAKE DATA policy)")
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
                    radius: 10000 // 10km Radius für Pisten
                )
                await MainActor.run {
                    self.skiPistes = pistes
                    self.isLoadingPistes = false
                    if pistes.isEmpty {
                        print("🎿 No ski pistes found in OpenStreetMap for \(resort.name)")
                    } else {
                        print("🎿 Loaded \(pistes.count) ski pistes from OpenStreetMap")
                    }
                }
            } catch {
                print("🎿 Error loading ski pistes: \(error)")
                await MainActor.run {
                    self.isLoadingPistes = false
                }
            }
        }
    }
    
    // Fetch real ski lifts from Overpass API
    private func fetchSkiLiftsFromOverpass(resort: SkiResort) async throws -> [SkiLift] {
        let lat = resort.coordinate.latitude
        let lon = resort.coordinate.longitude
        let radius = 5000 // 5km radius
        
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
        let response = try JSONDecoder().decode(OverpassResponse.self, from: data)
        
        return response.elements.compactMap { element in
            guard let geometry = element.geometry, 
                  geometry.count >= 2,
                  let name = element.tags?["name"] else { return nil }
            
            return SkiLift(
                id: Int64(element.id),
                name: name,
                type: element.aerialway ?? "chairlift",
                bottomStation: CLLocationCoordinate2D(
                    latitude: geometry.first!.lat,
                    longitude: geometry.first!.lon
                ),
                topStation: CLLocationCoordinate2D(
                    latitude: geometry.last!.lat,
                    longitude: geometry.last!.lon
                ),
                coordinates: geometry.map { 
                    CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon)
                }
            )
        }
    }
    
    // REMOVED: Demo lift generation methods - NO FAKE DATA policy
    // Only real OpenStreetMap lift data is used now
    
    private func findClosestAnnotation(to location: CGPoint) -> MapAnnotationItem? {
        // Simple implementation - return first accommodation for demo
        return mapAnnotations.first { $0.accommodation != nil }
    }
}

// MARK: - Data Structures for Ski Lifts

struct SkiLift: Identifiable, Codable {
    let id: Int64
    let name: String
    let type: String
    let bottomStation: CLLocationCoordinate2D
    let topStation: CLLocationCoordinate2D
    let coordinates: [CLLocationCoordinate2D]
}

extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}

// MARK: - Custom Map View with Style Support

struct CustomMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let mapType: MKMapType
    let annotations: [MapAnnotationItem]
    let onAnnotationTap: (MapAnnotationItem) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = mapType
        mapView.setRegion(region, animated: false)
        
        // Clear any existing annotation views cache
        mapView.removeAnnotations(mapView.annotations)
        
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
        
        // Update annotations - force refresh every time
        mapView.removeAnnotations(mapView.annotations)
        
        let newAnnotations = annotations.map { MapPointAnnotation(mapAnnotationItem: $0) }
        print("🚡 Adding \(newAnnotations.count) total annotations to map")
        print("🚡 Lift annotations: \(newAnnotations.filter { $0.item.type == .lift }.count)")
        
        mapView.addAnnotations(newAnnotations)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        let parent: CustomMapView
        
        init(_ parent: CustomMapView) {
            self.parent = parent
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            parent.region = mapView.region
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let mapAnnotation = annotation as? MapPointAnnotation else { return nil }
            
            // Use different identifiers to avoid caching issues
            let identifier = "Pin_\(mapAnnotation.item.type)_\(Date().timeIntervalSince1970)"
            
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView.canShowCallout = true
            
            // Create custom image
            let image = createStyledMarker(for: mapAnnotation.item.type)
            
            annotationView.image = image
            annotationView.frame = CGRect(origin: .zero, size: image.size)
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let mapAnnotation = view.annotation as? MapPointAnnotation else { return }
            parent.onAnnotationTap(mapAnnotation.item)
        }
        
        private func createStyledMarker(for type: AnnotationType) -> UIImage {
            // Different sizes for different marker types
            let size: CGSize = {
                switch type {
                case .resort:
                    return CGSize(width: 40, height: 40) // Largest for resort
                case .accommodation:
                    return CGSize(width: 36, height: 36) // Medium for hotels
                case .lift:
                    return CGSize(width: 38, height: 38) // Larger for better visibility
                }
            }()
            
            let renderer = UIGraphicsImageRenderer(size: size)
            
            return renderer.image { context in
                let rect = CGRect(origin: .zero, size: size)
                
                // Handle lift markers - simple orange circle with white icon
                if type == .lift {
                    // Draw simple orange circle
                    UIColor.systemOrange.setFill()
                    context.cgContext.fillEllipse(in: rect)
                    
                    // Draw white border for visibility
                    context.cgContext.setStrokeColor(UIColor.white.cgColor)
                    context.cgContext.setLineWidth(2)
                    context.cgContext.strokeEllipse(in: rect)
                    
                    // Draw cable car icon with simple approach
                    let iconSize: CGFloat = 20
                    let iconConfig = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .bold)
                    if let icon = UIImage(systemName: "cable.car.fill", withConfiguration: iconConfig) {
                        // Create white-colored version of the icon using tintColor
                        let whiteIcon = icon.withTintColor(.white, renderingMode: .alwaysOriginal)
                        
                        let iconRect = CGRect(
                            x: (size.width - iconSize) / 2,
                            y: (size.height - iconSize) / 2,
                            width: iconSize,
                            height: iconSize
                        )
                        
                        // Draw the white icon directly
                        whiteIcon.draw(in: iconRect)
                    } else {
                        // Fallback: draw lift emoji
                        let text = "🚡"
                        let attributes: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                            .foregroundColor: UIColor.white
                        ]
                        
                        let textSize = text.size(withAttributes: attributes)
                        let textRect = CGRect(
                            x: (size.width - textSize.width) / 2,
                            y: (size.height - textSize.height) / 2,
                            width: textSize.width,
                            height: textSize.height
                        )
                        
                        text.draw(in: textRect, withAttributes: attributes)
                    }
                    
                    return
                }
                
                // For resort and accommodation markers, keep circle design
                let borderWidth: CGFloat = 2
                let innerRect = CGRect(x: borderWidth, y: borderWidth, width: size.width - (borderWidth * 2), height: size.height - (borderWidth * 2))
                
                // Define colors and icons based on type
                let (backgroundColor, borderColor, iconName, iconColor): (UIColor, UIColor, String, UIColor) = {
                    switch type {
                    case .resort:
                        return (.systemRed.withAlphaComponent(0.9), .systemRed, "mountain.2.fill", .white)
                    case .accommodation:
                        return (.systemBlue.withAlphaComponent(0.85), .systemBlue, "building.2.fill", .white)
                    case .lift:
                        return (.clear, .clear, "", .clear) // Not used for lifts
                    }
                }()
                
                // Draw enhanced shadow for depth
                context.cgContext.setShadow(
                    offset: CGSize(width: 0, height: 3), 
                    blur: 6, 
                    color: UIColor.black.withAlphaComponent(0.35).cgColor
                )
                
                // Draw outer border circle
                borderColor.setFill()
                context.cgContext.fillEllipse(in: rect)
                
                // Draw inner background circle with transparency
                backgroundColor.setFill()
                context.cgContext.fillEllipse(in: innerRect)
                
                // Draw icon with proper rendering
                context.cgContext.saveGState()
                context.cgContext.setShadow(offset: CGSize.zero, blur: 0) // Clear shadow for icon
                
                let iconSize: CGFloat = 16
                let iconConfig = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .semibold)
                if let icon = UIImage(systemName: iconName, withConfiguration: iconConfig) {
                    let iconRect = CGRect(
                        x: (size.width - iconSize) / 2,
                        y: (size.height - iconSize) / 2,
                        width: iconSize,
                        height: iconSize
                    )
                    
                    // Draw icon with color
                    iconColor.setFill()
                    icon.draw(in: iconRect, blendMode: .normal, alpha: 1.0)
                }
                
                context.cgContext.restoreGState()
            }
        }
    }
}

class MapPointAnnotation: NSObject, MKAnnotation {
    let item: MapAnnotationItem
    
    var coordinate: CLLocationCoordinate2D {
        return item.coordinate
    }
    
    var title: String? {
        return item.title
    }
    
    init(mapAnnotationItem: MapAnnotationItem) {
        self.item = mapAnnotationItem
        super.init()
    }
}

extension MKCoordinateRegion {
    func isEqual(to other: MKCoordinateRegion, tolerance: Double = 0.0001) -> Bool {
        return abs(center.latitude - other.center.latitude) < tolerance &&
               abs(center.longitude - other.center.longitude) < tolerance &&
               abs(span.latitudeDelta - other.span.latitudeDelta) < tolerance &&
               abs(span.longitudeDelta - other.span.longitudeDelta) < tolerance
    }
}

// MARK: - Custom Piste Polyline Renderer with Labels

class PistePolylineRenderer: MKPolylineRenderer {
    
    static var showPisteNames: Bool = true
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        // Draw the polyline first
        super.draw(mapRect, zoomScale: zoomScale, in: context)
        
        // Draw the piste name along the line if available and enabled
        guard PistePolylineRenderer.showPisteNames,
              let polyline = self.polyline as? MKPolyline,
              let pisteName = polyline.title,
              !pisteName.isEmpty,
              zoomScale > 0.5 else { // Only show labels at sufficient zoom level
            return
        }
        
        drawPisteNameAlongPath(pisteName, context: context, mapRect: mapRect, zoomScale: zoomScale)
    }
    
    private func drawPisteNameAlongPath(_ name: String, context: CGContext, mapRect: MKMapRect, zoomScale: MKZoomScale) {
        let points = polyline.points()
        let pointCount = polyline.pointCount
        
        guard pointCount >= 2 else { return }
        
        // Convert MKMapPoints to CGPoints
        var cgPoints: [CGPoint] = []
        for i in 0..<pointCount {
            let mapPoint = points[i]
            let cgPoint = point(for: mapPoint)
            cgPoints.append(cgPoint)
        }
        
        // Calculate total path length and find midpoint
        var totalLength: CGFloat = 0
        var segmentLengths: [CGFloat] = []
        
        for i in 0..<cgPoints.count - 1 {
            let length = distance(from: cgPoints[i], to: cgPoints[i + 1])
            segmentLengths.append(length)
            totalLength += length
        }
        
        guard totalLength > 0 else { return }
        
        // Find position for text (middle of the line)
        let targetLength = totalLength / 2
        var currentLength: CGFloat = 0
        var textPosition = cgPoints[0]
        var textAngle: CGFloat = 0
        
        for i in 0..<segmentLengths.count {
            let segmentLength = segmentLengths[i]
            
            if currentLength + segmentLength >= targetLength {
                // Text should be placed in this segment
                let remainingLength = targetLength - currentLength
                let ratio = remainingLength / segmentLength
                
                let startPoint = cgPoints[i]
                let endPoint = cgPoints[i + 1]
                
                // Interpolate position
                textPosition.x = startPoint.x + (endPoint.x - startPoint.x) * ratio
                textPosition.y = startPoint.y + (endPoint.y - startPoint.y) * ratio
                
                // Calculate angle for text rotation
                let dx = endPoint.x - startPoint.x
                let dy = endPoint.y - startPoint.y
                textAngle = atan2(dy, dx)
                
                // Normalize angle to avoid upside-down text
                if textAngle > CGFloat.pi / 2 {
                    textAngle -= CGFloat.pi
                } else if textAngle < -CGFloat.pi / 2 {
                    textAngle += CGFloat.pi
                }
                
                break
            }
            
            currentLength += segmentLength
        }
        
        // Draw the text
        drawText(name, at: textPosition, angle: textAngle, context: context, zoomScale: zoomScale)
    }
    
    private func drawText(_ text: String, at position: CGPoint, angle: CGFloat, context: CGContext, zoomScale: MKZoomScale) {
        let fontSize = max(10, min(16, 12 / zoomScale)) // Adaptive font size
        let font = UIFont.boldSystemFont(ofSize: fontSize)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -2.0 // Negative for fill + stroke
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        
        context.saveGState()
        
        // Move to text position
        context.translateBy(x: position.x, y: position.y)
        
        // Rotate for text along path
        context.rotate(by: angle)
        
        // Center the text
        let rect = CGRect(x: -textSize.width / 2, y: -textSize.height / 2, width: textSize.width, height: textSize.height)
        
        // Draw text
        attributedString.draw(in: rect)
        
        context.restoreGState()
    }
    
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
}

// Note: Using existing OverpassResponse from Models/OverpassResponse.swift

struct MapAnnotationItem: Identifiable, Equatable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType
    let title: String
    let accommodation: Accommodation?
    
    static func == (lhs: MapAnnotationItem, rhs: MapAnnotationItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum AnnotationType: String {
    case resort = "resort"
    case accommodation = "accommodation"
    case lift = "lift"
}


struct AccommodationMapCard: View {
    let accommodation: Accommodation
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(accommodation.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Label("\(accommodation.distanceToLift) m", systemImage: "figure.skiing.downhill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", accommodation.rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            
            HStack {
                Text(accommodation.priceCategory.rawValue)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("pro Nacht")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Wellness Features
                HStack(spacing: 8) {
                    if accommodation.hasPool {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.cyan)
                            .font(.caption)
                    }
                    if accommodation.hasJacuzzi {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                            .font(.caption)
                    }
                    if accommodation.hasSpa {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    if accommodation.hasSauna {
                        Image(systemName: "thermometer.sun.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
            }
            
            if !accommodation.isRealData {
                Text("BEISPIELDATEN")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 10)
    }
}

// MARK: - Custom Map View with Pistes

struct CustomMapViewWithPistes: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let mapType: MKMapType
    let annotations: [MapAnnotationItem]
    let skiPistes: [SkiPiste]
    let onAnnotationTap: (MapAnnotationItem) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = mapType
        mapView.setRegion(region, animated: false)
        
        // Clear any existing annotation views cache
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
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
        
        // Update annotations - force refresh every time
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        let newAnnotations = annotations.map { MapPointAnnotation(mapAnnotationItem: $0) }
        print("🚡 Adding \(newAnnotations.count) total annotations to map")
        print("🚡 Lift annotations: \(newAnnotations.filter { $0.item.type == .lift }.count)")
        
        mapView.addAnnotations(newAnnotations)
        
        // Add piste overlays
        print("🎿 Adding \(skiPistes.count) piste overlays to map")
        for piste in skiPistes {
            let coordinates = piste.coordinates
            if coordinates.count >= 2 {
                let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
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
        let parent: CustomMapViewWithPistes
        
        init(_ parent: CustomMapViewWithPistes) {
            self.parent = parent
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Handle piste name labels
            if let pointAnnotation = annotation as? MKPointAnnotation,
               pointAnnotation.subtitle == "piste_label".localized {
                
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
            
            // Handle regular annotations (MapPointAnnotation)
            guard let pointAnnotation = annotation as? MapPointAnnotation else { return nil }
            
            let identifier = pointAnnotation.item.type.rawValue
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            if let markerView = annotationView as? MKMarkerAnnotationView {
                switch pointAnnotation.item.type {
                case .resort:
                    markerView.markerTintColor = UIColor.systemBlue
                    markerView.glyphImage = UIImage(systemName: "mountain.2.fill")
                case .accommodation:
                    markerView.markerTintColor = UIColor.systemGreen
                    markerView.glyphImage = UIImage(systemName: "bed.double.fill")
                case .lift:
                    markerView.markerTintColor = UIColor.systemOrange
                    markerView.glyphImage = UIImage(systemName: "cable.car")
                    markerView.displayPriority = MKFeatureDisplayPriority.required // Lifts should always be visible
                }
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let pointAnnotation = view.annotation as? MapPointAnnotation {
                parent.onAnnotationTap(pointAnnotation.item)
            }
        }
        
        // MARK: - Piste Overlay Rendering
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = PistePolylineRenderer(polyline: polyline)
                
                // Determine color based on difficulty from subtitle
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
            
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}