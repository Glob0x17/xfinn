//
//  AppDestinations.swift
//  xfinn
//
//  Routeur unique des écrans poussés dans le NavigationStack de l'accueil.
//  Toutes les cartes et tous les boutons poussent une valeur
//  (`NavigationLink(value:)` ou `NavigationCoordinator`) ; seul ce fichier
//  décide quelle vue afficher.
//

import SwiftUI

/// Écran d'un média selon son type Jellyfin
struct MediaItemDestination: View {
    let item: MediaItem
    @ObservedObject var jellyfinService: JellyfinService

    var body: some View {
        content
            // Recrée la vue (et ses StateObject) quand un autre média
            // remplace celui-ci dans le path (épisode suivant)
            .id(item.id)
    }

    @ViewBuilder
    private var content: some View {
        switch item.type {
        case "Series":
            SeriesDetailView(series: item, jellyfinService: jellyfinService)
        case "Season":
            SeasonEpisodesView(season: item, jellyfinService: jellyfinService)
        case "MusicAlbum":
            AlbumDetailView(album: item, jellyfinService: jellyfinService)
        case "MusicArtist":
            ArtistDetailView(artist: item, jellyfinService: jellyfinService)
        default:
            MediaDetailView(item: item, jellyfinService: jellyfinService)
        }
    }
}

/// Écrans hors médias
struct AppRouteDestination: View {
    let route: AppRoute
    @ObservedObject var jellyfinService: JellyfinService

    var body: some View {
        switch route {
        case .libraries:
            LibraryView(jellyfinService: jellyfinService)
        case .library(let library):
            LibraryContentRouter(library: library, jellyfinService: jellyfinService)
        case .search:
            SearchView(jellyfinService: jellyfinService)
        case .musicLibrary:
            MusicLibraryView(library: nil, jellyfinService: jellyfinService)
        }
    }
}
