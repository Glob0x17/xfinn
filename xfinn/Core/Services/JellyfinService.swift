//
//  JellyfinService.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import Foundation
import SwiftUI
import Combine

/// Service principal pour gérer toutes les interactions avec l'API Jellyfin
class JellyfinService: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var serverInfo: ServerInfo?
    @Published var preferredQuality: StreamQuality = .auto
    
    // MARK: - Private Properties
    
    private var baseURL: String = ""
    private var accessToken: String = ""
    private var userId: String = ""
    private let deviceId: String
    private let clientName = "xfinn"
    private let clientVersion = "1.0.0"
    
    // MARK: - Public Computed Properties
    
    /// URL du serveur Jellyfin (lecture seule)
    var serverURL: String {
        return baseURL
    }
    
    // MARK: - Initialization
    
    private var qualityCancellable: AnyCancellable?
    
    init() {
        self.deviceId = UserDefaults.standard.deviceId
        
        // Charger la qualité préférée depuis UserDefaults
        if let savedQuality = UserDefaults.standard.string(forKey: "preferredStreamQuality"),
           let quality = StreamQuality(rawValue: savedQuality) {
            self._preferredQuality = Published(initialValue: quality)
        }
        
        loadSavedCredentials()
        
        // Observer les changements de qualité pour les sauvegarder automatiquement
        setupQualityObserver()
    }
    
    private func setupQualityObserver() {
        qualityCancellable = $preferredQuality
            .dropFirst() // Ignorer la valeur initiale
            .sink { newQuality in
                UserDefaults.standard.set(newQuality.rawValue, forKey: "preferredStreamQuality")
            }
    }
    
    // MARK: - Authentication
    
    /// Se connecte au serveur Jellyfin et récupère les informations
    @MainActor
    func connect(to serverURL: String) async throws -> ServerInfo {
        self.baseURL = serverURL

        guard let url = URL(string: "\(baseURL)/System/Info/Public") else {
            throw JellyfinError.invalidURL
        }
        var request = URLRequest(url: url)
        request.addJellyfinHeaders(clientName: clientName, deviceId: deviceId, version: clientVersion)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw JellyfinError.connectionFailed
        }
        
        let serverInfo = try JSONDecoder().decode(ServerInfo.self, from: data)
        self.serverInfo = serverInfo
        
        return serverInfo
    }
    
    /// Authentifie l'utilisateur avec son nom d'utilisateur et mot de passe
    @MainActor
    func authenticate(username: String, password: String) async throws {
        guard let url = URL(string: "\(baseURL)/Users/AuthenticateByName") else {
            throw JellyfinError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addJellyfinHeaders(clientName: clientName, deviceId: deviceId, version: clientVersion)
        
        let authBody: [String: Any] = [
            "Username": username,
            "Pw": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: authBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw JellyfinError.authenticationFailed
        }
        
        let authResult = try JSONDecoder().decode(AuthenticationResult.self, from: data)
        
        self.accessToken = authResult.accessToken
        self.userId = authResult.user.id
        self.currentUser = authResult.user
        self.isAuthenticated = true
        
        saveCredentials()
    }
    
    /// Charge les identifiants sauvegardés depuis UserDefaults
    @MainActor
    func loadSavedCredentials() {
        guard let savedURL = UserDefaults.standard.jellyfinServerURL,
              let savedToken = UserDefaults.standard.jellyfinAccessToken,
              let savedUserId = UserDefaults.standard.jellyfinUserId else {
            return
        }
        
        self.baseURL = savedURL
        self.accessToken = savedToken
        self.userId = savedUserId
        self.isAuthenticated = true
        
        // Charger les informations utilisateur en arrière-plan
        Task {
            try? await loadCurrentUser()
        }
    }
    
    /// Sauvegarde les identifiants dans UserDefaults
    private func saveCredentials() {
        UserDefaults.standard.jellyfinServerURL = baseURL
        UserDefaults.standard.jellyfinAccessToken = accessToken
        UserDefaults.standard.jellyfinUserId = userId
    }
    
    /// Déconnecte l'utilisateur et efface les données sauvegardées
    @MainActor
    func logout() {
        UserDefaults.standard.clearJellyfinData()
        
        self.isAuthenticated = false
        self.currentUser = nil
        self.serverInfo = nil
        self.accessToken = ""
        self.userId = ""
        self.baseURL = ""
    }
    
    // MARK: - User Management
    
    /// Charge les informations de l'utilisateur actuel
    @MainActor
    func loadCurrentUser() async throws {
        guard let url = URL(string: "\(baseURL)/Users/\(userId)") else {
            throw JellyfinError.invalidURL
        }
        var request = URLRequest(url: url)
        request.addAuthorizationHeader(token: accessToken, clientName: clientName, deviceId: deviceId, version: clientVersion)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let user = try JSONDecoder().decode(User.self, from: data)
        self.currentUser = user
    }
    
    // MARK: - Libraries
    
    /// Récupère toutes les bibliothèques de l'utilisateur
    func getLibraries() async throws -> [LibraryItem] {
        guard let url = URL(string: "\(baseURL)/Users/\(userId)/Views") else {
            throw JellyfinError.invalidURL
        }
        var request = URLRequest(url: url)
        request.addAuthorizationHeader(token: accessToken, clientName: clientName, deviceId: deviceId, version: clientVersion)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ItemsResponse.self, from: data)
        
        // Ajouter les URLs d'image aux bibliothèques
        return response.items.map { item in
            LibraryItem(
                id: item.id,
                name: item.name,
                collectionType: item.type,
                imageUrl: getPrimaryImageURL(itemId: item.id)
            )
        }
    }
    
    // MARK: - Media Items
    
    /// Récupère les médias d'une bibliothèque ou d'un parent
    func getItems(parentId: String, includeItemTypes: [String]? = nil, recursive: Bool = false, limit: Int? = nil) async throws -> [MediaItem] {
        guard var urlComponents = URLComponents(string: "\(baseURL)/Users/\(userId)/Items") else {
            throw JellyfinError.invalidURL
        }

        var queryItems = [
            URLQueryItem(name: "ParentId", value: parentId),
            URLQueryItem(name: "Fields", value: "Overview,PrimaryImageAspectRatio,MediaStreams"),
            URLQueryItem(name: "SortBy", value: "SortName"),
            URLQueryItem(name: "SortOrder", value: "Ascending")
        ]

        if let types = includeItemTypes {
            queryItems.append(URLQueryItem(name: "IncludeItemTypes", value: types.joined(separator: ",")))
        }

        if recursive {
            queryItems.append(URLQueryItem(name: "Recursive", value: "true"))
        }

        if let limit = limit {
            queryItems.append(URLQueryItem(name: "Limit", value: "\(limit)"))
        }

        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw JellyfinError.invalidURL
        }
        var request = URLRequest(url: url)
        request.addAuthorizationHeader(token: accessToken, clientName: clientName, deviceId: deviceId, version: clientVersion)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ItemsResponse.self, from: data)
        
        return response.items
    }
    
    /// Récupère les médias en cours de lecture
    func getResumeItems(limit: Int = 12) async throws -> [MediaItem] {
        guard var urlComponents = URLComponents(string: "\(baseURL)/Users/\(userId)/Items/Resume") else {
            throw JellyfinError.invalidURL
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "Limit", value: "\(limit)"),
            URLQueryItem(name: "Fields", value: "Overview,PrimaryImageAspectRatio,MediaStreams"),
            URLQueryItem(name: "MediaTypes", value: "Video")
        ]

        guard let url = urlComponents.url else {
            throw JellyfinError.invalidURL
        }
        var request = URLRequest(url: url)
        request.addAuthorizationHeader(token: accessToken, clientName: clientName, deviceId: deviceId, version: clientVersion)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ItemsResponse.self, from: data)
        
        return response.items
    }
    
    /// Récupère les médias récemment ajoutés
    func getLatestItems(parentId: String? = nil, limit: Int = 16) async throws -> [MediaItem] {
        guard var urlComponents = URLComponents(string: "\(baseURL)/Users/\(userId)/Items/Latest") else {
            throw JellyfinError.invalidURL
        }

        if let parentId = parentId {
            urlComponents.queryItems = [
                URLQueryItem(name: "ParentId", value: parentId),
                URLQueryItem(name: "Limit", value: "\(limit)"),
                URLQueryItem(name: "Fields", value: "Overview,PrimaryImageAspectRatio,MediaStreams")
            ]
        } else {
            urlComponents.queryItems = [
                URLQueryItem(name: "Limit", value: "\(limit)"),
                URLQueryItem(name: "Fields", value: "Overview,PrimaryImageAspectRatio,MediaStreams")
            ]
        }

        guard let url = urlComponents.url else {
            throw JellyfinError.invalidURL
        }
        var request = URLRequest(url: url)
        request.addAuthorizationHeader(token: accessToken, clientName: clientName, deviceId: deviceId, version: clientVersion)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // L'endpoint Latest retourne un tableau direct, pas un ItemsResponse
        let items = try JSONDecoder().decode([MediaItem].self, from: data)
        
        return items
    }
    
    /// Recherche des médias par mots-clés
    func search(query: String, includeItemTypes: [String]? = nil, limit: Int = 50) async throws -> [MediaItem] {
        guard !query.isEmpty else { return [] }

        guard var urlComponents = URLComponents(string: "\(baseURL)/Users/\(userId)/Items") else {
            throw JellyfinError.invalidURL
        }

        var queryItems = [
            URLQueryItem(name: "searchTerm", value: query),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "Limit", value: "\(limit)"),
            URLQueryItem(name: "Fields", value: "PrimaryImageAspectRatio,UserData,Overview,MediaStreams"),
            URLQueryItem(name: "SortBy", value: "SortName"),
            URLQueryItem(name: "SortOrder", value: "Ascending")
        ]

        // Filtrer par types si spécifié
        if let types = includeItemTypes, !types.isEmpty {
            queryItems.append(URLQueryItem(name: "IncludeItemTypes", value: types.joined(separator: ",")))
        } else {
            // Par défaut : rechercher Movies, Series et Episodes
            queryItems.append(URLQueryItem(name: "IncludeItemTypes", value: "Movie,Series,Episode"))
        }

        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw JellyfinError.invalidURL
        }
        var request = URLRequest(url: url)
        request.addAuthorizationHeader(token: accessToken, clientName: clientName, deviceId: deviceId, version: clientVersion)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ItemsResponse.self, from: data)
        return response.items
    }
    
    /// Récupère les détails d'un média spécifique
    func getItem(itemId: String) async throws -> MediaItem {
        guard var urlComponents = URLComponents(string: "\(baseURL)/Users/\(userId)/Items/\(itemId)") else {
            throw JellyfinError.invalidURL
        }

        // IMPORTANT: Demander les MediaStreams pour avoir les sous-titres et pistes audio
        urlComponents.queryItems = [
            URLQueryItem(name: "Fields", value: "Overview,MediaStreams")
        ]

        guard let url = urlComponents.url else {
            throw JellyfinError.invalidURL
        }
        var request = URLRequest(url: url)
        request.addAuthorizationHeader(token: accessToken, clientName: clientName, deviceId: deviceId, version: clientVersion)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let item = try JSONDecoder().decode(MediaItem.self, from: data)
        
        return item
    }
    
    /// Récupère les détails d'un média spécifique (alias de getItem)
    func getItemDetails(itemId: String) async throws -> MediaItem {
        return try await getItem(itemId: itemId)
    }
    
    /// Récupère l'épisode suivant d'une série
    func getNextEpisode(currentItemId: String) async throws -> MediaItem? {
        // D'abord, récupérer les détails de l'épisode actuel
        let currentItem = try await getItem(itemId: currentItemId)
        
        // Vérifier que c'est un épisode
        guard currentItem.type == "Episode",
              let seriesId = currentItem.seriesId else {
            return nil
        }
        
        // Récupérer tous les épisodes de la série
        guard var urlComponents = URLComponents(string: "\(baseURL)/Shows/\(seriesId)/Episodes") else {
            throw JellyfinError.invalidURL
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "UserId", value: userId),
            URLQueryItem(name: "Fields", value: "Overview,PrimaryImageAspectRatio,MediaStreams")
        ]

        guard let url = urlComponents.url else {
            throw JellyfinError.invalidURL
        }
        var request = URLRequest(url: url)
        request.addAuthorizationHeader(token: accessToken, clientName: clientName, deviceId: deviceId, version: clientVersion)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ItemsResponse.self, from: data)
        
        // Trouver l'épisode suivant
        let episodes = response.items.sorted { lhs, rhs in
            if lhs.parentIndexNumber == rhs.parentIndexNumber {
                return (lhs.indexNumber ?? 0) < (rhs.indexNumber ?? 0)
            }
            return (lhs.parentIndexNumber ?? 0) < (rhs.parentIndexNumber ?? 0)
        }
        
        // Trouver l'index de l'épisode actuel
        guard let currentIndex = episodes.firstIndex(where: { $0.id == currentItemId }) else {
            return nil
        }
        
        // Retourner l'épisode suivant s'il existe
        let nextIndex = currentIndex + 1
        if nextIndex < episodes.count {
            return episodes[nextIndex]
        }
        
        return nil
    }
    
    // MARK: - Images
    
    /// Génère l'URL de l'image d'un média avec type spécifique
    func getImageURL(itemId: String, imageType: String = "Primary", maxWidth: Int = 400) -> String {
        return "\(baseURL)/Items/\(itemId)/Images/\(imageType)?maxWidth=\(maxWidth)"
    }
    
    /// Génère l'URL de l'image principale d'un média
    func getPrimaryImageURL(itemId: String, maxWidth: Int = 400) -> String {
        return "\(baseURL)/Items/\(itemId)/Images/Primary?maxWidth=\(maxWidth)"
    }
    
    /// Génère l'URL de l'image backdrop d'un média
    func getBackdropImageURL(itemId: String, maxWidth: Int = 1920) -> String {
        return "\(baseURL)/Items/\(itemId)/Images/Backdrop?maxWidth=\(maxWidth)"
    }
    
    // MARK: - Streaming
    
    /// Génère l'URL de streaming HLS pour un média (compatible tvOS)
    func getStreamURL(itemId: String, quality: StreamQuality = .auto, startPositionTicks: Int64 = 0, playSessionId: String, subtitleStreamIndex: Int? = nil) -> URL? {
        // Utiliser le endpoint master.m3u8 pour HLS au lieu du streaming direct
        var urlComponents = URLComponents(string: "\(baseURL)/Videos/\(itemId)/master.m3u8")!
        
        var queryItems = [
            URLQueryItem(name: "MediaSourceId", value: itemId),
            URLQueryItem(name: "DeviceId", value: deviceId),
            URLQueryItem(name: "api_key", value: accessToken),
            URLQueryItem(name: "PlaySessionId", value: playSessionId),
            URLQueryItem(name: "VideoCodec", value: "h264"),
            URLQueryItem(name: "AudioCodec", value: "aac"),
            URLQueryItem(name: "TranscodingContainer", value: "ts"),
            URLQueryItem(name: "TranscodingProtocol", value: "hls")
        ]
        
        // Ajouter les paramètres de qualité
        // Si Auto ou Original, utiliser des valeurs élevées pour avoir la meilleure qualité
        let effectiveBitrate = quality.maxBitrate ?? 15_000_000 // 15 Mbps par défaut pour Auto/Original
        let effectiveMaxWidth = quality.maxWidth ?? 1920 // 1080p par défaut
        
        queryItems.append(URLQueryItem(name: "MaxStreamingBitrate", value: "\(effectiveBitrate)"))
        queryItems.append(URLQueryItem(name: "VideoBitrate", value: "\(effectiveBitrate)"))
        queryItems.append(URLQueryItem(name: "AudioBitrate", value: "192000")) // 192 kbps pour l'audio
        queryItems.append(URLQueryItem(name: "MaxWidth", value: "\(effectiveMaxWidth)"))
        queryItems.append(URLQueryItem(name: "MaxHeight", value: "1080")) // Hauteur maximale en 1080p
        
        if startPositionTicks > 0 {
            queryItems.append(URLQueryItem(name: "StartTimeTicks", value: "\(startPositionTicks)"))
        }
        
        // 🔥 Configuration des sous-titres
        if let subtitleIndex = subtitleStreamIndex {
            // Utiliser le burn-in (encodage dans la vidéo)
            queryItems.append(URLQueryItem(name: "SubtitleStreamIndex", value: "\(subtitleIndex)"))
            queryItems.append(URLQueryItem(name: "SubtitleMethod", value: "Encode"))
            queryItems.append(URLQueryItem(name: "SubtitleCodec", value: ""))
        } else {
            queryItems.append(URLQueryItem(name: "SubtitleStreamIndex", value: "-1"))
            queryItems.append(URLQueryItem(name: "SubtitleCodec", value: ""))
        }
        
        // Paramètres supplémentaires pour tvOS
        queryItems.append(contentsOf: [
            URLQueryItem(name: "SegmentContainer", value: "ts"),
            URLQueryItem(name: "MinSegments", value: "2"),
            URLQueryItem(name: "BreakOnNonKeyFrames", value: "true"),
            URLQueryItem(name: "h264-profile", value: "high,main,baseline,constrained baseline"),
            URLQueryItem(name: "h264-level", value: "51"),
            URLQueryItem(name: "TranscodeReasons", value: "VideoCodecNotSupported,AudioCodecNotSupported")
        ])
        
        urlComponents.queryItems = queryItems
        
        return urlComponents.url
    }
    
    /// Génère l'URL pour récupérer un sous-titre spécifique
    func getSubtitleURL(itemId: String, mediaSourceId: String, streamIndex: Int, format: String = "vtt") -> URL? {
        let urlString = "\(baseURL)/Videos/\(itemId)/\(mediaSourceId)/Subtitles/\(streamIndex)/Stream.\(format)"
        var urlComponents = URLComponents(string: urlString)!
        
        urlComponents.queryItems = [
            URLQueryItem(name: "api_key", value: accessToken)
        ]
        
        return urlComponents.url
    }
    
    // MARK: - Device Capabilities
    
    /// Enregistre les capacités du device auprès du serveur
    func registerDeviceCapabilities() async throws {
        guard let url = URL(string: "\(baseURL)/Sessions/Capabilities/Full") else {
            throw JellyfinError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addAuthorizationHeader(token: accessToken, clientName: clientName, deviceId: deviceId, version: clientVersion)
        
        let capabilities: [String: Any] = [
            "PlayableMediaTypes": ["Video", "Audio"],
            "SupportedCommands": [
                "Play",
                "Playstate",
                "PlayNext",
                "PlayMediaSource"
            ],
            "SupportsMediaControl": true,
            "SupportsPersistentIdentifier": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: capabilities)
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }
    
    // MARK: - Playback Reporting
    
    /// Signale le début de la lecture
    func reportPlaybackStart(itemId: String, positionTicks: Int64 = 0, playSessionId: String) async throws {
        guard let url = URL(string: "\(baseURL)/Sessions/Playing") else {
            throw JellyfinError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addAuthorizationHeader(token: accessToken, clientName: clientName, deviceId: deviceId, version: clientVersion)
        
        let body: [String: Any] = [
            "ItemId": itemId,
            "PositionTicks": positionTicks,
            "PlayMethod": "DirectStream",
            "CanSeek": true,
            "PlaySessionId": playSessionId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }
    
    /// Signale la progression de la lecture
    func reportPlaybackProgress(itemId: String, positionTicks: Int64, isPaused: Bool = false, playSessionId: String) async throws {
        guard let url = URL(string: "\(baseURL)/Sessions/Playing/Progress") else {
            throw JellyfinError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addAuthorizationHeader(token: accessToken, clientName: clientName, deviceId: deviceId, version: clientVersion)
        
        let body: [String: Any] = [
            "ItemId": itemId,
            "PositionTicks": positionTicks,
            "IsPaused": isPaused,
            "PlayMethod": "DirectStream",
            "CanSeek": true,
            "PlaySessionId": playSessionId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }
    
    /// Signale l'arrêt de la lecture
    func reportPlaybackStopped(itemId: String, positionTicks: Int64, playSessionId: String) async throws {
        guard let url = URL(string: "\(baseURL)/Sessions/Playing/Stopped") else {
            throw JellyfinError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addAuthorizationHeader(token: accessToken, clientName: clientName, deviceId: deviceId, version: clientVersion)
        
        let body: [String: Any] = [
            "ItemId": itemId,
            "PositionTicks": positionTicks,
            "PlayMethod": "DirectStream",
            "PlaySessionId": playSessionId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, _) = try await URLSession.shared.data(for: request)
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
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Impossible de se connecter au serveur. Vérifiez l'URL et votre connexion réseau."
        case .authenticationFailed:
            return "Échec de l'authentification. Vérifiez vos identifiants."
        case .invalidURL:
            return "L'URL fournie est invalide."
        case .networkError(let error):
            return "Erreur réseau : \(error.localizedDescription)"
        case .decodingError(let error):
            return "Erreur de décodage des données : \(error.localizedDescription)"
        case .serverError(let statusCode):
            return "Erreur serveur (code \(statusCode))"
        }
    }
}
