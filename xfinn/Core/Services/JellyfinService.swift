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
class JellyfinService: ObservableObject {

    // MARK: - Published Properties

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var serverInfo: ServerInfo?
    @Published var preferredQuality: StreamQuality = .auto

    // MARK: - Services

    let authService = AuthService()
    private lazy var mediaService = MediaService(authService: authService)
    private lazy var playbackService = PlaybackService(authService: authService)

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

    // MARK: - Authentication (delegated to AuthService)

    @MainActor
    func connect(to serverURL: String) async throws -> ServerInfo {
        let info = try await authService.connect(to: serverURL)
        self.serverInfo = info
        return info
    }

    @MainActor
    func authenticate(username: String, password: String) async throws {
        let user = try await authService.authenticate(username: username, password: password)
        self.currentUser = user
        self.isAuthenticated = true
    }

    @MainActor
    func loadSavedCredentials() {
        guard authService.loadSavedCredentials() else { return }

        self.isAuthenticated = true

        Task {
            try? await loadCurrentUser()
        }
    }

    @MainActor
    func logout() {
        authService.logout()

        self.isAuthenticated = false
        self.currentUser = nil
        self.serverInfo = nil
    }

    @MainActor
    func loadCurrentUser() async throws {
        let user = try await authService.loadCurrentUser()
        self.currentUser = user
    }

    func registerDeviceCapabilities() async throws {
        try await authService.registerDeviceCapabilities()
    }

    // MARK: - Libraries (delegated to MediaService)

    func getLibraries() async throws -> [LibraryItem] {
        try await mediaService.getLibraries()
    }

    // MARK: - Media Items (delegated to MediaService)

    func getItems(parentId: String, includeItemTypes: [String]? = nil, recursive: Bool = false, limit: Int? = nil) async throws -> [MediaItem] {
        try await mediaService.getItems(parentId: parentId, includeItemTypes: includeItemTypes, recursive: recursive, limit: limit)
    }

    func getResumeItems(limit: Int = 12) async throws -> [MediaItem] {
        try await mediaService.getResumeItems(limit: limit)
    }

    func getLatestItems(parentId: String? = nil, limit: Int = 16) async throws -> [MediaItem] {
        try await mediaService.getLatestItems(parentId: parentId, limit: limit)
    }

    func search(query: String, includeItemTypes: [String]? = nil, limit: Int = 50) async throws -> [MediaItem] {
        try await mediaService.search(query: query, includeItemTypes: includeItemTypes, limit: limit)
    }

    func getItem(itemId: String) async throws -> MediaItem {
        try await mediaService.getItem(itemId: itemId)
    }

    func getItemDetails(itemId: String) async throws -> MediaItem {
        try await mediaService.getItemDetails(itemId: itemId)
    }

    func getNextEpisode(currentItemId: String) async throws -> MediaItem? {
        try await mediaService.getNextEpisode(currentItemId: currentItemId)
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
    func getPlaybackInfo(itemId: String, quality: StreamQuality = .auto) async throws -> PlaybackResult {
        try await playbackService.getPlaybackInfo(itemId: itemId, quality: quality)
    }

    /// Legacy: Génère directement l'URL de streaming (ne gère pas les sous-titres natifs)
    func getStreamURL(itemId: String, quality: StreamQuality = .auto, startPositionTicks: Int64 = 0, playSessionId: String, subtitleStreamIndex: Int? = nil) -> URL? {
        playbackService.getStreamURL(itemId: itemId, quality: quality, startPositionTicks: startPositionTicks, playSessionId: playSessionId, subtitleStreamIndex: subtitleStreamIndex)
    }

    func getSubtitleURL(itemId: String, mediaSourceId: String, streamIndex: Int, format: String = "vtt") -> URL? {
        playbackService.getSubtitleURL(itemId: itemId, mediaSourceId: mediaSourceId, streamIndex: streamIndex, format: format)
    }

    // MARK: - Playback Reporting (delegated to PlaybackService)

    func reportPlaybackStart(itemId: String, positionTicks: Int64 = 0, playSessionId: String) async throws {
        try await playbackService.reportPlaybackStart(itemId: itemId, positionTicks: positionTicks, playSessionId: playSessionId)
    }

    func reportPlaybackProgress(itemId: String, positionTicks: Int64, isPaused: Bool = false, playSessionId: String) async throws {
        try await playbackService.reportPlaybackProgress(itemId: itemId, positionTicks: positionTicks, isPaused: isPaused, playSessionId: playSessionId)
    }

    func reportPlaybackStopped(itemId: String, positionTicks: Int64, playSessionId: String) async throws {
        try await playbackService.reportPlaybackStopped(itemId: itemId, positionTicks: positionTicks, playSessionId: playSessionId)
    }
}

// MARK: - URLRequest Extensions

extension URLRequest {
    /// Ajoute les en-têtes Jellyfin standards
    mutating func addJellyfinHeaders(clientName: String, deviceId: String, version: String) {
        let authHeader = "MediaBrowser Client=\"\(clientName)\", Device=\"Apple TV\", DeviceId=\"\(deviceId)\", Version=\"\(version)\""
        addValue(authHeader, forHTTPHeaderField: "X-Emby-Authorization")
    }

    /// Ajoute les en-têtes d'autorisation avec token
    mutating func addAuthorizationHeader(token: String, clientName: String, deviceId: String, version: String) {
        let authHeader = "MediaBrowser Client=\"\(clientName)\", Device=\"Apple TV\", DeviceId=\"\(deviceId)\", Version=\"\(version)\", Token=\"\(token)\""
        addValue(authHeader, forHTTPHeaderField: "X-Emby-Authorization")
    }
}

// MARK: - Errors

enum JellyfinError: LocalizedError {
    case connectionFailed
    case authenticationFailed
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
