import SwiftUI
import UIKit

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Design System
// Centralized design constants following Apple Human Interface Guidelines

struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        // Primary Colors - Mountain/Ski Theme
        static let primary = Color(hex: "4A90E2") // Ski blue
        static let secondary = Color(hex: "6B7280") // Mountain gray
        static let accent = Color(hex: "F59E0B") // Warm orange for highlights
        
        // Semantic Colors
        static let success = Color(hex: "10B981") // Forest green
        static let warning = Color(hex: "F59E0B") // Amber
        static let error = Color(hex: "EF4444") // Red
        static let info = Color(hex: "3B82F6") // Blue
        
        // Dark Glassmorphism Background Colors
        static let background = Color(hex: "0F172A") // Very dark blue-gray
        static let secondaryBackground = Color(hex: "1E293B") // Dark slate
        static let tertiaryBackground = Color(hex: "334155") // Medium slate
        static let groupedBackground = Color(hex: "0F172A")
        
        // Glassmorphism Card Colors
        static let glassBackground = Color.white.opacity(0.1)
        static let glassStroke = Color.white.opacity(0.2)
        static let glassSecondary = Color.white.opacity(0.05)
        
        // Text Colors for dark theme
        static let primaryText = Color.white
        static let secondaryText = Color.white.opacity(0.8)
        static let tertiaryText = Color.white.opacity(0.6)
        static let quaternaryText = Color.white.opacity(0.4)
        
        // UI Element Colors
        static let separator = Color.white.opacity(0.1)
        static let fill = Color.white.opacity(0.1)
        static let secondaryFill = Color.white.opacity(0.08)
        static let tertiaryFill = Color.white.opacity(0.06)
        static let quaternaryFill = Color.white.opacity(0.04)
        
        // Mountain/Ski Category Colors
        static let elevation = Color(hex: "8B5CF6") // Purple
        static let snowfall = Color(hex: "06B6D4") // Cyan
        static let slopes = Color(hex: "10B981") // Emerald
        static let accommodation = Color(hex: "6366F1") // Indigo
        
        // Gradient Colors
        static let mountainGradient = LinearGradient(
            colors: [Color(hex: "1E293B"), Color(hex: "0F172A")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cardGradient = LinearGradient(
            colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Typography
    struct Typography {
        // Large Titles
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title1 = Font.title.weight(.bold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.semibold)
        
        // Headlines
        static let headline = Font.headline.weight(.semibold)
        static let subheadline = Font.subheadline.weight(.medium)
        
        // Body
        static let body = Font.body
        static let bodyEmphasized = Font.body.weight(.semibold)
        static let callout = Font.callout
        static let calloutEmphasized = Font.callout.weight(.semibold)
        
        // Small Text
        static let footnote = Font.footnote
        static let footnoteEmphasized = Font.footnote.weight(.semibold)
        static let caption1 = Font.caption
        static let caption2 = Font.caption2
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        static let huge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let continuous: RoundedCornerStyle = .continuous
    }
    
    // MARK: - Shadows
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        
        static let small = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        static let medium = Shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let large = Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        static let extraLarge = Shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
    }
    
    // MARK: - Animation
    struct Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let medium = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
    }
    
    // MARK: - Layout
    struct Layout {
        static let screenPadding: CGFloat = 16
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let itemSpacing: CGFloat = 12
        
        // Card dimensions
        static let cardMinHeight: CGFloat = 44
        static let buttonHeight: CGFloat = 50
        static let inputHeight: CGFloat = 44
        
        // Touch targets (Apple recommends minimum 44pt)
        static let minTouchTarget: CGFloat = 44
    }
}

// MARK: - View Extensions for Design System
extension View {
    
    // MARK: - Card Styles
    func glassCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: DesignSystem.CornerRadius.continuous)
                    .fill(DesignSystem.Colors.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: DesignSystem.CornerRadius.continuous)
                            .stroke(DesignSystem.Colors.glassStroke, lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    func primaryCard() -> some View {
        self
            .background(DesignSystem.Colors.glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: DesignSystem.CornerRadius.continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: DesignSystem.CornerRadius.continuous)
                    .stroke(DesignSystem.Colors.glassStroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
    }
    
    func secondaryCard() -> some View {
        self
            .background(DesignSystem.Colors.glassSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous)
                    .stroke(DesignSystem.Colors.glassStroke.opacity(0.5), lineWidth: 0.5)
            )
    }
    
    func highlightCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: DesignSystem.CornerRadius.continuous)
                    .fill(DesignSystem.Colors.primary.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: DesignSystem.CornerRadius.continuous)
                            .stroke(DesignSystem.Colors.primary.opacity(0.4), lineWidth: 1)
                    )
            )
            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - Button Styles
    func primaryButton() -> some View {
        self
            .frame(minHeight: DesignSystem.Layout.buttonHeight)
            .background(DesignSystem.Colors.primary)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
            .fontWeight(.semibold)
    }
    
    func secondaryButton() -> some View {
        self
            .frame(minHeight: DesignSystem.Layout.buttonHeight)
            .background(DesignSystem.Colors.secondaryBackground)
            .foregroundColor(DesignSystem.Colors.primary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous)
                    .stroke(DesignSystem.Colors.primary, lineWidth: 1)
            )
            .fontWeight(.semibold)
    }
    
    func destructiveButton() -> some View {
        self
            .frame(minHeight: DesignSystem.Layout.buttonHeight)
            .background(DesignSystem.Colors.error)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: DesignSystem.CornerRadius.continuous))
            .fontWeight(.semibold)
    }
    
    // MARK: - Section Styling
    func sectionContainer() -> some View {
        self
            .padding(DesignSystem.Spacing.md)
            .primaryCard()
    }
    
    // MARK: - Input Styling
    func textFieldStyle() -> some View {
        self
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.tertiaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: DesignSystem.CornerRadius.continuous))
    }
}

// MARK: - Haptic Feedback
struct HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(type)
    }
    
    static func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}