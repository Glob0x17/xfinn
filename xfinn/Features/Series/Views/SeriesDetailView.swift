//
//  SeriesDetailView.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//  Refonte design 08/2026 : page unique hero + sélecteur de saison +
//  épisodes (plus d'écran intermédiaire grille de saisons).
//

import SwiftUI

/// Vue de détail d'une série : hero immersif, chips de saisons, épisodes
struct SeriesDetailView: View {
    @StateObject private var viewModel: SeriesDetailViewModel
    @ObservedObject var jellyfinService: JellyfinService

    init(series: MediaItem, jellyfinService: JellyfinService) {
        self.jellyfinService = jellyfinService
        self._viewModel = StateObject(wrappedValue: SeriesDetailViewModel(series: series, jellyfinService: jellyfinService))
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.sp(40)) {
                    heroSection

                    if viewModel.isLoading {
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage {
                        ErrorStateView(message: errorMessage) {
                            viewModel.clearError()
                            Task { await viewModel.loadSeasons() }
                        }
                    } else if viewModel.isEmpty {
                        emptyStateView
                    } else {
                        seasonPicker
                        episodesSection
                    }
                }
                .padding(.bottom, AppTheme.sp(60))
            }
            .scrollClipDisabled()
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            if !viewModel.hasLoaded {
                Task {
                    await viewModel.loadSeasons()
                }
            }
        }
    }

    // MARK: - Hero Section

    #if os(tvOS)
    private static let heroHeight: CGFloat = 620
    #else
    private static let heroHeight: CGFloat = 340
    #endif

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Backdrop plein cadre. L'image est posée en overlay d'un cadre de taille fixe : en `.fill`
            // directement dans la pile, elle impose sa largeur naturelle et fait déborder tout l'écran
            // sur iPhone (titre, synopsis et épisodes coupés).
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: Self.heroHeight)
                .overlay {
                    AsyncImage(url: URL(string: viewModel.backdropURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure, .empty:
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AppTheme.secondary.opacity(0.35),
                                            AppTheme.tertiary.opacity(0.25)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                .clipped()

            // Scrim : fondu vers le fond de l'app pour la lisibilité du texte
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: Color(red: 0.02, green: 0.05, blue: 0.10).opacity(0.55), location: 0.55),
                    .init(color: Color(red: 0.02, green: 0.05, blue: 0.10).opacity(0.97), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Titre + métadonnées + synopsis, par-dessus le backdrop
            VStack(alignment: .leading, spacing: AppTheme.sp(18)) {
                Text(viewModel.series.name)
                    .font(.system(size: AppTheme.fs(64), weight: .heavy))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.6), radius: 12, y: 2)

                metadataRow

                if let overview = viewModel.series.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.system(size: AppTheme.fs(22)))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(3)
                        .frame(maxWidth: AppTheme.dm(1100), alignment: .leading)
                        .shadow(color: .black.opacity(0.5), radius: 8)
                }
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.bottom, AppTheme.sp(40))
        }
        .frame(height: Self.heroHeight)
    }

    private var metadataRow: some View {
        HStack(spacing: AppTheme.sp(20)) {
            if let year = viewModel.series.productionYear {
                Text(String(year))
                    .font(.system(size: AppTheme.fs(22), weight: .semibold))
                    .foregroundColor(.appTextSecondary)
            }

            if let rating = viewModel.series.communityRating {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: AppTheme.fs(18)))
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: AppTheme.fs(22), weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                }
            }

            if let officialRating = viewModel.series.officialRating {
                Text(officialRating)
                    .font(.system(size: AppTheme.fs(18), weight: .bold))
                    .foregroundColor(.appTextSecondary)
                    .padding(.horizontal, AppTheme.sp(14))
                    .padding(.vertical, AppTheme.sp(5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.45), lineWidth: 1.5)
                    )
            }

            if viewModel.seasonCount > 0 {
                Text(seasonCountText)
                    .font(.system(size: AppTheme.fs(22), weight: .semibold))
                    .foregroundColor(.appTextSecondary)
            }
        }
    }

    private var seasonCountText: String {
        viewModel.seasonCount > 1
            ? "series.season_count.plural".localized(with: viewModel.seasonCount)
            : "series.season_count.singular".localized(with: viewModel.seasonCount)
    }

    // MARK: - Season Picker

    private var seasonPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.sp(20)) {
                ForEach(viewModel.seasons) { season in
                    SeasonChip(
                        season: season,
                        isSelected: season.id == viewModel.selectedSeasonId
                    ) {
                        Task { await viewModel.selectSeason(season) }
                    }
                }
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.vertical, AppTheme.sp(20))
        }
        .scrollClipDisabled()
    }

    // MARK: - Episodes Section

    private var episodesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.sp(30)) {
            if viewModel.isLoadingEpisodes {
                episodesLoadingView
            } else if viewModel.episodes.isEmpty {
                Text("series.no_episodes_message".localized)
                    .font(.system(size: AppTheme.fs(22)))
                    .foregroundColor(.appTextSecondary)
                    .padding(.horizontal, AppTheme.screenPadding)
                    .padding(.vertical, AppTheme.sp(30))
            } else {
                LazyVStack(spacing: AppTheme.sp(30)) {
                    ForEach(viewModel.episodes) { episode in
                        // Clic = fiche de l'épisode, la lecture part de Lire
                        NavigationLink(value: episode) {
                            EpisodeCard(episode: episode, jellyfinService: jellyfinService)
                        }
                        .buttonStyle(CustomCardButtonStyle(cornerRadius: AppTheme.dm(28)))
                        .mediaContextMenu(item: episode, jellyfinService: jellyfinService)
                    }
                }
                .padding(.horizontal, AppTheme.screenPadding)
            }
        }
    }

    private var episodesLoadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.4)
                .tint(.appSecondary)
            Spacer()
        }
        .padding(.vertical, AppTheme.sp(60))
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: AppTheme.sp(30)) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.8)
                .tint(.appSecondary)

            Text("series.loading_seasons".localized)
                .font(.system(size: AppTheme.fs(24), weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.sp(60))
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: AppTheme.sp(30)) {
            Image(systemName: "tv.slash")
                .font(.system(size: AppTheme.fs(80), weight: .light))
                .foregroundColor(.appTextTertiary)

            VStack(spacing: 12) {
                Text("series.no_seasons".localized)
                    .font(.system(size: AppTheme.fs(38), weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text("series.no_seasons_message".localized)
                    .font(.system(size: AppTheme.fs(22)))
                    .foregroundColor(.appTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.sp(60))
    }
}

// MARK: - Season Chip

/// Chip de sélection de saison (rangée horizontale sous le hero)
struct SeasonChip: View {
    let season: MediaItem
    let isSelected: Bool
    let action: () -> Void

    private var label: String {
        if let index = season.indexNumber, index > 0 {
            return "series.season".localized(with: index)
        }
        return season.name
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: AppTheme.fs(26), weight: .semibold))
                .foregroundColor(isSelected ? .white : .appTextSecondary)
                .padding(.horizontal, AppTheme.sp(36))
                .padding(.vertical, AppTheme.sp(16))
                .background(
                    Capsule()
                        .fill(isSelected ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(AppTheme.glassBackground))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? AppTheme.tertiary.opacity(0.8) : AppTheme.glassStroke, lineWidth: 1.5)
                )
        }
        .buttonStyle(GlassButtonStyle(isProminent: isSelected))
    }
}

// MARK: - Season Episodes View

/// Vue directe des épisodes d'une saison (navigation depuis Accueil/
/// Recherche/Bibliothèque quand l'item est déjà une saison)
struct SeasonEpisodesView: View {
    @StateObject private var viewModel: SeasonEpisodesViewModel
    @ObservedObject var jellyfinService: JellyfinService

    init(season: MediaItem, jellyfinService: JellyfinService) {
        self.jellyfinService = jellyfinService
        self._viewModel = StateObject(wrappedValue: SeasonEpisodesViewModel(season: season, jellyfinService: jellyfinService))
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            if viewModel.isLoading {
                loadingView
            } else if viewModel.isEmpty {
                emptyStateView
            } else {
                episodesContent
            }
        }
        .onAppear {
            if !viewModel.hasLoaded {
                Task {
                    await viewModel.loadEpisodes()
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: AppTheme.sp(30)) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.8)
                .tint(.appSecondary)

            Text("series.loading_episodes".localized)
                .font(.system(size: AppTheme.fs(24), weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: AppTheme.sp(30)) {
            Image(systemName: "film.slash")
                .font(.system(size: AppTheme.fs(80), weight: .light))
                .foregroundColor(.appTextTertiary)

            VStack(spacing: 12) {
                Text("series.no_episodes".localized)
                    .font(.system(size: AppTheme.fs(38), weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text("series.no_episodes_message".localized)
                    .font(.system(size: AppTheme.fs(22)))
                    .foregroundColor(.appTextSecondary)
            }
        }
    }

    // MARK: - Episodes Content

    private var episodesContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sp(30)) {
                // En-tête
                VStack(alignment: .leading, spacing: 8) {
                    if let seriesName = viewModel.season.seriesName {
                        Text(seriesName.uppercased())
                            .font(.system(size: AppTheme.fs(20), weight: .bold))
                            .foregroundColor(.appTertiary)
                            .kerning(1.2)
                    }

                    Text(viewModel.season.name)
                        .font(.system(size: AppTheme.fs(48), weight: .heavy))
                        .foregroundColor(.appTextPrimary)

                    Text(viewModel.episodeCountText)
                        .font(.system(size: AppTheme.fs(24)))
                        .foregroundColor(.appTextSecondary)
                }
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.top, AppTheme.sp(40))

                // Liste des épisodes (clic = fiche de l'épisode)
                LazyVStack(spacing: AppTheme.sp(30)) {
                    ForEach(viewModel.episodes) { episode in
                        NavigationLink(value: episode) {
                            EpisodeCard(episode: episode, jellyfinService: jellyfinService)
                        }
                        .buttonStyle(CustomCardButtonStyle(cornerRadius: AppTheme.dm(28)))
                        .mediaContextMenu(item: episode, jellyfinService: jellyfinService)
                    }
                }
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.bottom, AppTheme.sp(60))
            }
            .padding(.top, 20)
        }
        .scrollClipDisabled()
        .contentMargins(.top, 20, for: .scrollContent)
    }
}

#Preview {
    NavigationStack {
        SeriesDetailView(
            series: MediaItem(
                id: "1",
                name: "Série Test",
                type: "Series",
                overview: "Une série de test",
                productionYear: 2023,
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
            jellyfinService: JellyfinService()
        )
    }
}
