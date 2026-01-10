//
//  ViewModelProtocol.swift
//  xfinn
//
//  Created by Refactoring Phase 1
//

import Foundation
import Combine

// MARK: - Loading State

/// État de chargement pour les ViewModels
enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }

    var isError: Bool {
        if case .error = self { return true }
        return false
    }

    var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }

    static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.loading, .loading): return true
        case (.loaded, .loaded): return true
        case (.error(let lhsMsg), .error(let rhsMsg)): return lhsMsg == rhsMsg
        default: return false
        }
    }
}

// MARK: - ViewModel Protocol

/// Protocole de base pour tous les ViewModels
protocol ViewModelProtocol: ObservableObject {
    /// État de chargement actuel
    var loadingState: LoadingState { get }

    /// Charger les données initiales
    func load() async

    /// Rafraîchir les données
    func refresh() async
}

// MARK: - Default Implementation

extension ViewModelProtocol {
    /// Implémentation par défaut de refresh (appelle load)
    func refresh() async {
        await load()
    }
}

// MARK: - Cancellable ViewModel Protocol

/// Protocole pour les ViewModels avec gestion de tâches annulables
protocol CancellableViewModelProtocol: ViewModelProtocol {
    /// Tâches en cours pouvant être annulées
    var activeTasks: Set<AnyCancellable> { get set }

    /// Annuler toutes les tâches en cours
    func cancelAllTasks()
}

extension CancellableViewModelProtocol {
    func cancelAllTasks() {
        activeTasks.forEach { $0.cancel() }
        activeTasks.removeAll()
    }
}

// MARK: - Async Task Management

/// Helper pour gérer les tâches async dans les ViewModels
final class TaskManager {
    private var tasks: [String: Task<Void, Never>] = [:]

    /// Lance une tâche avec un identifiant unique
    /// Si une tâche avec le même ID existe, elle est annulée
    func run(id: String, priority: TaskPriority? = nil, operation: @escaping () async -> Void) {
        // Annuler la tâche précédente avec le même ID
        tasks[id]?.cancel()

        // Créer et stocker la nouvelle tâche
        let task = Task(priority: priority) {
            await operation()
        }
        tasks[id] = task
    }

    /// Annule une tâche spécifique
    func cancel(id: String) {
        tasks[id]?.cancel()
        tasks.removeValue(forKey: id)
    }

    /// Annule toutes les tâches
    func cancelAll() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }

    deinit {
        cancelAll()
    }
}

// MARK: - Error Handling

/// Protocole pour la gestion des erreurs dans les ViewModels
protocol ErrorHandlingViewModel: ViewModelProtocol {
    /// Message d'erreur actuel
    var errorMessage: String? { get set }

    /// Gère une erreur et met à jour l'état
    func handleError(_ error: Error)

    /// Efface l'erreur courante
    func clearError()
}

extension ErrorHandlingViewModel {
    func handleError(_ error: Error) {
        if let jellyfinError = error as? JellyfinError {
            errorMessage = jellyfinError.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
