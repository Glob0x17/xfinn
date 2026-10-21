//
//  JellyfinService.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//  Refactored on 05/01/2026: Facade pattern with specialized services
//

import Foundation
import SwiftUI
import Combine

/// Service principal Jellyfin - Facade coordonnant les services spécialisés
@MainActor
class JellyfinService: ObservableObject {

    // MARK: - Published Properties

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var serverInfo: ServerInfo?
    @Published var preferredQuality: StreamQuality = .auto

    /// UserData mis à jour localement (marquer vu/favori) : les MediaItem sont
    /// immuables et les listes déjà chargées ne sont pas re-fetchées, donc les
    /// cartes lisent effectiveUserData(for:) pour refléter le changement partout
    @Published private(set) var userDataOverrides: [String: UserData] = [:]

    // MARK: - Services

    let authService = AuthService()
    private lazy var mediaService = MediaService(authService: authService)
    private lazy var playbackService = PlaybackService(authService: authService)
    let playerManager = PlayerManager()

    // MARK: - Private Properties

    private var qualityCancellable: AnyCancellable?

    // MARK: - Public Computed Properties

    var serverURL: String {
        authService.serverURL
    }

    var accessToken: String {
        authService.accessToken
    }

    // MARK: - Initialization

    init() {
        // Charger la qualité préférée depuis UserDefaults
        self._preferredQuality = Published(initialValue: StreamQuality.load())

        loadSavedCredentials()
        setupQualityObserver()
    }

    private func setupQualityObserver() {
        qualityCancellable = $preferredQuality
            .dropFirst()
            .sink { newQuality in
                newQuality.save()
            }
    }

    // MARK: - Session Expiration Handling

    /// Exécute une opération et déconnecte l'utilisateur si le serveur signale
    /// un token invalide/révoqué (401), pour ne pas rester bloqué en état
    /// "authentifié" cassé
    private func withAuthErrorHandling<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch JellyfinError.authenticationFailed {
            handleSessionExpired()
            throw JellyfinError.authenticationFailed
        }
    }

    /// Invalide la session locale suite à un rejet du token par le serveur
    private func handleSessionExpired() {
        guard isAuthenticated else { return }
        #if DEBUG
        print("[JellyfinService] Session expired (401) - logging out")
        #endif
        logout()
    }

    // MARK: - Authentication (delegated to AuthService)

    func connect(to serverURL: String) async throws -> ServerInfo {
        let info = try await authService.connect(to: serverURL)
        self.serverInfo = info
        return info
    }

    func authenticate(username: String, password: String) async throws {
        let user = try await authService.authenticate(username: username, password: password)
        self.currentUser = user
        self.isAuthenticated = true
    }

    func loadSavedCredentials() {
        guard authService.loadSavedCredentials() else { return }

        self.isAuthenticated = true

        // Valider le token au démarrage : s'il a été révoqué côté serveur,
        // revenir à l'écran de connexion au lieu de rester bloqué
        Task {
            do {
                try await loadCurrentUser()
            } catch JellyfinError.authenticationFailed {
                handleSessionExpired()
            } catch {
                // Erreur réseau/serveur : on garde la session, l'utilisateur
                // pourra réessayer sans se réauthentifier
            }
        }
    }

    func logout() {
        // Purge défensive des mots de passe stockés par d'anciennes versions
        KeychainService.shared.purgeStoredPasswords(
            forServers: RecentServersService.shared.getRecentServers().map { $0.url }
        )

        authService.logout()

        self.isAuthenticated = false
        self.currentUser = nil
        self.serverInfo = nil
        self.hasRegisteredCapabilities = false
        self.userDataOverrides = [:]
    }

    func loadCurrentUser() async throws {
        let user = try await authService.loadCurrentUser()
        self.currentUser = user
    }

    // MARK: - Quick Connect (delegated to AuthService)
    // Volontairement SANS withAuthErrorHandling, comme connect/authenticate :
    // les erreurs de polling ne doivent pas déclencher la déconnexion globale

    func isQuickConnectEnabled() async -> Bool {
        await authService.isQuickConnectEnabled()
    }

    func initiateQuickConnect() async throws -> QuickConnectResult {
        try await authService.initiateQuickConnect()
    }

    func checkQuickConnect(secret: String) async throws -> Bool {
        try await authService.checkQuickConnect(secret: secret)
    }

    func authenticateWithQuickConnect(secret: String) async throws {
        let user = try await authService.authenticateWithQuickConnect(secret: secret)
        self.currentUser = user
        self.isAuthenticated = true
    }

    /// Enregistre les capacités du device — une seule fois par session
    /// (était rejoué avant chaque lecture : aller-retour réseau inutile)
    private var hasRegisteredCapabilities = false

    func registerDeviceCapabilities() async throws {
        guard !hasRegisteredCapabilities else { return }
        try await withAuthErrorHandling {
            try await authService.registerDeviceCapabilities()
        }
        hasRegisteredCapabilities = true
    }

    // MARK: - Libraries (delegated to MediaService)

    func getLibraries() async throws -> [LibraryItem] {
        try await withAuthErrorHandling {
            try await mediaService.getLibraries()
        }
    }

    // MARK: - Media Items (delegated to MediaService)

    func getItems(parentId: String, includeItemTypes: [String]? = nil, recursive: Bool = false, limit: Int? = nil) async throws -> [MediaItem] {
        try await withAuthErrorHandling {
            try await mediaService.getItems(parentId: parentId, includeItemTypes: includeItemTypes, recursive: recursive, limit: limit)
        }
    }

    func getItemsPage(
        parentId: String,
        sortBy: LibrarySortOption,
        unwatchedOnly: Bool,
        startIndex: Int,
        limit: Int
    ) async throws -> MediaService.ItemsPage {
        try await withAuthErrorHandling {
            try await mediaService.getItemsPage(
                parentId: parentId,
                sortBy: sortBy,
                unwatchedOnly: unwatchedOnly,
                startIndex: startIndex,
                limit: limit
            )
        }
    }

    func getResumeItems(limit: Int = 12) async throws -> [MediaItem] {
        try await withAuthErrorHandling {
            try await mediaService.getResumeItems(limit: limit)
        }
    }

    func getLatestItems(parentId: String? = nil, limit: Int = 16) async throws -> [MediaItem] {
        try await withAuthErrorHandling {
            try await mediaService.getLatestItems(parentId: parentId, limit: limit)
        }
    }

    func search(query: String, includeItemTypes: [String]? = nil, limit: Int = 50) async throws -> [MediaItem] {
        try await withAuthErrorHandling {
            try await mediaService.search(query: query, includeItemTypes: includeItemTypes, limit: limit)
        }
    }

    func getItem(itemId: String) async throws -> MediaItem {
        try await withAuthErrorHandling {
            try await mediaService.getItem(itemId: itemId)
        }
    }

    func getItemDetails(itemId: String) async throws -> MediaItem {
        try await withAuthErrorHandling {
            try await mediaService.getItemDetails(itemId: itemId)
        }
    }

    func getNextEpisode(currentItemId: String) async throws -> MediaItem? {
        try await withAuthErrorHandling {
            try await mediaService.getNextEpisode(currentItemId: currentItemId)
        }
    }

    // MARK: - Watched / Favorites

    /// UserData effectif d'un item : override local s'il existe, sinon celui
    /// embarqué dans l'item au moment de son chargement
    func effectiveUserData(for item: MediaItem) -> UserData? {
        userDataOverrides[item.id] ?? item.userData
    }

    func setPlayed(itemId: String, played: Bool) async throws {
        let updated = try await withAuthErrorHandling {
            try await mediaService.setPlayed(itemId: itemId, played: played)
        }
        userDataOverrides[itemId] = updated
    }

    func setFavorite(itemId: String, favorite: Bool) async throws {
        let updated = try await withAuthErrorHandling {
            try await mediaService.setFavorite(itemId: itemId, favorite: favorite)
        }
        userDataOverrides[itemId] = updated
    }

    func getFavoriteItems(limit: Int = 10) async throws -> [MediaItem] {
        try await withAuthErrorHandling {
            try await mediaService.getFavoriteItems(limit: limit)
        }
    }

    // MARK: - Music Items (delegated to MediaService)

    func getMusicArtists(parentId: String, limit: Int? = nil) async throws -> [MediaItem] {
        try await withAuthErrorHandling {
            try await mediaService.getMusicArtists(parentId: parentId, limit: limit)
        }
    }

    func getArtistAlbums(artistId: String) async throws -> [MediaItem] {
        try await withAuthErrorHandling {
            try await mediaService.getArtistAlbums(artistId: artistId)
        }
    }

    func getAlbumTracks(albumId: String) async throws -> [MediaItem] {
        try await withAuthErrorHandling {
            try await mediaService.getAlbumTracks(albumId: albumId)
        }
    }

    func getLatestAlbums(parentId: String, limit: Int = 16) async throws -> [MediaItem] {
        try await withAuthErrorHandling {
            try await mediaService.getLatestAlbums(parentId: parentId, limit: limit)
        }
    }

    // MARK: - Images (delegated to MediaService)

    func getImageURL(itemId: String, imageType: String = "Primary", maxWidth: Int = 400) -> String {
        mediaService.getImageURL(itemId: itemId, imageType: imageType, maxWidth: maxWidth)
    }

    func getPrimaryImageURL(itemId: String, maxWidth: Int = 400) -> String {
        mediaService.getPrimaryImageURL(itemId: itemId, maxWidth: maxWidth)
    }

    func getBackdropImageURL(itemId: String, maxWidth: Int = 1920) -> String {
        mediaService.getBackdropImageURL(itemId: itemId, maxWidth: maxWidth)
    }

    // MARK: - Streaming (delegated to PlaybackService)

    /// Obtient les informations de lecture via l'API PlaybackInfo avec DeviceProfile
    /// C'est la méthode recommandée car elle gère les sous-titres nativement via HLS
    func getPlaybackInfo(itemId: String, quality: StreamQuality = .auto, audioStreamIndex: Int? = nil, subtitleStreamIndex: Int? = nil, forceAudioTranscode: Bool = false, allowDirectPlay: Bool = true, burnInSubtitles: Bool = false, requireStream: Bool = false) async throws -> PlaybackResult {
        try await withAuthErrorHandling {
            try await playbackService.getPlaybackInfo(itemId: itemId, quality: quality, audioStreamIndex: audioStreamIndex, subtitleStreamIndex: subtitleStreamIndex, forceAudioTranscode: forceAudioTranscode, allowDirectPlay: allowDirectPlay, burnInSubtitles: burnInSubtitles, requireStream: requireStream)
        }
    }

    /// Legacy: Génère directement l'URL de streaming (ne gère pas les sous-titres natifs)
    func getStreamURL(itemId: String, quality: StreamQuality = .auto, startPositionTicks: Int64 = 0, playSessionId: String, subtitleStreamIndex: Int? = nil) -> URL? {
        playbackService.getStreamURL(itemId: itemId, quality: quality, startPositionTicks: startPositionTicks, playSessionId: playSessionId, subtitleStreamIndex: subtitleStreamIndex)
    }

    func getSubtitleURL(itemId: String, mediaSourceId: String, streamIndex: Int, format: String = "vtt") -> URL? {
        playbackService.getSubtitleURL(itemId: itemId, mediaSourceId: mediaSourceId, streamIndex: streamIndex, format: format)
    }

    /// Segments (intro/générique/récap) d'un média — vide si non disponibles
    func getMediaSegments(itemId: String) async throws -> [MediaSegment] {
        try await withAuthErrorHandling {
            try await playbackService.getMediaSegments(itemId: itemId)
        }
    }

    // MARK: - Playback Reporting (delegated to PlaybackService)

    func reportPlaybackStart(itemId: String, positionTicks: Int64 = 0, playSessionId: String, playMethod: String = "DirectStream") async throws {
        try await withAuthErrorHandling {
            try await playbackService.reportPlaybackStart(itemId: itemId, positionTicks: positionTicks, playSessionId: playSessionId, playMethod: playMethod)
        }
    }

    func reportPlaybackProgress(itemId: String, positionTicks: Int64, isPaused: Bool = false, playSessionId: String, playMethod: String = "DirectStream") async throws {
        try await withAuthErrorHandling {
            try await playbackService.reportPlaybackProgress(itemId: itemId, positionTicks: positionTicks, isPaused: isPaused, playSessionId: playSessionId, playMethod: playMethod)
        }
    }

    func reportPlaybackStopped(itemId: String, positionTicks: Int64, playSessionId: String, playMethod: String = "DirectStream") async throws {
        try await withAuthErrorHandling {
            try await playbackService.reportPlaybackStopped(itemId: itemId, positionTicks: positionTicks, playSessionId: playSessionId, playMethod: playMethod)
        }
    }

    func stopActiveEncodings(playSessionId: String) async throws {
        try await withAuthErrorHandling {
            try await playbackService.stopActiveEncodings(playSessionId: playSessionId)
        }
    }
}

// MARK: - URLRequest Extensions

extension URLRequest {
    /// Ajoute les en-têtes Jellyfin standards
    /// Jellyfin 12 ne parse plus X-Emby-Authorization : le schéma MediaBrowser
    /// doit passer par l'en-tête HTTP standard Authorization
    mutating func addJellyfinHeaders(clientName: String, deviceId: String, version: String) {
        let authHeader = "MediaBrowser Client=\"\(clientName)\", Device=\"Apple TV\", DeviceId=\"\(deviceId)\", Version=\"\(version)\""
        addValue(authHeader, forHTTPHeaderField: "Authorization")
    }

    /// Ajoute les en-têtes d'autorisation avec token
    mutating func addAuthorizationHeader(token: String, clientName: String, deviceId: String, version: String) {
        let authHeader = "MediaBrowser Client=\"\(clientName)\", Device=\"Apple TV\", DeviceId=\"\(deviceId)\", Version=\"\(version)\", Token=\"\(token)\""
        addValue(authHeader, forHTTPHeaderField: "Authorization")
    }
}

// MARK: - HTTP Response Validation

extension URLResponse {
    /// Valide une réponse HTTP Jellyfin (2xx), sinon lève un JellyfinError.
    /// Sémantique partagée par tous les services :
    /// - 401 = token invalide/révoqué → authenticationFailed (déclenche le
    ///   logout automatique via JellyfinService)
    /// - 403 = permissions insuffisantes sur la ressource (ex: contrôle
    ///   parental) → erreur simple, ne doit PAS invalider la session
    func validateJellyfinResponse() throws {
        guard let httpResponse = self as? HTTPURLResponse else {
            throw JellyfinError.responseError("Invalid response type")
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw JellyfinError.authenticationFailed
        case 403:
            throw JellyfinError.responseError("Access denied (403)")
        case 404:
            throw JellyfinError.responseError("Resource not found")
        case 500...599:
            throw JellyfinError.responseError("Server error (\(httpResponse.statusCode))")
        default:
            throw JellyfinError.responseError("HTTP error \(httpResponse.statusCode)")
        }
    }
}

// MARK: - Errors

enum JellyfinError: LocalizedError {
    case connectionFailed
    case authenticationFailed
    case quickConnectExpired
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(statusCode: Int)
    case responseError(String)

    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "error.connection_failed".localized
        case .authenticationFailed:
            return "error.auth_failed".localized
        case .quickConnectExpired:
            return "error.quick_connect_expired".localized
        case .invalidURL:
            return "error.invalid_url".localized
        case .networkError(let error):
            return "error.network".localized(with: error.localizedDescription)
        case .decodingError(let error):
            return "error.decoding".localized(with: error.localizedDescription)
        case .serverError(let statusCode):
            return "error.server".localized(with: statusCode)
        case .responseError(let message):
            return "error.response".localized(with: message)
        }
    }
}
