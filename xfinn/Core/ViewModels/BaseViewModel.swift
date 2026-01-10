//
//  BaseViewModel.swift
//  xfinn
//
//  Created by Refactoring Phase 1
//

import Foundation
import Combine
import SwiftUI

/// Classe de base pour tous les ViewModels de l'application
@MainActor
class BaseViewModel: ObservableObject {
    // MARK: - Published Properties

    /// État de chargement
    @Published private(set) var loadingState: LoadingState = .idle

    /// Message d'erreur (optionnel, pour affichage détaillé)
    @Published var errorMessage: String?

    // MARK: - Task Management

    /// Gestionnaire de tâches pour éviter les doublons
    let taskManager = TaskManager()

    /// Ensemble des subscriptions Combine
    var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {}

    deinit {
        taskManager.cancelAll()
        cancellables.forEach { $0.cancel() }
    }

    // MARK: - Loading State Management

    /// Définit l'état de chargement
    func setLoading() {
        loadingState = .loading
        errorMessage = nil
    }

    /// Définit l'état chargé avec succès
    func setLoaded() {
        loadingState = .loaded
        errorMessage = nil
    }

    /// Définit l'état d'erreur
    func setError(_ error: Error) {
        if let jellyfinError = error as? JellyfinError {
            errorMessage = jellyfinError.localizedDescription
            loadingState = .error(jellyfinError.localizedDescription)
        } else {
            errorMessage = error.localizedDescription
            loadingState = .error(error.localizedDescription)
        }
    }

    /// Définit l'état d'erreur avec un message personnalisé
    func setError(message: String) {
        errorMessage = message
        loadingState = .error(message)
    }

    /// Réinitialise l'état
    func resetState() {
        loadingState = .idle
        errorMessage = nil
    }

    // MARK: - Async Operation Wrapper

    /// Exécute une opération async avec gestion automatique de l'état de chargement
    /// - Parameters:
    ///   - taskId: Identifiant unique de la tâche (évite les doublons)
    ///   - showLoading: Afficher l'état de chargement
    ///   - operation: L'opération async à exécuter
    func performAsync(
        taskId: String = "default",
        showLoading: Bool = true,
        operation: @escaping () async throws -> Void
    ) {
        taskManager.run(id: taskId) { [weak self] in
            guard let self = self else { return }

            if showLoading {
                self.setLoading()
            }

            do {
                try await operation()
                self.setLoaded()
            } catch {
                // Ne pas afficher d'erreur si la tâche a été annulée
                if !Task.isCancelled {
                    self.setError(error)
                    print("[ViewModel] Erreur: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Exécute une opération async et retourne le résultat
    /// - Parameters:
    ///   - showLoading: Afficher l'état de chargement
    ///   - operation: L'opération async à exécuter
    /// - Returns: Le résultat de l'opération, ou nil en cas d'erreur
    func performAsyncWithResult<T>(
        showLoading: Bool = true,
        operation: @escaping () async throws -> T
    ) async -> T? {
        if showLoading {
            setLoading()
        }

        do {
            let result = try await operation()
            setLoaded()
            return result
        } catch {
            if !Task.isCancelled {
                setError(error)
                print("[ViewModel] Erreur: \(error.localizedDescription)")
            }
            return nil
        }
    }

    // MARK: - Helpers

    /// Vérifie si une opération doit être effectuée (pas déjà en cours)
    var canLoad: Bool {
        !loadingState.isLoading
    }

    /// Efface l'erreur et réinitialise à l'état idle
    func clearError() {
        errorMessage = nil
        if loadingState.isError {
            loadingState = .idle
        }
    }
}

// MARK: - Convenience Extensions

extension BaseViewModel {
    /// Exécute une opération avec animation
    func withAnimation<T>(_ animation: Animation = AppTheme.standardAnimation, _ body: () throws -> T) rethrows -> T {
        try SwiftUI.withAnimation(animation, body)
    }

    /// Exécute du code sur le main thread après un délai
    func delay(_ seconds: Double, action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: action)
    }
}
