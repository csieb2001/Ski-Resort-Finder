//
//  WelcomeWizardView.swift
//  Ski Resort Finder
//
//  Created by Christopher Siebert on 18.03.26.
//

import SwiftUI
import UIKit

struct WelcomeWizardView: View {
    @Binding var hasSeenWelcome: Bool
    @State private var currentPage = 0
    @ObservedObject private var localization = LocalizationService.shared

    private let totalPages = 5

    var body: some View {
        ZStack {
            // Background
            DesignSystem.Colors.mountainGradient
                .ignoresSafeArea()

            DesignSystem.Colors.ambientGlow
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    // Page 1: Welcome
                    welcomePage
                        .tag(0)

                    // Page 2: Resorts
                    featurePage(
                        icon: "mountain.2.fill",
                        iconColor: DesignSystem.Colors.slopes,
                        title: "welcome_resorts_title".localized,
                        description: "welcome_resorts_desc".localized
                    )
                    .tag(1)

                    // Page 3: Snow & Weather
                    featurePage(
                        icon: "snowflake",
                        iconColor: DesignSystem.Colors.snowfall,
                        title: "welcome_snow_title".localized,
                        description: "welcome_snow_desc".localized
                    )
                    .tag(2)

                    // Page 4: Hotels
                    featurePage(
                        icon: "building.2.fill",
                        iconColor: DesignSystem.Colors.accommodation,
                        title: "welcome_hotels_title".localized,
                        description: "welcome_hotels_desc".localized
                    )
                    .tag(3)

                    // Page 5: Get Started
                    getStartedPage
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(DesignSystem.Animation.medium, value: currentPage)

                // Custom page indicator
                pageIndicator
                    .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Welcome Page

    private var welcomePage: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            // Real App Icon
            if let uiImage = UIImage(named: "AppIcon") {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 8)
            } else {
                // Fallback: bundle icon
                if let iconFiles = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
                   let primaryIcon = iconFiles["CFBundlePrimaryIcon"] as? [String: Any],
                   let iconFileNames = primaryIcon["CFBundleIconFiles"] as? [String],
                   let lastIcon = iconFileNames.last,
                   let uiImage = UIImage(named: lastIcon) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 8)
                } else {
                    // Last fallback: SF Symbol
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 64))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .frame(width: 140, height: 140)
                        .glassEffect(in: .circle)
                }
            }

            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("welcome_title".localized)
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)

                Text("welcome_subtitle".localized)
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, DesignSystem.Spacing.xxl)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Feature Page

    private func featurePage(icon: String, iconColor: Color, title: String, description: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            // Icon
            VStack(spacing: DesignSystem.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Image(systemName: icon)
                        .font(.system(size: 52))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [iconColor, iconColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(DesignSystem.Spacing.md)
                .glassEffect(in: .circle)
                .shadow(color: iconColor.opacity(0.25), radius: 16, x: 0, y: 6)
            }

            // Text content in glass card
            VStack(spacing: DesignSystem.Spacing.md) {
                Text(title)
                    .font(DesignSystem.Typography.title1)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(DesignSystem.Spacing.xl)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .glassCard()
            .padding(.horizontal, DesignSystem.Spacing.xl)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Get Started Page

    private var getStartedPage: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            // Icon
            VStack(spacing: DesignSystem.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Image(systemName: "figure.skiing.downhill")
                        .font(.system(size: 52))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(DesignSystem.Spacing.md)
                .glassEffect(in: .circle)
                .shadow(color: DesignSystem.Colors.primary.opacity(0.25), radius: 16, x: 0, y: 6)
            }

            VStack(spacing: DesignSystem.Spacing.md) {
                Text("welcome_start_title".localized)
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)

                Text("welcome_start_desc".localized)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, DesignSystem.Spacing.xxl)

            Spacer()

            // Start button
            Button(action: {
                HapticFeedback.notification(.success)
                withAnimation(DesignSystem.Animation.medium) {
                    hasSeenWelcome = true
                }
            }) {
                Text("welcome_start_button".localized)
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .padding(.horizontal, DesignSystem.Spacing.huge)
            }
            .glassEffect(.regular.interactive(), in: .capsule)
            .tint(DesignSystem.Colors.primary)
            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 12, x: 0, y: 4)
            .padding(.horizontal, DesignSystem.Spacing.xxxl)
            .padding(.bottom, DesignSystem.Spacing.lg)

            Spacer()
        }
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage
                          ? DesignSystem.Colors.primary
                          : DesignSystem.Colors.quaternaryText)
                    .frame(width: index == currentPage ? 10 : 7,
                           height: index == currentPage ? 10 : 7)
                    .animation(DesignSystem.Animation.fast, value: currentPage)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .glassEffect(in: .capsule)
    }
}

#Preview {
    WelcomeWizardView(hasSeenWelcome: .constant(false))
}
