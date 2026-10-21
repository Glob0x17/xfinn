//
//  HomeViewModel.swift
//  xfinn
//
//  Created by Refactoring Phase 1
//

import Foundation
import SwiftUI
import Combine

/// ViewModel pour la vue d'accueil
@MainActor
final class HomeViewModel: BaseViewModel {
    // MARK: - Published Properties

    /// Items à reprendre (Continue Watching)
    @Published private(set) var resumeItems: [MediaItem] = []

    /// Items récemment ajoutés
    @Published private(set) var recentItems: [MediaItem] = []

    /// Favoris de l'utilisateur
    @Published private(set) var favoriteItems: [MediaItem] = []

    /// Indique si le contenu a déjà été chargé
    @Published private(set) var hasLoaded = false

    /// Le serveur a une bibliothèque musicale : sans elle, l'entrée Musique
    /// de l'accueil n'ouvrirait qu'une erreur. Inconnu (échec réseau) = affichée
    @Published private(set) var hasMusicLibrary = false

    // MARK: - Dependencies

    private let jellyfinService: JellyfinService

    // MARK: - Computed Properties

    /// Utilisateur courant
    var currentUser: User? {
        jellyfinService.currentUser
    }

    /// Indique si des items à reprendre existent
    var hasResumeItems: Bool {
        !resumeItems.isEmpty
    }

    /// Indique si des items récents existent
    var hasRecentItems: Bool {
        !recentItems.isEmpty
    }

    var hasFavoriteItems: Bool {
        !favoriteItems.isEmpty
    }

    /// Indique si le contenu est vide (après chargement)
    var isEmpty: Bool {
        hasLoaded && resumeItems.isEmpty && recentItems.isEmpty
    }

    // MARK: - Initialization

    init(jellyfinService: JellyfinService) {
        self.jellyfinService = jellyfinService
        super.init()
    }

    // MARK: - Public Methods

    /// Charge le contenu initial
    func loadContent() async {
        guard !hasLoaded else { return }

        setLoading()

        // Charger les données en parallèle
        lastLoadError = nil

        async let resumeTask = loadResumeItems()
        async let recentTask = loadRecentItems()
        async let favoritesTask = loadFavoriteItems()
        async let musicTask = loadMusicAvailability()

        await resumeTask
        await recentTask
        await favoritesTask
        await musicTask

        withAnimation(AppTheme.standardAnimation) {
            // Échec total (aucune section chargée) : afficher l'état d'erreur.
            // Échec partiel : on affiche ce qu'on a.
            if resumeItems.isEmpty && recentItems.isEmpty, let error = lastLoadError {
                self.hasLoaded = false
                self.setError(error)
            } else {
                self.hasLoaded = true
                self.setLoaded()
            }
        }
    }

    /// Dernière erreur rencontrée pendant le chargement parallèle
    private var lastLoadError: Error?

    /// Rafraîchit le contenu
    func refresh() async {
        hasLoaded = false
        resumeItems = []
        recentItems = []
        favoriteItems = []
        await loadContent()
    }

    /// Force le rechargement des items à reprendre
    func refreshResumeItems() async {
        await loadResumeItems()
    }

    // MARK: - Image URLs

    /// Génère l'URL d'image pour un item
    func getImageURL(for item: MediaItem, imageType: String = "Primary") -> String {
        jellyfinService.getImageURL(itemId: item.id, imageType: imageType)
    }

    // MARK: - Private Methods

    private func loadMusicAvailability() async {
        do {
            let libraries = try await jellyfinService.getLibraries()
            hasMusicLibrary = libraries.contains { $0.collectionType == "music" }
        } catch {
            hasMusicLibrary = true
        }
    }

    private func loadResumeItems() async {
        do {
            let items = try await jellyfinService.getResumeItems(limit: 10)
            withAnimation(AppTheme.standardAnimation) {
                self.resumeItems = items
            }
        } catch {
            lastLoadError = error
            #if DEBUG
            print("[HomeViewModel] Error loading resume items: \(error.localizedDescription)")
            #endif
            // Don't propagate error - continue with other data
        }
    }

    private func loadFavoriteItems() async {
        do {
            let items = try await jellyfinService.getFavoriteItems(limit: 10)
            withAnimation(AppTheme.standardAnimation) {
                self.favoriteItems = items
            }
        } catch {
            // Section optionnelle : silencieux (les autres sections suffisent)
            #if DEBUG
            print("[HomeViewModel] Error loading favorites: \(error.localizedDescription)")
            #endif
        }
    }

    private func loadRecentItems() async {
        do {
            let items = try await jellyfinService.getLatestItems(limit: 10)
            withAnimation(AppTheme.standardAnimation) {
                self.recentItems = items
            }
        } catch {
            lastLoadError = error
            #if DEBUG
            print("[HomeViewModel] Error loading recent items: \(error.localizedDescription)")
            #endif
            // Don't propagate error - continue with other data
        }
    }
}

// MARK: - Preview Helper

#if DEBUG
extension HomeViewModel {
    /// Crée un ViewModel avec des données de test
    static var preview: HomeViewModel {
        let vm = HomeViewModel(jellyfinService: JellyfinService())
        // Les données seront vides en preview, mais la structure est là
        return vm
    }
}
#endif
