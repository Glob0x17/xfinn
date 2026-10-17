//
//  ViewModelProtocol.swift
//  xfinn
//
//  Created by Refactoring Phase 1
//  Cleaned 18/08/2026: removed unused protocols (ViewModelProtocol,
//  CancellableViewModelProtocol, ErrorHandlingViewModel) — only
//  LoadingState and TaskManager are used, by BaseViewModel.
//

import Foundation

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
