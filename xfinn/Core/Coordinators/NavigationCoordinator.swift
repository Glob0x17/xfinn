//
//  NavigationCoordinator.swift
//  xfinn
//
//  Created by Dorian Galiana on 16/12/2025.
//

import SwiftUI
import Combine

/// Coordinateur de navigation pour gérer les transitions entre médias
@MainActor
class NavigationCoordinator: ObservableObject {
    @Published var navigationPath = NavigationPath()
    @Published var shouldAutoPlay = false // Pour indiquer qu'on veut lancer automatiquement la lecture
    
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
}
