//
//  GlassLoadingView.swift
//  xfinn
//
//  Created by Refactoring Phase 1
//

import SwiftUI

/// Vue de chargement avec effet glass
struct GlassLoadingView: View {
    /// Message à afficher sous le spinner
    var message: String = "Chargement..."

    /// Taille du spinner (small, medium, large)
    var size: LoadingSize = .medium

    /// Couleur du spinner
    var tintColor: Color = .appPrimary

    /// Afficher un backdrop sombre
    var showBackdrop: Bool = true

    /// Couleur du glow
    var glowColor: Color = .appPrimary

    enum LoadingSize {
        case small
        case medium
        case large

        var circleSize: CGFloat {
            switch self {
            case .small: return 60
            case .medium: return 100
            case .large: return 140
            }
        }

        var spinnerScale: CGFloat {
            switch self {
            case .small: return 1.2
            case .medium: return 1.8
            case .large: return 2.5
            }
        }

        var textSize: CGFloat {
            switch self {
            case .small: return 18
            case .medium: return 24
            case .large: return 28
            }
        }

        var spacing: CGFloat {
            switch self {
            case .small: return 15
            case .medium: return 25
            case .large: return 35
            }
        }
    }

    var body: some View {
        ZStack {
            // Backdrop optionnel
            if showBackdrop {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
            }

            VStack(spacing: size.spacing) {
                // Spinner avec glass effect
                ZStack {
                    Circle()
                        .fill(AppTheme.glassBackground)
                        .frame(width: size.circleSize, height: size.circleSize)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.glassStroke, lineWidth: 2)
                        )

                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(size.spinnerScale)
                        .tint(tintColor)
                }
                .glowing(color: glowColor, radius: size.circleSize * 0.25)

                // Message
                if !message.isEmpty {
                    Text(message)
                        .font(.system(size: size.textSize, weight: .medium))
                        .foregroundStyle(Color.appTextPrimary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

/// Vue de chargement inline (sans backdrop, pour intégration dans une vue)
struct InlineLoadingView: View {
    var message: String = "Chargement..."
    var tintColor: Color = .appPrimary

    var body: some View {
        HStack(spacing: 15) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(tintColor)

            Text(message)
                .font(AppTheme.body)
                .foregroundStyle(Color.appTextSecondary)
        }
    }
}

/// Vue de chargement pour liste/grille (skeleton-like)
struct SkeletonLoadingView: View {
    var itemCount: Int = 4
    var itemWidth: CGFloat = 200
    var itemHeight: CGFloat = 300
    var spacing: CGFloat = 20

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<itemCount, id: \.self) { _ in
                RoundedRectangle(cornerRadius: AppTheme.largeRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.gray.opacity(0.2),
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.2)
                            ],
                            startPoint: isAnimating ? .leading : .trailing,
                            endPoint: isAnimating ? .trailing : .leading
                        )
                    )
                    .frame(width: itemWidth, height: itemHeight)
            }
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Loading Views") {
    ZStack {
        AppTheme.backgroundGradient.ignoresSafeArea()

        VStack(spacing: 60) {
            // Small
            VStack(spacing: 10) {
                Text("Small")
                    .font(AppTheme.caption)
                    .foregroundStyle(Color.appTextTertiary)

                GlassLoadingView(
                    message: "Chargement...",
                    size: .small,
                    showBackdrop: false
                )
            }

            // Medium (default)
            VStack(spacing: 10) {
                Text("Medium (default)")
                    .font(AppTheme.caption)
                    .foregroundStyle(Color.appTextTertiary)

                GlassLoadingView(
                    message: "Chargement du contenu...",
                    size: .medium,
                    showBackdrop: false
                )
            }

            // Inline
            VStack(spacing: 10) {
                Text("Inline Loading")
                    .font(AppTheme.caption)
                    .foregroundStyle(Color.appTextTertiary)

                InlineLoadingView(message: "Recherche en cours...")
            }

            // Skeleton
            VStack(alignment: .leading, spacing: 10) {
                Text("Skeleton Loading")
                    .font(AppTheme.caption)
                    .foregroundStyle(Color.appTextTertiary)

                SkeletonLoadingView(
                    itemCount: 3,
                    itemWidth: 150,
                    itemHeight: 200
                )
            }
        }
        .padding()
    }
}

#Preview("Full Screen Loading") {
    ZStack {
        // Simulated content behind
        AppTheme.backgroundGradient.ignoresSafeArea()

        VStack {
            Text("Contenu de la page")
                .font(AppTheme.title)
                .foregroundStyle(Color.appTextPrimary)
        }

        // Loading overlay
        GlassLoadingView(
            message: "Chargement du contenu...",
            size: .large,
            showBackdrop: true
        )
    }
}
#endif
