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
    /// Le Direct Play a été refusé côté client (MP4 fragmenté détecté ou
    /// repli après échec) : le flux est un remux HLS
    let directPlayDisabled: Bool
}

/// Service de gestion de la lecture Jellyfin
@MainActor
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
    /// Construit la query de PlaybackInfo — Jellyfin n'honore
    /// AudioStreamIndex/SubtitleStreamIndex QUE en query string et QUE si
    /// MediaSourceId y figure aussi (vérifié sur 10.11 ; en body ils sont
    /// silencieusement ignorés). SubtitleStreamIndex=-1 = aucun sous-titre
    /// (sinon le serveur applique la préférence du compte, qui peut
    /// déclencher une incrustation impossible à désactiver côté client).
    /// Fonction pure, testée dans xfinnTests
    static func playbackInfoQueryItems(
        itemId: String,
        audioStreamIndex: Int?,
        subtitleStreamIndex: Int?
    ) -> [URLQueryItem] {
        var items = [URLQueryItem(name: "MediaSourceId", value: itemId)]
        if let audioStreamIndex {
            items.append(URLQueryItem(name: "AudioStreamIndex", value: "\(audioStreamIndex)"))
        }
        if let subtitleStreamIndex {
            items.append(URLQueryItem(name: "SubtitleStreamIndex", value: "\(subtitleStreamIndex)"))
        }
        return items
    }

    /// - Parameter forceAudioTranscode: profil de repli qui impose le
    ///   réencodage audio en AAC (voir `DeviceProfile.tvOSProfile`)
    /// - Parameter allowDirectPlay: false = demande un flux HLS même si le
    ///   fichier est lisible tel quel (voir `MP4Layout`)
    func getPlaybackInfo(
        itemId: String,
        quality: StreamQuality = .auto,
        audioStreamIndex: Int? = nil,
        subtitleStreamIndex: Int? = nil,
        forceAudioTranscode: Bool = false,
        allowDirectPlay: Bool = true
    ) async throws -> PlaybackResult {
        guard var urlComponents = URLComponents(string: "\(authService.baseURL)/Items/\(itemId)/PlaybackInfo") else {
            throw JellyfinError.invalidURL
        }
        urlComponents.queryItems = Self.playbackInfoQueryItems(
            itemId: itemId,
            audioStreamIndex: audioStreamIndex,
            subtitleStreamIndex: subtitleStreamIndex
        )
        guard let url = urlComponents.url else {
            throw JellyfinError.invalidURL
        }

        // Créer le device profile avec support des sous-titres
        // Pour "Auto", utiliser le bitrate Maximum (360 Mbps) pour favoriser le Direct Play
        // Le serveur choisira le meilleur mode en fonction du média
        let maxBitrate = quality.maxBitrate ?? StreamQuality.maximum.rawValue
        let deviceProfile = DeviceProfile.currentProfile(
            maxBitrate: maxBitrate,
            forceAudioTranscode: forceAudioTranscode
        )

        // Créer la requête PlaybackInfo
        let playbackInfoRequest = PlaybackInfoRequest(
            userId: authService.userId,
            maxStreamingBitrate: maxBitrate,
            mediaSourceId: itemId,
            deviceProfile: deviceProfile,
            autoOpenLiveStream: true,
            enableDirectPlay: allowDirectPlay ? nil : false,
            enableDirectStream: allowDirectPlay ? nil : false
        )

        var request = authService.authenticatedRequest(for: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(playbackInfoRequest)

        let (data, response) = try await authService.session.data(for: request)
        try response.validateJellyfinResponse()

        let playbackInfoResponse = try JSONDecoder().decode(PlaybackInfoResponse.self, from: data)

        guard let playSessionId = playbackInfoResponse.playSessionId else {
            throw JellyfinError.responseError("error.no_play_session".localized)
        }

        guard let mediaSource = playbackInfoResponse.mediaSources?.first else {
            throw JellyfinError.responseError("error.no_media_source".localized)
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

            // MP4 fragmenté en Direct Play : AVPlayer bloque plusieurs
            // minutes au chargement → redemander un remux HLS au serveur
            if allowDirectPlay,
               MP4Layout.isMP4Family(container: mediaSource.container),
               await isFragmentedMP4(at: fullURL) == true {
                #if DEBUG
                print("[PlaybackService] Fragmented MP4 detected for \(itemId) — requesting HLS instead of Direct Play")
                #endif
                return try await getPlaybackInfo(
                    itemId: itemId,
                    quality: quality,
                    audioStreamIndex: audioStreamIndex,
                    subtitleStreamIndex: subtitleStreamIndex,
                    forceAudioTranscode: forceAudioTranscode,
                    allowDirectPlay: false
                )
            }
        }

        return PlaybackResult(
            streamURL: streamURL,
            playSessionId: playSessionId,
            mediaSource: mediaSource,
            isTranscoding: isTranscoding,
            directPlayDisabled: !allowDirectPlay
        )
    }

    /// Lit les premiers Ko du fichier (requête Range) pour détecter un MP4
    /// fragmenté. nil si indéterminé ou en cas d'erreur réseau — le timeout
    /// de chargement côté PlayerManager couvre alors le cas.
    private func isFragmentedMP4(at url: URL) async -> Bool? {
        var request = URLRequest(url: url, timeoutInterval: 5)
        request.setValue("bytes=0-\(MP4Layout.probeLength - 1)", forHTTPHeaderField: "Range")

        guard let (data, response) = try? await authService.session.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return nil
        }
        // Un serveur qui ignore Range renvoie 200 + le fichier entier :
        // URLSession l'a déjà téléchargé, on ne garde que la tête
        return MP4Layout.isFragmented(prefix: data.prefix(MP4Layout.probeLength))
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
            URLQueryItem(name: "ApiKey", value: authService.accessToken),
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
            URLQueryItem(name: "ApiKey", value: authService.accessToken),
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
            URLQueryItem(name: "ApiKey", value: authService.accessToken)
        ]

        return urlComponents.url
    }

    // MARK: - Media Segments

    /// Récupère les segments (intro, générique, récap) d'un média
    /// Serveur < 10.9 ou média non analysé : l'appelant traite l'erreur/le
    /// vide comme "pas de segments" — jamais bloquant pour la lecture
    func getMediaSegments(itemId: String) async throws -> [MediaSegment] {
        guard let url = URL(string: "\(authService.baseURL)/MediaSegments/\(itemId)") else {
            throw JellyfinError.invalidURL
        }

        let request = authService.authenticatedRequest(for: url)
        let (data, response) = try await authService.session.data(for: request)
        try response.validateJellyfinResponse()

        return try JSONDecoder().decode(MediaSegmentsResponse.self, from: data).items
    }

    // MARK: - Playback Reporting

    /// Signale le début de la lecture
    func reportPlaybackStart(itemId: String, positionTicks: Int64 = 0, playSessionId: String, playMethod: String = "DirectStream") async throws {
        guard let url = URL(string: "\(authService.baseURL)/Sessions/Playing") else {
            throw JellyfinError.invalidURL
        }

        var request = authService.authenticatedRequest(for: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "ItemId": itemId,
            "PositionTicks": positionTicks,
            "PlayMethod": playMethod,
            "CanSeek": true,
            "PlaySessionId": playSessionId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await authService.session.data(for: request)
        try response.validateJellyfinResponse()
    }

    /// Signale la progression de la lecture
    func reportPlaybackProgress(itemId: String, positionTicks: Int64, isPaused: Bool = false, playSessionId: String, playMethod: String = "DirectStream") async throws {
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
            "PlayMethod": playMethod,
            "CanSeek": true,
            "PlaySessionId": playSessionId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await authService.session.data(for: request)
        try response.validateJellyfinResponse()
    }

    /// Signale l'arrêt de la lecture
    func reportPlaybackStopped(itemId: String, positionTicks: Int64, playSessionId: String, playMethod: String = "DirectStream") async throws {
        guard let url = URL(string: "\(authService.baseURL)/Sessions/Playing/Stopped") else {
            throw JellyfinError.invalidURL
        }

        var request = authService.authenticatedRequest(for: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "ItemId": itemId,
            "PositionTicks": positionTicks,
            "PlayMethod": playMethod,
            "PlaySessionId": playSessionId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await authService.session.data(for: request)
        try response.validateJellyfinResponse()
    }

}
