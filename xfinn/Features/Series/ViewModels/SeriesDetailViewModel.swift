//
//  SeriesDetailViewModel.swift
//  xfinn
//
//  Created by Refactoring Phase 1
//

import Foundation
import SwiftUI
import Combine

// MARK: - Series Detail ViewModel

/// ViewModel pour la vue de détail d'une série
@MainActor
final class SeriesDetailViewModel: BaseViewModel {
    // MARK: - Published Properties

    /// La série affichée
    let series: MediaItem

    /// Les saisons de la série
    @Published private(set) var seasons: [MediaItem] = []

    /// La saison actuellement sélectionnée (chips)
    @Published private(set) var selectedSeasonId: String?

    /// Épisodes chargés, par saison (cache : un aller serveur par saison)
    @Published private(set) var episodesBySeason: [String: [MediaItem]] = [:]

    /// Indique si les épisodes de la saison sélectionnée chargent
    @Published private(set) var isLoadingEpisodes = false

    /// Indique si le contenu est en chargement
    @Published private(set) var isLoading = true

    /// Indique si le contenu a été chargé
    @Published private(set) var hasLoaded = false

    // MARK: - Dependencies

    private let jellyfinService: JellyfinService

    // MARK: - Computed Properties

    /// Nombre de saisons
    var seasonCount: Int {
        seasons.count
    }

    /// Indique si l'état est vide (chargé mais sans saisons)
    var isEmpty: Bool {
        !isLoading && seasons.isEmpty
    }

    /// La saison sélectionnée
    var selectedSeason: MediaItem? {
        seasons.first { $0.id == selectedSeasonId }
    }

    /// Épisodes de la saison sélectionnée
    var episodes: [MediaItem] {
        selectedSeasonId.flatMap { episodesBySeason[$0] } ?? []
    }

    // MARK: - Initialization

    init(series: MediaItem, jellyfinService: JellyfinService) {
        self.series = series
        self.jellyfinService = jellyfinService
        super.init()
    }

    // MARK: - Public Methods

    /// Charge les saisons de la série
    func loadSeasons() async {
        guard !hasLoaded else { return }

        hasLoaded = true
        isLoading = true

        do {
            let loadedSeasons = try await jellyfinService.getItems(
                parentId: series.id,
                includeItemTypes: ["Season"]
            )

            withAnimation(AppTheme.standardAnimation) {
                self.seasons = loadedSeasons
                self.isLoading = false
            }

            // Sélectionne la première saison et charge ses épisodes
            if selectedSeasonId == nil, let first = loadedSeasons.first {
                await selectSeason(first)
            }
        } catch {
            #if DEBUG
            print("[SeriesDetailViewModel] Error loading seasons: \(error.localizedDescription)")
            #endif
            self.hasLoaded = false
            self.isLoading = false
            self.setError(error)
        }
    }

    /// Sélectionne une saison et charge ses épisodes si nécessaire
    func selectSeason(_ season: MediaItem) async {
        selectedSeasonId = season.id
        guard episodesBySeason[season.id] == nil else { return }

        isLoadingEpisodes = true
        do {
            let loadedEpisodes = try await jellyfinService.getItems(
                parentId: season.id,
                includeItemTypes: ["Episode"]
            )
            withAnimation(AppTheme.standardAnimation) {
                self.episodesBySeason[season.id] = loadedEpisodes
                self.isLoadingEpisodes = false
            }
        } catch {
            #if DEBUG
            print("[SeriesDetailViewModel] Error loading episodes: \(error.localizedDescription)")
            #endif
            self.isLoadingEpisodes = false
            self.setError(error)
        }
    }

    /// Force le rechargement des saisons
    func refresh() async {
        hasLoaded = false
        seasons = []
        selectedSeasonId = nil
        episodesBySeason = [:]
        await loadSeasons()
    }

    // MARK: - Image URLs

    /// URL du backdrop de la série (haute résolution pour le hero plein écran)
    var backdropURL: String {
        jellyfinService.getImageURL(itemId: series.id, imageType: "Backdrop", maxWidth: 1920)
    }

    /// Génère l'URL d'image pour une saison
    func getImageURL(for season: MediaItem, imageType: String = "Primary") -> String {
        jellyfinService.getImageURL(itemId: season.id, imageType: imageType)
    }
}

// MARK: - Season Episodes ViewModel

/// ViewModel pour la vue des épisodes d'une saison
@MainActor
final class SeasonEpisodesViewModel: BaseViewModel {
    // MARK: - Published Properties

    /// La saison affichée
    let season: MediaItem

    /// Les épisodes de la saison
    @Published private(set) var episodes: [MediaItem] = []

    /// Indique si le contenu est en chargement
    @Published private(set) var isLoading = true

    /// Indique si le contenu a été chargé
    @Published private(set) var hasLoaded = false

    // MARK: - Dependencies

    private let jellyfinService: JellyfinService

    // MARK: - Computed Properties

    /// Nombre d'épisodes
    var episodeCount: Int {
        episodes.count
    }

    /// Texte du compteur d'épisodes
    var episodeCountText: String {
        episodeCount > 1 ? "series.episode_count.plural".localized(with: episodeCount) : "series.episode_count.singular".localized(with: episodeCount)
    }

    /// Indique si l'état est vide (chargé mais sans épisodes)
    var isEmpty: Bool {
        !isLoading && episodes.isEmpty
    }

    // MARK: - Initialization

    init(season: MediaItem, jellyfinService: JellyfinService) {
        self.season = season
        self.jellyfinService = jellyfinService
        super.init()
    }

    // MARK: - Public Methods

    /// Charge les épisodes de la saison
    func loadEpisodes() async {
        guard !hasLoaded else { return }

        hasLoaded = true
        isLoading = true

        do {
            let loadedEpisodes = try await jellyfinService.getItems(
                parentId: season.id,
                includeItemTypes: ["Episode"]
            )

            withAnimation(AppTheme.standardAnimation) {
                self.episodes = loadedEpisodes
                self.isLoading = false
            }
        } catch {
            #if DEBUG
            print("[SeasonEpisodesViewModel] Error loading episodes: \(error.localizedDescription)")
            #endif
            self.hasLoaded = false
            self.isLoading = false
            self.setError(error)
        }
    }

    /// Force le rechargement des épisodes
    func refresh() async {
        hasLoaded = false
        episodes = []
        await loadEpisodes()
    }

    // MARK: - Image URLs

    /// Génère l'URL d'image pour un épisode
    func getImageURL(for episode: MediaItem, imageType: String = "Primary") -> String {
        jellyfinService.getImageURL(itemId: episode.id, imageType: imageType)
    }
}

// MARK: - Preview Helper

#if DEBUG
extension SeriesDetailViewModel {
    static var preview: SeriesDetailViewModel {
        SeriesDetailViewModel(
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

extension SeasonEpisodesViewModel {
    static var preview: SeasonEpisodesViewModel {
        SeasonEpisodesViewModel(
            season: MediaItem(
                id: "1",
                name: "Saison 1",
                type: "Season",
                overview: nil,
                productionYear: nil,
                indexNumber: 1,
                parentIndexNumber: nil,
                communityRating: nil,
                officialRating: nil,
                runTimeTicks: nil,
                userData: nil,
                seriesName: "Série Test",
                seriesId: nil,
                seasonId: nil,
                mediaStreams: nil
            ),
            jellyfinService: JellyfinService()
        )
    }
}
#endif
