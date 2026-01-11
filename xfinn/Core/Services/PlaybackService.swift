//
//  PlaybackService.swift
//  xfinn
//
//  Jellyfin playback service with DeviceProfile support.
//

import Foundation

/// Résultat de la requête PlaybackInfo
struct PlaybackResult {
    let streamURL: URL
    let playSessionId: String
    let mediaSource: MediaSourceInfo
    let isTranscoding: Bool
}

/// Service de gestion de la lecture Jellyfin
final class PlaybackService {

    // MARK: - Properties

    private let authService: AuthService

    // MARK: - Initialization

    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - PlaybackInfo API (Recommended)

    /// Obtient les informations de lecture via l'API PlaybackInfo avec DeviceProfile
    /// Cette méthode permet au serveur Jellyfin de décider du meilleur mode de lecture
    /// et d'inclure les sous-titres dans le manifest HLS si transcoding est nécessaire
    func getPlaybackInfo(
        itemId: String,
        quality: StreamQuality = .auto
    ) async throws -> PlaybackResult {
        guard let url = URL(string: "\(authService.baseURL)/Items/\(itemId)/PlaybackInfo") else {
            throw JellyfinError.invalidURL
        }

        // Créer le device profile avec support des sous-titres
        // Pour "Auto", utiliser le bitrate Maximum (360 Mbps) pour favoriser le Direct Play
        // Le serveur choisira le meilleur mode en fonction du média
        let maxBitrate = quality.maxBitrate ?? StreamQuality.maximum.rawValue
        let deviceProfile = DeviceProfile.tvOSProfile(maxBitrate: maxBitrate)

        // Créer la requête PlaybackInfo
        let playbackInfoRequest = PlaybackInfoRequest(
            userId: authService.userId,
            maxStreamingBitrate: maxBitrate,
            mediaSourceId: itemId,
            deviceProfile: deviceProfile,
            autoOpenLiveStream: true
        )

        var request = authService.authenticatedRequest(for: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(playbackInfoRequest)

        let (data, _) = try await URLSession.shared.data(for: request)

        let response = try JSONDecoder().decode(PlaybackInfoResponse.self, from: data)

        guard let playSessionId = response.playSessionId else {
            throw JellyfinError.responseError("Pas de PlaySessionId dans la réponse")
        }

        guard let mediaSource = response.mediaSources?.first else {
            throw JellyfinError.responseError("Pas de MediaSource dans la réponse")
        }

        // Déterminer l'URL de streaming
        // Logique basée sur Swiftfin: TranscodingURL > Direct Stream
        let streamURL: URL
        let isTranscoding: Bool

        // 1. Si le serveur fournit une URL de transcodage, l'utiliser
        if let transcodingUrl = mediaSource.transcodingUrl {
            guard let fullURL = URL(string: "\(authService.baseURL)\(transcodingUrl)") else {
                throw JellyfinError.invalidURL
            }
            streamURL = fullURL
            isTranscoding = true
        }
        // 2. Sinon, construire l'URL de Direct Stream (static=true)
        else {
            guard let fullURL = buildDirectStreamURL(itemId: itemId, playSessionId: playSessionId) else {
                throw JellyfinError.invalidURL
            }
            streamURL = fullURL
            isTranscoding = false
        }

        return PlaybackResult(
            streamURL: streamURL,
            playSessionId: playSessionId,
            mediaSource: mediaSource,
            isTranscoding: isTranscoding
        )
    }

    // MARK: - URL Building Helpers

    /// Construit l'URL de Direct Stream/Play pour un média (format Swiftfin)
    /// URL: /Videos/{itemId}/stream?static=true&mediaSourceId={itemId}&playSessionId=...
    private func buildDirectStreamURL(itemId: String, playSessionId: String) -> URL? {
        guard var urlComponents = URLComponents(string: "\(authService.baseURL)/Videos/\(itemId)/stream") else {
            return nil
        }

        let queryItems = [
            URLQueryItem(name: "static", value: "true"),
            URLQueryItem(name: "mediaSourceId", value: itemId),
            URLQueryItem(name: "playSessionId", value: playSessionId),
            URLQueryItem(name: "api_key", value: authService.accessToken),
            URLQueryItem(name: "deviceId", value: authService.deviceId)
        ]

        urlComponents.queryItems = queryItems
        return urlComponents.url
    }

    // MARK: - Legacy Streaming URLs (Fallback)

    /// Génère l'URL de streaming HLS pour un média (compatible tvOS)
    /// Note: Préférer getPlaybackInfo() qui gère mieux les sous-titres
    func getStreamURL(
        itemId: String,
        quality: StreamQuality = .auto,
        startPositionTicks: Int64 = 0,
        playSessionId: String,
        subtitleStreamIndex: Int? = nil
    ) -> URL? {
        guard var urlComponents = URLComponents(string: "\(authService.baseURL)/Videos/\(itemId)/master.m3u8") else {
            return nil
        }

        var queryItems = [
            URLQueryItem(name: "MediaSourceId", value: itemId),
            URLQueryItem(name: "DeviceId", value: authService.deviceId),
            URLQueryItem(name: "api_key", value: authService.accessToken),
            URLQueryItem(name: "PlaySessionId", value: playSessionId),
            URLQueryItem(name: "VideoCodec", value: "h264"),
            URLQueryItem(name: "AudioCodec", value: "aac"),
            URLQueryItem(name: "TranscodingContainer", value: "ts"),
            URLQueryItem(name: "TranscodingProtocol", value: "hls")
        ]

        // Paramètres de qualité - utiliser Maximum pour Auto (favorise Direct Play)
        let effectiveBitrate = quality.maxBitrate ?? StreamQuality.maximum.rawValue
        let effectiveMaxWidth = quality.maxWidth ?? 3840

        queryItems.append(URLQueryItem(name: "MaxStreamingBitrate", value: "\(effectiveBitrate)"))
        queryItems.append(URLQueryItem(name: "VideoBitrate", value: "\(effectiveBitrate)"))
        queryItems.append(URLQueryItem(name: "AudioBitrate", value: "192000"))
        queryItems.append(URLQueryItem(name: "MaxWidth", value: "\(effectiveMaxWidth)"))
        queryItems.append(URLQueryItem(name: "MaxHeight", value: "1080"))

        if startPositionTicks > 0 {
            queryItems.append(URLQueryItem(name: "StartTimeTicks", value: "\(startPositionTicks)"))
        }

        // Sous-titres : On ne passe PAS de SubtitleStreamIndex
        // Jellyfin inclut automatiquement TOUTES les pistes de sous-titres dans le manifest HLS
        // AVPlayer les détecte via AVMediaSelectionGroup et permet la sélection native
        // Note: Le paramètre subtitleStreamIndex est gardé pour compatibilité mais ignoré

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
        let urlString = "\(authService.baseURL)/Videos/\(itemId)/\(mediaSourceId)/Subtitles/\(streamIndex)/Stream.\(format)"

        guard var urlComponents = URLComponents(string: urlString) else {
            return nil
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "api_key", value: authService.accessToken)
        ]

        return urlComponents.url
    }

    // MARK: - Playback Reporting

    /// Signale le début de la lecture
    func reportPlaybackStart(itemId: String, positionTicks: Int64 = 0, playSessionId: String) async throws {
        guard let url = URL(string: "\(authService.baseURL)/Sessions/Playing") else {
            throw JellyfinError.invalidURL
        }

        var request = authService.authenticatedRequest(for: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

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
        guard let url = URL(string: "\(authService.baseURL)/Sessions/Playing/Progress") else {
            throw JellyfinError.invalidURL
        }

        var request = authService.authenticatedRequest(for: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

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
        guard let url = URL(string: "\(authService.baseURL)/Sessions/Playing/Stopped") else {
            throw JellyfinError.invalidURL
        }

        var request = authService.authenticatedRequest(for: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

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
