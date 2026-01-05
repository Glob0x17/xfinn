//
//  PlaybackService.swift
//  xfinn
//
//  Created by Claude on 05/01/2026.
//  Extracted from JellyfinService for better separation of concerns.
//

import Foundation

/// Service de gestion de la lecture Jellyfin
final class PlaybackService {

    // MARK: - Properties

    private let authService: AuthService

    // MARK: - Initialization

    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - Streaming URLs

    /// Génère l'URL de streaming HLS pour un média (compatible tvOS)
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

        // Configuration des sous-titres
        if let subtitleIndex = subtitleStreamIndex {
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
