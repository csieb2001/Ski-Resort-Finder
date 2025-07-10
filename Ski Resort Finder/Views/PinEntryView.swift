import SwiftUI

struct PinEntryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localization = LocalizationService.shared
    @State private var enteredPin = ""
    @State private var showingError = false
    @State private var isShaking = false
    
    let correctPin = "2025" // Debug PIN - can be changed as needed
    let onSuccess: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                Spacer()
                
                // Header
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Text("debug_access_required".localized)
                        .font(DesignSystem.Typography.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("enter_debug_pin".localized)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                // PIN Display
                HStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < enteredPin.count ? DesignSystem.Colors.primary : DesignSystem.Colors.tertiaryBackground)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(DesignSystem.Colors.separator, lineWidth: 1)
                            )
                            .scaleEffect(index < enteredPin.count ? 1.2 : 1.0)
                            .animation(.spring(), value: enteredPin.count)
                    }
                }
                .offset(x: isShaking ? -10 : 0)
                .animation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true), value: isShaking)
                
                if showingError {
                    Text("incorrect_pin".localized)
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.error)
                        .transition(.opacity)
                }
                
                Spacer()
                
                // Number Pad
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Rows 1-3
                    ForEach(0..<3, id: \.self) { row in
                        HStack(spacing: DesignSystem.Spacing.lg) {
                            ForEach(1...3, id: \.self) { col in
                                let number = row * 3 + col
                                NumberButton(number: number) {
                                    addDigit(String(number))
                                }
                            }
                        }
                    }
                    
                    // Bottom row with 0
                    HStack(spacing: DesignSystem.Spacing.lg) {
                        // Empty space
                        Color.clear
                            .frame(width: 70, height: 70)
                        
                        NumberButton(number: 0) {
                            addDigit("0")
                        }
                        
                        // Delete button
                        Button(action: deleteDigit) {
                            Image(systemName: "delete.left.fill")
                                .font(.title2)
                                .foregroundColor(DesignSystem.Colors.error)
                                .frame(width: 70, height: 70)
                                .background(DesignSystem.Colors.tertiaryBackground)
                                .clipShape(Circle())
                        }
                        .disabled(enteredPin.isEmpty)
                        .opacity(enteredPin.isEmpty ? 0.3 : 1.0)
                    }
                }
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.lg)
            .navigationTitle("debug_access".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("cancel".localized) { 
                        dismiss() 
                    }
                }
            }
        }
    }
    
    private func addDigit(_ digit: String) {
        guard enteredPin.count < 4 else { return }
        
        HapticFeedback.impact(.light)
        enteredPin += digit
        
        if enteredPin.count == 4 {
            checkPin()
        }
        
        // Hide error message when typing
        if showingError {
            withAnimation {
                showingError = false
            }
        }
    }
    
    private func deleteDigit() {
        guard !enteredPin.isEmpty else { return }
        
        HapticFeedback.impact(.light)
        enteredPin = String(enteredPin.dropLast())
        
        // Hide error message when deleting
        if showingError {
            withAnimation {
                showingError = false
            }
        }
    }
    
    private func checkPin() {
        if enteredPin == correctPin {
            HapticFeedback.notification(.success)
            dismiss()
            onSuccess()
        } else {
            HapticFeedback.notification(.error)
            withAnimation {
                showingError = true
                isShaking = true
            }
            
            // Reset after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                enteredPin = ""
                isShaking = false
            }
        }
    }
}

struct NumberButton: View {
    let number: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(number)")
                .font(.title)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .frame(width: 70, height: 70)
                .background(DesignSystem.Colors.tertiaryBackground)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(DesignSystem.Colors.separator.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
}

#Preview {
    PinEntryView(onSuccess: {
        print("PIN correct!")
    })
}