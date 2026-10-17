//
//  EpisodeCard.swift
//  xfinn
//
//  Carte épisode (refonte design) : vignette 16:9 avec barre de progression
//  intégrée au bord bas (style Apple TV), badges vu/favori, durée, et bloc
//  texte numéro/titre/synopsis. Utilisée par SeriesDetailView et
//  SeasonEpisodesView. L'état vu/favori est lu via effectiveUserData pour
//  refléter les bascules locales sans re-fetch.
//

import SwiftUI

struct EpisodeCard: View {
    let episode: MediaItem
    @ObservedObject var jellyfinService: JellyfinService

    #if os(tvOS)
    private static let thumbWidth: CGFloat = 440
    private static let thumbHeight: CGFloat = 248
    private static let progressHeight: CGFloat = 8
    #else
    private static let thumbWidth: CGFloat = 150
    private static let thumbHeight: CGFloat = 84
    private static let progressHeight: CGFloat = 4
    #endif

    private var userData: UserData? {
        jellyfinService.effectiveUserData(for: episode)
    }

    /// Fraction de lecture (0...1), nil si pas de reprise en cours
    private var progress: Double? {
        guard let userData,
              userData.playbackPositionTicks > 0,
              let duration = episode.duration,
              duration > 0 else { return nil }
        return min(userData.playbackPosition / duration, 1)
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.sp(30)) {
            thumbnail

            VStack(alignment: .leading, spacing: AppTheme.sp(10)) {
                if let episodeNumber = episode.indexNumber {
                    Text("series.episode".localized(with: episodeNumber).uppercased())
                        .font(.system(size: AppTheme.fs(19), weight: .bold))
                        .foregroundColor(.appTertiary)
                        .kerning(1.2)
                }

                Text(episode.name)
                    .font(.system(size: AppTheme.fs(30), weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let overview = episode.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.system(size: AppTheme.fs(21)))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                if let userData, userData.playbackPositionTicks > 0 {
                    Text("episode.resume_at".localized(with: userData.playbackPosition.formattedDuration))
                        .font(.system(size: AppTheme.fs(19), weight: .medium))
                        .foregroundColor(.appTertiary)
                }
            }
            .padding(.vertical, AppTheme.sp(12))

            Spacer(minLength: 0)
        }
        .padding(AppTheme.sp(18))
        .background(
            RoundedRectangle(cornerRadius: AppTheme.dm(28))
                .fill(AppTheme.glassBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.dm(28))
                .stroke(AppTheme.glassStroke, lineWidth: 1)
        )
    }

    // MARK: - Thumbnail

    private var thumbnail: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.25), Color.gray.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            AsyncImage(url: URL(string: jellyfinService.getImageURL(itemId: episode.id, imageType: "Primary", maxWidth: 800))) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    Image(systemName: "film")
                        .font(.system(size: AppTheme.fs(44)))
                        .foregroundColor(.appTextTertiary)
                @unknown default:
                    EmptyView()
                }
            }
        }
        .frame(width: Self.thumbWidth, height: Self.thumbHeight)
        .overlay(alignment: .topTrailing) {
            MediaCardBadges(userData: userData)
                .padding(AppTheme.sp(14))
        }
        .overlay(alignment: .bottomTrailing) {
            if let duration = episode.duration {
                Text(duration.formattedDuration)
                    .font(.system(size: AppTheme.fs(17), weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.sp(14))
                    .padding(.vertical, AppTheme.sp(6))
                    .background(Capsule().fill(Color.black.opacity(0.65)))
                    .padding(AppTheme.sp(14))
                    .padding(.bottom, progress != nil ? Self.progressHeight : 0)
            }
        }
        .overlay(alignment: .bottom) {
            if let progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.black.opacity(0.5))
                        Rectangle()
                            .fill(AppTheme.accentGradient)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: Self.progressHeight)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.dm(18)))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.dm(18))
                .stroke(AppTheme.glassStroke, lineWidth: 1)
        )
    }
}
