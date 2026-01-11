//
//  SearchViewModel.swift
//  xfinn
//
//  Created by Refactoring Phase 1
//

import Foundation
import SwiftUI
import Combine

// MARK: - Search Filter

/// Filtre de recherche
enum SearchFilter: String, CaseIterable {
    case all
    case movies
    case series
    case episodes

    var displayName: String {
        switch self {
        case .all: return "search.filter.all".localized
        case .movies: return "search.filter.movies".localized
        case .series: return "search.filter.series".localized
        case .episodes: return "search.filter.episodes".localized
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .movies: return "film"
        case .series: return "tv"
        case .episodes: return "list.bullet"
        }
    }

    var itemType: String? {
        switch self {
        case .all: return nil
        case .movies: return "Movie"
        case .series: return "Series"
        case .episodes: return "Episode"
        }
    }
}

// MARK: - Search ViewModel

/// ViewModel pour la vue de recherche
@MainActor
final class SearchViewModel: BaseViewModel {
    // MARK: - Published Properties

    /// Requête de recherche
    @Published var searchQuery = ""

    /// Résultats de la recherche
    @Published private(set) var searchResults: [MediaItem] = []

    /// Filtre sélectionné
    @Published var selectedFilter: SearchFilter = .all

    /// Indique si une recherche est en cours
    @Published private(set) var isSearching = false

    // MARK: - Dependencies

    private let jellyfinService: JellyfinService

    // MARK: - Computed Properties

    /// Résultats filtrés selon le filtre sélectionné
    var filteredResults: [MediaItem] {
        guard selectedFilter != .all else { return searchResults }

        return searchResults.filter { item in
            switch selectedFilter {
            case .all:
                return true
            case .movies:
                return item.type == "Movie"
            case .series:
                return item.type == "Series"
            case .episodes:
                return item.type == "Episode"
            }
        }
    }

    /// Indique si des résultats existent
    var hasResults: Bool {
        !searchResults.isEmpty
    }

    /// Indique si la recherche est vide
    var isSearchEmpty: Bool {
        searchQuery.isEmpty
    }

    /// Indique si aucun résultat n'a été trouvé
    var hasNoResults: Bool {
        !isSearching && !searchQuery.isEmpty && searchResults.isEmpty
    }

    // MARK: - Initialization

    init(jellyfinService: JellyfinService) {
        self.jellyfinService = jellyfinService
        super.init()
    }

    // MARK: - Public Methods

    /// Effectue une recherche
    func performSearch() async {
        guard !searchQuery.isEmpty else { return }

        isSearching = true

        do {
            let results = try await jellyfinService.search(query: searchQuery)

            withAnimation(AppTheme.standardAnimation) {
                self.searchResults = results
                self.isSearching = false
            }
        } catch {
            #if DEBUG
            print("[SearchViewModel] Search error '\(searchQuery)': \(error.localizedDescription)")
            #endif
            withAnimation(AppTheme.standardAnimation) {
                self.isSearching = false
            }
        }
    }

    /// Efface la recherche
    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }

    /// Met à jour le filtre et relance la recherche si nécessaire
    func updateFilter(_ filter: SearchFilter) {
        withAnimation(AppTheme.standardAnimation) {
            selectedFilter = filter
        }

        // Relancer la recherche si une requête existe
        if !searchQuery.isEmpty {
            Task {
                await performSearch()
            }
        }
    }

    // MARK: - Image URLs

    /// Génère l'URL d'image pour un item
    func getImageURL(for item: MediaItem, imageType: String = "Primary") -> String {
        jellyfinService.getImageURL(itemId: item.id, imageType: imageType)
    }
}

// MARK: - Preview Helper

#if DEBUG
extension SearchViewModel {
    /// Crée un ViewModel avec des données de test
    static var preview: SearchViewModel {
        SearchViewModel(jellyfinService: JellyfinService())
    }
}
#endif
