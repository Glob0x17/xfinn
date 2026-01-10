//
//  RepositoryProtocols.swift
//  xfinn
//
//  Created by Refactoring Phase 1
//

import Foundation

// MARK: - Media Repository Protocol

/// Protocole pour le repository de médias
protocol MediaRepositoryProtocol {
    /// Récupère les bibliothèques de l'utilisateur
    func getLibraries() async throws -> [LibraryItem]

    /// Récupère les items d'une bibliothèque
    func getItems(
        parentId: String,
        includeItemTypes: [String]?,
        recursive: Bool,
        limit: Int?
    ) async throws -> [MediaItem]

    /// Récupère les items à reprendre
    func getResumeItems(limit: Int) async throws -> [MediaItem]

    /// Récupère les derniers items ajoutés
    func getLatestItems(parentId: String?, limit: Int) async throws -> [MediaItem]

    /// Recherche des items
    func search(query: String, includeItemTypes: [String]?, limit: Int) async throws -> [MediaItem]

    /// Récupère un item par son ID
    func getItem(itemId: String) async throws -> MediaItem

    /// Récupère les détails d'un item
    func getItemDetails(itemId: String) async throws -> MediaItem

    /// Récupère l'épisode suivant
    func getNextEpisode(currentItemId: String) async throws -> MediaItem?

    /// Génère l'URL d'une image
    func getImageURL(itemId: String, imageType: String, maxWidth: Int) -> String

    /// Génère l'URL de l'image principale
    func getPrimaryImageURL(itemId: String, maxWidth: Int) -> String

    /// Génère l'URL du backdrop
    func getBackdropImageURL(itemId: String, maxWidth: Int) -> String
}

// MARK: - Auth Repository Protocol

/// Protocole pour le repository d'authentification
protocol AuthRepositoryProtocol {
    /// Vérifie si l'utilisateur est authentifié
    var isAuthenticated: Bool { get }

    /// L'utilisateur courant
    var currentUser: User? { get }

    /// Les informations du serveur
    var serverInfo: ServerInfo? { get }

    /// Se connecte à un serveur
    func connect(to serverURL: String) async throws -> ServerInfo

    /// Authentifie un utilisateur
    func authenticate(username: String, password: String) async throws -> User

    /// Charge les credentials sauvegardés
    func loadSavedCredentials() -> Bool

    /// Déconnecte l'utilisateur
    func logout()

    /// Charge l'utilisateur courant
    func loadCurrentUser() async throws -> User
}

// MARK: - Playback Repository Protocol

/// Protocole pour le repository de lecture
protocol PlaybackRepositoryProtocol {
    /// Génère l'URL de streaming
    func getStreamURL(
        itemId: String,
        quality: StreamQuality,
        startPositionTicks: Int64,
        playSessionId: String,
        subtitleStreamIndex: Int?
    ) -> URL?

    /// Génère l'URL des sous-titres
    func getSubtitleURL(
        itemId: String,
        mediaSourceId: String,
        streamIndex: Int,
        format: String
    ) -> URL?

    /// Signale le début de lecture
    func reportPlaybackStart(
        itemId: String,
        positionTicks: Int64,
        playSessionId: String
    ) async throws

    /// Signale la progression de lecture
    func reportPlaybackProgress(
        itemId: String,
        positionTicks: Int64,
        isPaused: Bool,
        playSessionId: String
    ) async throws

    /// Signale la fin de lecture
    func reportPlaybackStopped(
        itemId: String,
        positionTicks: Int64,
        playSessionId: String
    ) async throws
}

// MARK: - Combined Repository Protocol

/// Protocole combiné pour accès simplifié (utilisé par JellyfinService)
protocol JellyfinRepositoryProtocol: MediaRepositoryProtocol, AuthRepositoryProtocol, PlaybackRepositoryProtocol {}
