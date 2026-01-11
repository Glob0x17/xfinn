//
//  EpisodeRow.swift
//  xfinn
//
//  Created by Refactoring Phase 1
//

import SwiftUI

/// Ligne d'épisode moderne avec design Liquid Glass
struct EpisodeRow: View {
    let episode: MediaItem
    let imageURL: String

    /// Couleur d'accent pour la progression
    var accentColor: Color = .appPrimary

    /// Largeur de la vignette
    var thumbnailWidth: CGFloat = 500

    /// Hauteur de la vignette
    var thumbnailHeight: CGFloat = 280

    /// Largeur de la barre de progression
    var progressWidth: CGFloat = 450

    @Environment(\.isFocused) private var isFocused: Bool

    var body: some View {
        HStack(spacing: 30) {
            // Vignette de l'épisode
            thumbnailView

            // Informations de l'épisode
            infoView

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 24))
                .foregroundColor(.appTextTertiary)
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.glassBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
        )
    }

    // MARK: - Thumbnail View

    private var thumbnailView: some View {
        ZStack(alignment: .bottomLeading) {
            // Background
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
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    VStack(spacing: 10) {
                        Image(systemName: "film")
                            .font(.system(size: 40))
                            .foregroundColor(.appTextTertiary)
                    }
                @unknown default:
                    EmptyView()
                }
            }

            // Badges (Vu + Durée)
            badgesOverlay
        }
        .frame(width: thumbnailWidth, height: thumbnailHeight)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
        )
    }

    private var badgesOverlay: some View {
        HStack {
            // Badge "Vu"
            if episode.userData?.played == true {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                    Text("series.watched".localized)
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(AppTheme.success.opacity(0.9))
                )
            }

            Spacer()

            // Badge durée
            if let duration = episode.duration {
                Text(formatDuration(duration))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.7))
                    )
            }
        }
        .padding(15)
    }

    // MARK: - Info View

    private var infoView: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Numéro d'épisode
            if let episodeNumber = episode.indexNumber {
                Text("series.episode".localized(with: episodeNumber))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.appTextTertiary)
            }

            // Titre
            Text(episode.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.appTextPrimary)
                .lineLimit(2)

            // Synopsis
            if let overview = episode.overview, !overview.isEmpty {
                Text(overview)
                    .font(.system(size: 20))
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(3)
            }

            // Barre de progression
            if let userData = episode.userData,
               userData.playbackPositionTicks > 0,
               let duration = episode.duration {
                progressView(userData: userData, duration: duration)
            }
        }
    }

    private func progressView(userData: UserData, duration: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            PlaybackProgressBar(
                playbackPosition: userData.playbackPosition,
                duration: duration,
                accentColor: accentColor,
                height: 6,
                totalWidth: progressWidth
            )
            .frame(width: progressWidth)

            Text("episode.resume_at".localized(with: formatDuration(userData.playbackPosition)))
                .font(.system(size: 16))
                .foregroundColor(.appTextTertiary)
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            return "\(hours)h \(remainingMinutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}

/// Version compacte de la ligne d'épisode (pour les grilles)
struct CompactEpisodeRow: View {
    let episode: MediaItem
    let imageURL: String

    var accentColor: Color = .appPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "film")
                                    .font(.system(size: 30))
                                    .foregroundColor(.appTextTertiary)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 150)
                .clipped()

                // Durée
                if let duration = episode.duration {
                    Text(formatDuration(duration))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                        .padding(8)
                }
            }

            // Infos
            VStack(alignment: .leading, spacing: 6) {
                if let episodeNumber = episode.indexNumber {
                    Text("E\(episodeNumber)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appTextTertiary)
                }

                Text(episode.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.glassBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.glassStroke, lineWidth: 1)
        )
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)min"
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Episode Rows") {
    ZStack {
        AppTheme.backgroundGradient.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 30) {
                Text("EpisodeRow")
                    .font(AppTheme.headline)
                    .foregroundStyle(Color.appTextPrimary)

                EpisodeRow(
                    episode: MediaItem(
                        id: "1",
                        name: "Pilot Episode with a Very Long Title",
                        type: "Episode",
                        overview: "The first episode of the series introduces the main characters and sets up the central conflict.",
                        productionYear: 2024,
                        indexNumber: 1,
                        parentIndexNumber: 1,
                        communityRating: 8.5,
                        officialRating: nil,
                        runTimeTicks: 27000000000,
                        userData: UserData(
                            played: false,
                            playbackPositionTicks: 9000000000,
                            playCount: 0
                        ),
                        seriesName: "Test Series",
                        seriesId: nil,
                        seasonId: nil,
                        mediaStreams: nil
                    ),
                    imageURL: ""
                )
                .padding(.horizontal, 60)
            }
            .padding(.vertical, 40)
        }
    }
}
#endif
