import SwiftUI

struct AmenityChip: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(color)
            
            Text(text)
                .font(DesignSystem.Typography.caption2)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.primaryText)
        }
        .padding(.horizontal, DesignSystem.Spacing.xs)
        .padding(.vertical, DesignSystem.Spacing.xxs)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs, style: DesignSystem.CornerRadius.continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs, style: DesignSystem.CornerRadius.continuous)
                .stroke(color.opacity(0.3), lineWidth: 0.5)
        )
    }
}

#Preview {
    VStack {
        HStack {
            AmenityChip(icon: "drop.fill", text: "Pool", color: .cyan)
            AmenityChip(icon: "sparkles", text: "Jacuzzi", color: .purple)
            AmenityChip(icon: "leaf.fill", text: "Spa", color: .green)
        }
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}