import SwiftUI

// MARK: - Accommodation Image Carousel
struct AccommodationImageCarousel: View {
    let imageUrls: [String]
    let accommodationName: String
    
    @State private var currentImageIndex = 0
    @State private var showFullScreenGallery = false
    
    var body: some View {
        Group {
            if imageUrls.isEmpty {
                // Fallback für keine Bilder
                placeholderImage
            } else if imageUrls.count == 1 {
                // Einzelnes Bild
                singleImageView
            } else {
                // Mehrere Bilder - Carousel
                carouselView
            }
        }
        .sheet(isPresented: $showFullScreenGallery) {
            AccommodationImageGallery(
                imageUrls: imageUrls,
                accommodationName: accommodationName,
                initialIndex: currentImageIndex
            )
        }
    }
    
    @ViewBuilder
    private var placeholderImage: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("no_images_available".localized)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(.gray)
                }
            )
    }
    
    @ViewBuilder
    private var singleImageView: some View {
        AsyncImage(url: URL(string: imageUrls[0])) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    ProgressView()
                        .scaleEffect(0.8)
                )
        }
        .onTapGesture {
            HapticFeedback.impact(.light)
            print("Single image tap detected - opening full screen gallery")
            currentImageIndex = 0
            showFullScreenGallery = true
        }
    }
    
    @ViewBuilder 
    private var carouselView: some View {
        VStack(spacing: 0) {
            // Main Image Container with proper tap handling
            ZStack {
                TabView(selection: $currentImageIndex) {
                    ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .onTapGesture {
                                    // Direct tap on image - most reliable
                                    HapticFeedback.impact(.light)
                                    print("Direct image tap detected - opening full screen gallery")
                                    showFullScreenGallery = true
                                }
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.8)
                                )
                                .onTapGesture {
                                    // Tap on placeholder too
                                    HapticFeedback.impact(.light)
                                    print("Placeholder tap detected - opening full screen gallery")
                                    showFullScreenGallery = true
                                }
                        }
                        .tag(index)
                        .clipped() // Fix potential overflow
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(DesignSystem.Animation.medium, value: currentImageIndex)
            }
            
            // Image Indicators and Info - without gray bar background
            if imageUrls.count > 1 {
                HStack {
                    // Dots Indicator
                    HStack(spacing: 4) {
                        ForEach(0..<min(imageUrls.count, 5), id: \.self) { index in
                            Button(action: {
                                HapticFeedback.selection()
                                withAnimation(DesignSystem.Animation.medium) {
                                    currentImageIndex = index
                                }
                            }) {
                                Circle()
                                    .fill(currentImageIndex == index ? Color.white : Color.white.opacity(0.5))
                                    .frame(width: 6, height: 6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        if imageUrls.count > 5 {
                            Text("+\(imageUrls.count - 5)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    // Image Counter
                    HStack(spacing: 2) {
                        Image(systemName: "photo")
                            .font(.caption)
                        Text("\(currentImageIndex + 1)/\(imageUrls.count)")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(DesignSystem.Spacing.sm)
            }
        }
    }
}

// MARK: - Full Screen Image Gallery
struct AccommodationImageGallery: View {
    let imageUrls: [String]
    let accommodationName: String
    let initialIndex: Int
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var showImageInfo = true
    
    init(imageUrls: [String], accommodationName: String, initialIndex: Int = 0) {
        self.imageUrls = imageUrls
        self.accommodationName = accommodationName
        self.initialIndex = initialIndex
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if imageUrls.isEmpty {
                    emptyStateView
                } else {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                            GeometryReader { geometry in
                                AsyncImage(url: URL(string: imageUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                        .clipped()
                                } placeholder: {
                                    VStack {
                                        ProgressView()
                                            .scaleEffect(1.2)
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        
                                        Text("loading_image".localized)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                            .padding(.top, 8)
                                    }
                                }
                            }
                            .tag(index)
                            .onTapGesture {
                                withAnimation(DesignSystem.Animation.medium) {
                                    showImageInfo.toggle()
                                }
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(DesignSystem.Animation.medium, value: currentIndex)
                }
                
                // Overlay with image info
                if showImageInfo && !imageUrls.isEmpty {
                    VStack {
                        // Top bar
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            // Image counter
                            Text("\(currentIndex + 1) " + "of".localized + " \(imageUrls.count)")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.black.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Bottom info
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(accommodationName)
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(.white)
                            
                            Text("accommodation_images".localized)
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.black.opacity(0.8), .clear],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                    }
                    .transition(.opacity)
                }
            }
            .navigationBarHidden(true)
            .statusBarHidden()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.6))
            
            Text("no_images_available".localized)
                .font(DesignSystem.Typography.title2)
                .foregroundColor(.white)
            
            Text("no_images_description".localized)
                .font(DesignSystem.Typography.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { dismiss() }) {
                Text("close".localized)
                    .font(DesignSystem.Typography.calloutEmphasized)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.top)
        }
    }
}

// MARK: - Preview
#Preview("Single Image") {
    AccommodationImageCarousel(
        imageUrls: ["https://example.com/image1.jpg"],
        accommodationName: "Test Hotel"
    )
    .frame(height: 200)
}

#Preview("Multiple Images") {
    AccommodationImageCarousel(
        imageUrls: [
            "https://example.com/image1.jpg",
            "https://example.com/image2.jpg",
            "https://example.com/image3.jpg"
        ],
        accommodationName: "Test Resort"
    )
    .frame(height: 200)
}

#Preview("No Images") {
    AccommodationImageCarousel(
        imageUrls: [],
        accommodationName: "Hotel ohne Bilder"
    )
    .frame(height: 200)
}