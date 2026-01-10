//
//  SectionHeader.swift
//  xfinn
//
//  Created by Refactoring Phase 1
//

import SwiftUI

/// En-tête de section réutilisable avec icône, titre et badge optionnel
struct SectionHeader: View {
    let title: String
    var icon: String? = nil
    var count: Int? = nil
    var accentColor: Color = .appPrimary

    /// Taille de l'icône dans sa box
    var iconSize: CGFloat = 24
    /// Taille de la box contenant l'icône
    var iconBoxSize: CGFloat = 50
    /// Taille du titre
    var titleSize: CGFloat = 38
    /// Afficher un glow sur l'icône
    var showIconGlow: Bool = true

    var body: some View {
        HStack(spacing: 15) {
            // Icône avec glass background
            if let iconName = icon {
                ZStack {
                    GlassBox(
                        cornerRadius: AppTheme.mediumRadius,
                        size: CGSize(width: iconBoxSize, height: iconBoxSize),
                        glowColor: showIconGlow ? accentColor : nil,
                        glowRadius: 10
                    )

                    Image(systemName: iconName)
                        .font(.system(size: iconSize))
                        .foregroundColor(accentColor)
                }
            }

            // Titre
            Text(title)
                .font(.system(size: titleSize, weight: .bold))
                .foregroundStyle(Color.appTextPrimary)

            Spacer()

            // Badge de compteur
            if let count = count {
                CountBadge(count: count, accentColor: accentColor)
            }
        }
    }
}

/// Badge de compteur
struct CountBadge: View {
    let count: Int
    var accentColor: Color = .appPrimary
    var fontSize: CGFloat = 20

    var body: some View {
        Text("\(count)")
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundColor(accentColor)
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(AppTheme.glassBackground)
                    .overlay(
                        Capsule()
                            .stroke(accentColor.opacity(0.5), lineWidth: 1.5)
                    )
            )
    }
}

/// En-tête de section compact (sans icône box)
struct CompactSectionHeader: View {
    let title: String
    var icon: String? = nil
    var subtitle: String? = nil
    var accentColor: Color = .appPrimary
    var titleSize: CGFloat = 32

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: titleSize * 0.7))
                        .foregroundColor(accentColor)
                }

                Text(title)
                    .font(.system(size: titleSize, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)
            }

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: titleSize * 0.55, weight: .medium))
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
    }
}

/// En-tête de section avec action
struct ActionSectionHeader: View {
    let title: String
    var icon: String? = nil
    var actionTitle: String = "Voir tout"
    var actionIcon: String = "chevron.right"
    var accentColor: Color = .appPrimary
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 15) {
            // Icône
            if let iconName = icon {
                ZStack {
                    GlassBox(
                        cornerRadius: AppTheme.mediumRadius,
                        size: CGSize(width: 50, height: 50),
                        glowColor: accentColor,
                        glowRadius: 10
                    )

                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .foregroundColor(accentColor)
                }
            }

            // Titre
            Text(title)
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(Color.appTextPrimary)

            Spacer()

            // Bouton d'action
            if let action = onAction {
                Button(action: action) {
                    HStack(spacing: 8) {
                        Text(actionTitle)
                            .font(.system(size: 20, weight: .medium))

                        Image(systemName: actionIcon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(AppTheme.glassBackground)
                            .overlay(
                                Capsule()
                                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(CustomCardButtonStyle())
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Section Headers") {
    ZStack {
        AppTheme.backgroundGradient.ignoresSafeArea()

        VStack(spacing: 50) {
            // SectionHeader standard
            SectionHeader(
                title: "À reprendre",
                icon: "play.circle.fill",
                count: 5,
                accentColor: .appPrimary
            )
            .padding(.horizontal, 60)

            // SectionHeader sans count
            SectionHeader(
                title: "Récemment ajoutés",
                icon: "sparkles",
                accentColor: .appSecondary
            )
            .padding(.horizontal, 60)

            // CompactSectionHeader
            CompactSectionHeader(
                title: "Films",
                icon: "film",
                subtitle: "Votre collection de films",
                accentColor: .appPrimary
            )
            .padding(.horizontal, 60)

            // ActionSectionHeader
            ActionSectionHeader(
                title: "Séries",
                icon: "tv",
                actionTitle: "Voir tout",
                accentColor: .appSecondary,
                onAction: { print("Action!") }
            )
            .padding(.horizontal, 60)

            // CountBadge seul
            HStack(spacing: 20) {
                CountBadge(count: 12, accentColor: .appPrimary)
                CountBadge(count: 99, accentColor: .appSecondary)
                CountBadge(count: 3, accentColor: .appTertiary)
            }
        }
    }
}
#endif
