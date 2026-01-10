//
//  MediaCard.swift
//  xfinn
//
//  Created by Refactoring Phase 1
//

import SwiftUI

// MARK: - Media Card Style

/// Style de carte média
enum MediaCardStyle {
    case poster      // Vertical (2:3 ratio) - pour carousels
    case landscape   // Horizontal (16:9 ratio) - pour recherche
    case compact     // Petit format pour grilles
}

// MARK: - Media Card

/// Carte de média réutilisable avec design Liquid Glass
struct MediaCard: View {
    let item: MediaItem
    let imageURL: String

    /// Style de la carte
    var style: MediaCardStyle = .poster

    /// Couleur d'accent
    var accentColor: Color = .appPrimary

    /// Afficher la barre de progression
    var showProgress: Bool = true

    /// Afficher les métadonnées
    var showMetadata: Bool = true

    /// Afficher l'icône play
    var showPlayIcon: Bool = true

    @Environment(\.isFocused) private var isFocused: Bool

    // Dimensions selon le style
    private var cardWidth: CGFloat {
        switch style {
        case .poster: return 400
        case .landscape: return 500
        case .compact: return 250
        }
    }

    private var imageHeight: CGFloat {
        switch style {
        case .poster: return 600
        case .landscape: return 280
        case .compact: return 375
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image avec overlay
            imageSection

            // Informations
            if showMetadata {
                infoSection
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
        )
        .frame(width: cardWidth)
    }

    // MARK: - Image Section

    private var imageSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Background placeholder
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.gray.opacity(0.3),
                            Color.gray.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Image
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.2)
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(accentColor)
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        Color.gray.opacity(0.2)
                        VStack(spacing: 10) {
                            Image(systemName: mediaIcon)
                                .font(.system(size: 50))
                                .foregroundStyle(Color.appTextTertiary)
                            Text("Image\nindisponible")
                                .font(.caption)
                                .foregroundStyle(Color.appTextTertiary)
                                .multilineTextAlignment(.center)
                        }
                    }
                @unknown default:
                    EmptyView()
                }
            }

            // Overlay gradient
            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)
            .frame(maxHeight: .infinity, alignment: .bottom)

            // Progress bar
            if showProgress, let progress = playbackProgress {
                VStack(spacing: 0) {
                    Spacer()
                    PlaybackProgressBar(
                        playbackPosition: progress.position,
                        duration: progress.duration,
                        accentColor: accentColor,
                        height: 6,
                        totalWidth: cardWidth - 40
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 15)
                }
            }
        }
        .frame(width: cardWidth, height: imageHeight)
        .clipped()
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Titre
            Text(item.displayTitle)
                .font(.system(size: titleFontSize, weight: .semibold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            // Métadonnées
            HStack(spacing: 15) {
                // Année
                if let year = item.productionYear {
                    HStack(spacing: 5) {
                        Image(systemName: "calendar")
                            .font(.system(size: metadataIconSize))
                        Text(String(year))
                            .font(.system(size: metadataFontSize, weight: .medium))
                    }
                    .foregroundStyle(Color.appTextSecondary)
                }

                // Séparateur
                if item.productionYear != nil && item.communityRating != nil {
                    Circle()
                        .fill(Color.appTextTertiary)
                        .frame(width: 4, height: 4)
                }

                // Note
                if let rating = item.communityRating {
                    HStack(spacing: 5) {
                        Image(systemName: "star.fill")
                            .font(.system(size: metadataIconSize))
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: metadataFontSize, weight: .medium))
                            .foregroundStyle(Color.appTextPrimary)
                    }
                }

                Spacer()

                // Icône lecture
                if showPlayIcon {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: playIconSize))
                        .foregroundColor(accentColor)
                }
            }
        }
        .padding(infoPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Rectangle()
                .fill(AppTheme.glassBackground)
        )
    }

    // MARK: - Computed Properties

    private var mediaIcon: String {
        switch item.type.lowercased() {
        case "movie": return "film"
        case "series": return "tv"
        case "episode": return "play.rectangle"
        case "season": return "square.stack"
        default: return "film"
        }
    }

    private var playbackProgress: (position: TimeInterval, duration: TimeInterval)? {
        guard let userData = item.userData,
              userData.playbackPositionTicks > 0,
              let duration = item.duration else {
            return nil
        }
        return (userData.playbackPosition, duration)
    }

    // Tailles adaptatives selon le style
    private var titleFontSize: CGFloat {
        switch style {
        case .poster: return 22
        case .landscape: return 24
        case .compact: return 18
        }
    }

    private var metadataFontSize: CGFloat {
        switch style {
        case .poster: return 16
        case .landscape: return 18
        case .compact: return 14
        }
    }

    private var metadataIconSize: CGFloat {
        switch style {
        case .poster: return 14
        case .landscape: return 16
        case .compact: return 12
        }
    }

    private var playIconSize: CGFloat {
        switch style {
        case .poster: return 24
        case .landscape: return 28
        case .compact: return 20
        }
    }

    private var infoPadding: CGFloat {
        switch style {
        case .poster: return 20
        case .landscape: return 20
        case .compact: return 15
        }
    }
}

// MARK: - Convenience Initializers

extension MediaCard {
    /// Crée une carte poster pour un carousel
    static func poster(
        item: MediaItem,
        imageURL: String,
        accentColor: Color = .appPrimary
    ) -> MediaCard {
        MediaCard(
            item: item,
            imageURL: imageURL,
            style: .poster,
            accentColor: accentColor
        )
    }

    /// Crée une carte paysage pour la recherche
    static func landscape(
        item: MediaItem,
        imageURL: String,
        accentColor: Color = .appPrimary
    ) -> MediaCard {
        MediaCard(
            item: item,
            imageURL: imageURL,
            style: .landscape,
            accentColor: accentColor
        )
    }

    /// Crée une carte compacte pour les grilles
    static func compact(
        item: MediaItem,
        imageURL: String,
        accentColor: Color = .appPrimary
    ) -> MediaCard {
        MediaCard(
            item: item,
            imageURL: imageURL,
            style: .compact,
            accentColor: accentColor,
            showPlayIcon: false
        )
    }
}

// MARK: - Season Card

/// Carte spécifique pour les saisons
struct SeasonMediaCard: View {
    let season: MediaItem
    let imageURL: String

    @Environment(\.isFocused) private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Poster de la saison
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        VStack(spacing: 15) {
                            Image(systemName: "tv")
                                .font(.system(size: 60))
                                .foregroundColor(.appTextTertiary)
                            Text(season.name)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.appTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .frame(width: 300, height: 450)
            .clipped()

            // Informations
            VStack(alignment: .leading, spacing: 12) {
                Text(season.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(1)

                if let indexNumber = season.indexNumber {
                    HStack(spacing: 8) {
                        Image(systemName: "number")
                            .font(.system(size: 14))
                        Text("Saison \(indexNumber)")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.appTextSecondary)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Rectangle()
                    .fill(AppTheme.glassBackground)
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
        )
        .frame(width: 300)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Media Cards") {
    ZStack {
        AppTheme.backgroundGradient.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 50) {
                // Poster style
                VStack(alignment: .leading, spacing: 10) {
                    Text("Poster Style")
                        .font(AppTheme.headline)
                        .foregroundStyle(Color.appTextPrimary)
                        .padding(.horizontal, 60)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 30) {
                            MediaCard.poster(
                                item: MediaItem(
                                    id: "1",
                                    name: "Film Test",
                                    type: "Movie",
                                    overview: nil,
                                    productionYear: 2024,
                                    indexNumber: nil,
                                    parentIndexNumber: nil,
                                    communityRating: 8.5,
                                    officialRating: nil,
                                    runTimeTicks: nil,
                                    userData: nil,
                                    seriesName: nil,
                                    seriesId: nil,
                                    seasonId: nil,
                                    mediaStreams: nil
                                ),
                                imageURL: "",
                                accentColor: .appPrimary
                            )
                        }
                        .padding(.horizontal, 60)
                    }
                }

                // Compact style
                VStack(alignment: .leading, spacing: 10) {
                    Text("Compact Style")
                        .font(AppTheme.headline)
                        .foregroundStyle(Color.appTextPrimary)
                        .padding(.horizontal, 60)

                    MediaCard.compact(
                        item: MediaItem(
                            id: "2",
                            name: "Série Test",
                            type: "Series",
                            overview: nil,
                            productionYear: 2023,
                            indexNumber: nil,
                            parentIndexNumber: nil,
                            communityRating: 9.1,
                            officialRating: nil,
                            runTimeTicks: nil,
                            userData: nil,
                            seriesName: nil,
                            seriesId: nil,
                            seasonId: nil,
                            mediaStreams: nil
                        ),
                        imageURL: "",
                        accentColor: .appSecondary
                    )
                    .padding(.horizontal, 60)
                }
            }
            .padding(.vertical, 40)
        }
    }
}
#endif
