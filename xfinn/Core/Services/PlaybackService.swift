//
//  PlaybackService.swift
//  xfinn
//
//  Created by Claude on 05/01/2026.
//  Extracted from JellyfinService for better separation of concerns.
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
        let maxBitrate = quality.maxBitrate ?? 20_000_000
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
        let streamURL: URL
        let isTranscoding: Bool

        if let transcodingUrl = mediaSource.transcodingUrl {
            // Transcoding - sous-titres inclus dans le manifest HLS
            guard let fullURL = URL(string: "\(authService.baseURL)\(transcodingUrl)") else {
                throw JellyfinError.invalidURL
            }
            streamURL = fullURL
            isTranscoding = true
        } else if let directStreamUrl = mediaSource.directStreamUrl {
            // Direct Stream
            guard let fullURL = URL(string: "\(authService.baseURL)\(directStreamUrl)") else {
                throw JellyfinError.invalidURL
            }
            streamURL = fullURL
            isTranscoding = false
        } else if mediaSource.supportsDirectPlay == true, let path = mediaSource.path {
            // Direct Play
            guard let fullURL = URL(string: path) else {
                throw JellyfinError.invalidURL
            }
            streamURL = fullURL
            isTranscoding = false
        } else {
            throw JellyfinError.responseError("Aucune URL de streaming disponible")
        }

        return PlaybackResult(
            streamURL: streamURL,
            playSessionId: playSessionId,
            mediaSource: mediaSource,
            isTranscoding: isTranscoding
        )
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

        // Paramètres de qualité
        let effectiveBitrate = quality.maxBitrate ?? 15_000_000
        let effectiveMaxWidth = quality.maxWidth ?? 1920

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
