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

    /// Indique si le contenu est en chargement
    @Published private(set) var isLoading = true

    /// Indique si le contenu a été chargé
    @Published private(set) var hasLoaded = false

    // MARK: - Dependencies

    private let jellyfinService: JellyfinService

    // MARK: - Computed Properties

    /// Indique si la série a des saisons
    var hasSeasons: Bool {
        !seasons.isEmpty
    }

    /// Nombre de saisons
    var seasonCount: Int {
        seasons.count
    }

    /// Indique si l'état est vide (chargé mais sans saisons)
    var isEmpty: Bool {
        !isLoading && seasons.isEmpty
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
        } catch {
            print("[SeriesDetailViewModel] Erreur chargement saisons: \(error.localizedDescription)")
            self.hasLoaded = false
            self.isLoading = false
        }
    }

    /// Force le rechargement des saisons
    func refresh() async {
        hasLoaded = false
        seasons = []
        await loadSeasons()
    }

    // MARK: - Image URLs

    /// URL du backdrop de la série
    var backdropURL: String {
        jellyfinService.getImageURL(itemId: series.id, imageType: "Backdrop")
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

    /// Indique si la saison a des épisodes
    var hasEpisodes: Bool {
        !episodes.isEmpty
    }

    /// Nombre d'épisodes
    var episodeCount: Int {
        episodes.count
    }

    /// Texte du compteur d'épisodes
    var episodeCountText: String {
        "\(episodeCount) épisode\(episodeCount > 1 ? "s" : "")"
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
            print("[SeasonEpisodesViewModel] Erreur chargement épisodes: \(error.localizedDescription)")
            self.hasLoaded = false
            self.isLoading = false
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
