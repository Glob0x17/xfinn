//
//  ProgressBar.swift
//  xfinn
//
//  Created by Refactoring Phase 1
//

import SwiftUI

/// Barre de progression réutilisable avec effet glass
struct ProgressBar: View {
    /// Valeur de progression entre 0 et 1
    let progress: Double

    /// Couleur de la barre de progression
    var accentColor: Color = .appPrimary

    /// Hauteur de la barre
    var height: CGFloat = 6

    /// Afficher le pourcentage à côté
    var showPercentage: Bool = false

    /// Style de la barre (capsule ou rectangle)
    var style: ProgressBarStyle = .capsule

    enum ProgressBarStyle {
        case capsule
        case rectangle
    }

    var body: some View {
        HStack(spacing: 10) {
            GeometryReader { geometry in
                makeProgressBar(geometry: geometry)
            }
            .frame(height: height)

            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(AppTheme.caption2)
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(width: 45, alignment: .trailing)
            }
        }
    }

    @ViewBuilder
    private func makeProgressBar(geometry: GeometryProxy) -> some View {
        let progressWidth = max(0, min(geometry.size.width * progress, geometry.size.width))

        ZStack(alignment: .leading) {
            // Background
            Group {
                switch style {
                case .capsule:
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                case .rectangle:
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                }
            }
            .frame(height: height)

            // Progress
            Group {
                switch style {
                case .capsule:
                    Capsule()
                        .fill(accentColor)
                case .rectangle:
                    Rectangle()
                        .fill(accentColor)
                }
            }
            .frame(width: progressWidth, height: height)
        }
    }
}

/// Barre de progression pour la lecture vidéo avec position de reprise
struct PlaybackProgressBar: View {
    /// Position de lecture en secondes
    let playbackPosition: TimeInterval

    /// Durée totale en secondes
    let duration: TimeInterval

    /// Couleur d'accent
    var accentColor: Color = .appPrimary

    /// Hauteur de la barre
    var height: CGFloat = 6

    /// Largeur totale disponible (pour calcul précis)
    var totalWidth: CGFloat? = nil

    private var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1, max(0, playbackPosition / duration))
    }

    var body: some View {
        if let width = totalWidth {
            // Version avec largeur explicite (pour les cartes)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: height)

                Capsule()
                    .fill(accentColor)
                    .frame(width: width * progress, height: height)
            }
        } else {
            // Version flexible
            ProgressBar(
                progress: progress,
                accentColor: accentColor,
                height: height
            )
        }
    }
}

/// Barre de progression circulaire (pour countdown, etc.)
struct CircularProgressBar: View {
    /// Valeur de progression entre 0 et 1
    let progress: Double

    /// Couleur de la barre
    var accentColor: Color = .appPrimary

    /// Épaisseur du trait
    var lineWidth: CGFloat = 4

    /// Taille du cercle
    var size: CGFloat = 60

    /// Contenu au centre
    var centerContent: AnyView? = nil

    init(
        progress: Double,
        accentColor: Color = .appPrimary,
        lineWidth: CGFloat = 4,
        size: CGFloat = 60
    ) {
        self.progress = progress
        self.accentColor = accentColor
        self.lineWidth = lineWidth
        self.size = size
        self.centerContent = nil
    }

    init<Content: View>(
        progress: Double,
        accentColor: Color = .appPrimary,
        lineWidth: CGFloat = 4,
        size: CGFloat = 60,
        @ViewBuilder centerContent: () -> Content
    ) {
        self.progress = progress
        self.accentColor = accentColor
        self.lineWidth = lineWidth
        self.size = size
        self.centerContent = AnyView(centerContent())
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: lineWidth)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(accentColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Center content
            if let content = centerContent {
                content
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Progress Bars") {
    ZStack {
        AppTheme.backgroundGradient.ignoresSafeArea()

        VStack(spacing: 40) {
            // Standard progress bar
            VStack(alignment: .leading, spacing: 10) {
                Text("Standard Progress")
                    .font(AppTheme.caption)
                    .foregroundStyle(Color.appTextSecondary)

                ProgressBar(progress: 0.65, accentColor: .appPrimary)
                    .frame(width: 300)
            }

            // With percentage
            VStack(alignment: .leading, spacing: 10) {
                Text("With Percentage")
                    .font(AppTheme.caption)
                    .foregroundStyle(Color.appTextSecondary)

                ProgressBar(progress: 0.42, accentColor: .appSecondary, showPercentage: true)
                    .frame(width: 300)
            }

            // Playback progress
            VStack(alignment: .leading, spacing: 10) {
                Text("Playback Progress (30min / 2h)")
                    .font(AppTheme.caption)
                    .foregroundStyle(Color.appTextSecondary)

                PlaybackProgressBar(
                    playbackPosition: 1800,
                    duration: 7200,
                    accentColor: .appPrimary
                )
                .frame(width: 300)
            }

            // Circular progress
            HStack(spacing: 30) {
                CircularProgressBar(progress: 0.75, accentColor: .appPrimary)

                CircularProgressBar(progress: 0.5, accentColor: .appSecondary, size: 80) {
                    Text("50%")
                        .font(AppTheme.caption)
                        .foregroundStyle(Color.appTextPrimary)
                }
            }
        }
        .padding()
    }
}
#endif
