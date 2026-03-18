import SwiftUI
import CoreLocation

struct AsyncAccommodationImage: View {
    let accommodation: Accommodation
    let width: CGFloat
    let height: CGFloat
    
    @StateObject private var imageLoader = AsyncImageLoader()
    
    var body: some View {
        ZStack {
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipped()
                    .contentShape(Rectangle())
            } else if imageLoader.isLoading {
                // Loading state mit coolem Gradient
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.3), 
                            Color.cyan.opacity(0.2),
                            Color.purple.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: width, height: height)
                    .overlay(
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            Text("Foto lädt...")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.top, 8)
                        }
                    )
            } else {
                // Fallback bei Fehler - schöner Gradient mit Icon
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.indigo.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: width, height: height)
                    .overlay(
                        VStack {
                            Image(systemName: getAccommodationIcon())
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text("Hotel Foto")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.top, 4)
                        }
                    )
            }
            
            // Demo-Badge wenn Beispieldaten
            if !accommodation.isRealData {
                VStack {
                    HStack {
                        Spacer()
                        Text("DEMO")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.9))
                            .cornerRadius(4)
                    }
                    Spacer()
                }
                .padding(8)
            }
            
            // Preisanzeige entfernt - nur Dollar-Symbole werden unten angezeigt
        }
        .cornerRadius(12)
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        Task {
            let imageURL = UnsplashImageService.getHotelImageURL(
                for: accommodation.name,
                width: Int(width * 2),
                height: Int(height * 2)
            )

            if let url = imageURL {
                await imageLoader.loadImage(from: url)
            }
        }
    }
    
    private func getAccommodationIcon() -> String {
        let name = accommodation.name.lowercased()
        
        if name.contains("hotel") || name.contains("resort") {
            return "building.2.fill"
        } else if name.contains("lodge") || name.contains("chalet") {
            return "house.fill"
        } else if name.contains("apartment") {
            return "building.fill"
        } else if name.contains("hostel") {
            return "bed.double.fill"
        } else if name.contains("wellness") || name.contains("spa") {
            return "leaf.fill"
        } else {
            return "building.2.fill"
        }
    }
}

#Preview {
    let sampleAccommodation = Accommodation(
        name: "Alpine Wellness Hotel",
        distanceToLift: 50,
        hasPool: true,
        hasJacuzzi: true,
        hasSpa: true,
        pricePerNight: 280,
        rating: 4.8,
        imageUrl: "",
        resort: SkiResort(
            name: "St. Anton",
            country: "Austria",
            region: "Tirol",
            totalSlopes: 305,
            maxElevation: 2811,
            minElevation: 1304,
            coordinate: CLLocationCoordinate2D(latitude: 47.1296, longitude: 10.2686),
            liftCount: 88,
            slopeBreakdown: SlopeBreakdown(greenSlopes: 22, blueSlopes: 123, redSlopes: 85, blackSlopes: 75)
        ),
        isRealData: true
    )
    
    AsyncAccommodationImage(
        accommodation: sampleAccommodation,
        width: 350,
        height: 200
    )
    .padding()
}