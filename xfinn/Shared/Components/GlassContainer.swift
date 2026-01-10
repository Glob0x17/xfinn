//
//  GlassContainer.swift
//  xfinn
//
//  Created by Refactoring Phase 1
//

import SwiftUI

// MARK: - Glass Container Shapes

/// Conteneur rectangulaire avec effet glass
struct GlassContainer<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let strokeWidth: CGFloat
    let content: Content

    init(
        cornerRadius: CGFloat = AppTheme.extraLargeRadius,
        padding: CGFloat = AppTheme.cardPadding,
        strokeWidth: CGFloat = 1.5,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.strokeWidth = strokeWidth
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(AppTheme.glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.glassStroke, lineWidth: strokeWidth)
            )
    }
}

/// Conteneur circulaire avec effet glass
struct GlassCircle<Content: View>: View {
    let size: CGFloat
    let strokeWidth: CGFloat
    let glowColor: Color?
    let glowRadius: CGFloat
    let content: Content

    init(
        size: CGFloat = 80,
        strokeWidth: CGFloat = 2,
        glowColor: Color? = nil,
        glowRadius: CGFloat = 15,
        @ViewBuilder content: () -> Content
    ) {
        self.size = size
        self.strokeWidth = strokeWidth
        self.glowColor = glowColor
        self.glowRadius = glowRadius
        self.content = content()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.glassBackground)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(AppTheme.glassStroke, lineWidth: strokeWidth)
                )

            content
        }
        .modifier(OptionalGlowModifier(color: glowColor, radius: glowRadius))
    }
}

/// Conteneur capsule avec effet glass
struct GlassCapsule<Content: View>: View {
    let strokeWidth: CGFloat
    let strokeColor: Color?
    let content: Content

    init(
        strokeWidth: CGFloat = 1.5,
        strokeColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.strokeWidth = strokeWidth
        self.strokeColor = strokeColor
        self.content = content()
    }

    var body: some View {
        content
            .background(
                Capsule()
                    .fill(AppTheme.glassBackground)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(strokeColor ?? AppTheme.glassStroke, lineWidth: strokeWidth)
            )
    }
}

/// Conteneur rectangulaire sans padding (pour wrapper des éléments)
struct GlassBox: View {
    let cornerRadius: CGFloat
    let strokeWidth: CGFloat
    let size: CGSize?
    let glowColor: Color?
    let glowRadius: CGFloat

    init(
        cornerRadius: CGFloat = AppTheme.mediumRadius,
        strokeWidth: CGFloat = 1.5,
        size: CGSize? = nil,
        glowColor: Color? = nil,
        glowRadius: CGFloat = 10
    ) {
        self.cornerRadius = cornerRadius
        self.strokeWidth = strokeWidth
        self.size = size
        self.glowColor = glowColor
        self.glowRadius = glowRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(AppTheme.glassBackground)
            .frame(width: size?.width, height: size?.height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.glassStroke, lineWidth: strokeWidth)
            )
            .modifier(OptionalGlowModifier(color: glowColor, radius: glowRadius))
    }
}

// MARK: - Helper Modifier

/// Modifier conditionnel pour le glow
private struct OptionalGlowModifier: ViewModifier {
    let color: Color?
    let radius: CGFloat

    func body(content: Content) -> some View {
        if let glowColor = color {
            content.glowing(color: glowColor, radius: radius)
        } else {
            content
        }
    }
}

// MARK: - Convenience View Extensions

extension View {
    /// Applique un conteneur glass rectangulaire autour du contenu
    func glassContainerStyle(
        cornerRadius: CGFloat = AppTheme.extraLargeRadius,
        padding: CGFloat = AppTheme.cardPadding,
        strokeWidth: CGFloat = 1.5
    ) -> some View {
        self
            .padding(padding)
            .background(AppTheme.glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.glassStroke, lineWidth: strokeWidth)
            )
    }

    /// Applique un conteneur glass capsule autour du contenu
    func glassCapsuleStyle(
        strokeWidth: CGFloat = 1.5,
        strokeColor: Color? = nil
    ) -> some View {
        self
            .background(
                Capsule()
                    .fill(AppTheme.glassBackground)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(strokeColor ?? AppTheme.glassStroke, lineWidth: strokeWidth)
            )
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Glass Containers") {
    ZStack {
        AppTheme.backgroundGradient.ignoresSafeArea()

        VStack(spacing: 40) {
            // GlassContainer
            GlassContainer {
                Text("GlassContainer")
                    .font(AppTheme.headline)
                    .foregroundStyle(Color.appTextPrimary)
            }

            // GlassCircle
            GlassCircle(size: 100, glowColor: .appPrimary) {
                Image(systemName: "play.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.appPrimary)
            }

            // GlassCapsule
            GlassCapsule(strokeColor: .appPrimary.opacity(0.5)) {
                Text("Badge")
                    .font(AppTheme.caption)
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
            }

            // GlassBox
            ZStack {
                GlassBox(size: CGSize(width: 50, height: 50), glowColor: .appSecondary)
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.appSecondary)
            }
        }
    }
}
#endif
