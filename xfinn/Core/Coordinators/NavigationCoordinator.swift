//
//  NavigationCoordinator.swift
//  xfinn
//
//  Created by Dorian Galiana on 16/12/2025.
//

import SwiftUI
import Combine

/// Écrans de navigation qui ne sont pas des médias. Les médias sont poussés
/// directement comme `MediaItem` (voir `MediaItemDestination`).
///
/// Toute la navigation passe par `navigationPath` : un `NavigationLink`
/// à destination directe (hors path) est retiré par SwiftUI dès que le path
/// change — ouvrir un épisode depuis une fiche série poussée ainsi faisait
/// revenir à l'accueil au retour arrière.
enum AppRoute: Hashable {
    case libraries
    case library(LibraryItem)
    case search
    case musicLibrary
}

/// Coordinateur de navigation pour gérer les transitions entre médias
@MainActor
class NavigationCoordinator: ObservableObject {
    // MARK: - Navigation Path
    
    @Published var navigationPath = NavigationPath()
    @Published var shouldAutoPlay = false // Pour indiquer qu'on veut lancer automatiquement la lecture
    
    // MARK: - Media Navigation
    
    /// Naviguer vers un média spécifique
    func navigateTo(item: MediaItem, autoPlay: Bool = false) {
        shouldAutoPlay = autoPlay
        navigationPath.append(item)
    }
    
    /// Remplacer le dernier élément de la navigation (pour la lecture automatique)
    func replaceLastWith(item: MediaItem) {
        // Retirer le dernier élément
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
        // Ajouter le nouveau
        navigationPath.append(item)
    }
    
    /// Retour arrière
    func goBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    /// Retour à la racine
    func goToRoot() {
        navigationPath = NavigationPath()
    }
    
    // MARK: - Écrans hors médias

    /// Ouvre la vue de recherche
    func navigateToSearch() {
        navigationPath.append(AppRoute.search)
    }

    /// Ouvre la bibliothèque musicale
    func navigateToMusicLibrary() {
        navigationPath.append(AppRoute.musicLibrary)
    }
}
