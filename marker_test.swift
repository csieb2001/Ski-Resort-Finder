import UIKit

enum AnnotationType {
    case resort, accommodation, lift
}

func createStyledMarker(for type: AnnotationType) -> UIImage {
    let size: CGSize = {
        switch type {
        case .resort:
            return CGSize(width: 40, height: 40)
        case .accommodation:
            return CGSize(width: 36, height: 36)
        case .lift:
            return CGSize(width: 28, height: 28)
        }
    }()
    
    let renderer = UIGraphicsImageRenderer(size: size)
    
    return renderer.image { context in
        let rect = CGRect(origin: .zero, size: size)
        let borderWidth: CGFloat = 2
        let innerRect = CGRect(x: borderWidth, y: borderWidth, width: size.width - (borderWidth * 2), height: size.height - (borderWidth * 2))
        
        let (backgroundColor, borderColor, iconName, iconColor): (UIColor, UIColor, String, UIColor) = {
            switch type {
            case .resort:
                return (.systemRed.withAlphaComponent(0.9), .systemRed, "mountain.2.fill", .white)
            case .accommodation:
                return (.systemBlue.withAlphaComponent(0.85), .systemBlue, "building.2.fill", .white)
            case .lift:
                return (UIColor.systemOrange.withAlphaComponent(0.6), UIColor.systemOrange.withAlphaComponent(0.8), "cable.car", .white)
            }
        }()
        
        // Draw shadow
        context.cgContext.setShadow(
            offset: CGSize(width: 0, height: 3), 
            blur: 6, 
            color: UIColor.black.withAlphaComponent(0.35).cgColor
        )
        
        // Draw outer border circle
        borderColor.setFill()
        context.cgContext.fillEllipse(in: rect)
        
        // Draw inner background circle
        backgroundColor.setFill()
        context.cgContext.fillEllipse(in: innerRect)
        
        // Draw icon
        context.cgContext.saveGState()
        context.cgContext.setShadow(offset: CGSize.zero, blur: 0)
        
        let iconSize: CGFloat = type == .lift ? 14 : 16
        let iconConfig = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .semibold)
        if let icon = UIImage(systemName: iconName, withConfiguration: iconConfig) {
            let iconRect = CGRect(
                x: (size.width - iconSize) / 2,
                y: (size.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
            
            iconColor.setFill()
            icon.draw(in: iconRect, blendMode: .normal, alpha: 1.0)
        }
        
        context.cgContext.restoreGState()
    }
}

// Test
let liftMarker = createStyledMarker(for: .lift)
print("Created lift marker with size: \(liftMarker.size)")