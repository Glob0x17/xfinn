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

    /// Indique si le contenu a déjà été chargé
    @Published private(set) var hasLoaded = false

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
        async let resumeTask = loadResumeItems()
        async let recentTask = loadRecentItems()

        await resumeTask
        await recentTask

        withAnimation(AppTheme.standardAnimation) {
            self.hasLoaded = true
            self.setLoaded()
        }
    }

    /// Rafraîchit le contenu
    func refresh() async {
        hasLoaded = false
        resumeItems = []
        recentItems = []
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

    private func loadResumeItems() async {
        do {
            let items = try await jellyfinService.getResumeItems(limit: 10)
            withAnimation(AppTheme.standardAnimation) {
                self.resumeItems = items
            }
        } catch {
            #if DEBUG
            print("[HomeViewModel] Error loading resume items: \(error.localizedDescription)")
            #endif
            // Don't propagate error - continue with other data
        }
    }

    private func loadRecentItems() async {
        do {
            let items = try await jellyfinService.getLatestItems(limit: 10)
            withAnimation(AppTheme.standardAnimation) {
                self.recentItems = items
            }
        } catch {
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
