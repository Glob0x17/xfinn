//
//  HLSSubtitleResourceLoader.swift
//  xfinn
//
//  Corrige la synchronisation des sous-titres HLS transcodés par Jellyfin.
//
//  Problème (mesuré sur serveur réel) : les segments WebVTT de Jellyfin
//  embarquent une carte `X-TIMESTAMP-MAP=MPEGTS:900000` (offset 10 s, pensée
//  pour mpegts) alors que ses segments fMP4 démarrent à t=0 → AVPlayer
//  affiche les sous-titres ~10 s en retard.
//
//  Contrainte AVPlayer : le resource loader ne reçoit QUE les playlists —
//  jamais les segments média (.vtt inclus). On ne peut donc pas réécrire les
//  VTT. À la place :
//  - le master (scheme custom) est réécrit : vidéo en http direct, playlist
//    de sous-titres vers une playlist virtuelle (scheme custom) ;
//  - la playlist virtuelle est GÉNÉRÉE localement : un unique segment = le
//    VTT fichier-entier de Jellyfin (/Videos/.../Subtitles/{i}/Stream.vtt),
//    servi en http direct, qui ne contient PAS la carte fautive et dont les
//    cues sont en temps absolu — alignés sur la timeline fMP4.
//

import AVFoundation

final class HLSSubtitleResourceLoader: NSObject, AVAssetResourceLoaderDelegate {

    /// Schemes custom → schemes réels
    private static let schemeMap = ["xfinnhls": "http", "xfinnhlss": "https"]

    let queue = DispatchQueue(label: "com.xfinn.hlsSubtitleLoader")

    /// Durée du média (borne l'unique segment de la playlist virtuelle)
    private let mediaDuration: TimeInterval

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        return URLSession(configuration: configuration)
    }()

    init(mediaDuration: TimeInterval) {
        // Durée inconnue : borne large, AVPlayer tronque à la durée réelle
        self.mediaDuration = mediaDuration > 0 ? mediaDuration : 4 * 3600
    }

    /// URL proxifiée pour un master HLS de transcodage (nil si non applicable)
    static func proxyURL(for url: URL) -> URL? {
        guard url.path.hasSuffix("master.m3u8") else { return nil }
        return customURL(for: url)
    }

    private static func realURL(for url: URL) -> URL? {
        guard let scheme = url.scheme,
              let real = schemeMap[scheme],
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.scheme = real
        return components.url
    }

    private static func customURL(for url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        switch components.scheme {
        case "http": components.scheme = "xfinnhls"
        case "https": components.scheme = "xfinnhlss"
        default: return nil
        }
        return components.url
    }

    // MARK: - AVAssetResourceLoaderDelegate

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        guard let customURL = loadingRequest.request.url,
              let realURL = Self.realURL(for: customURL) else {
            return false
        }

        Task {
            await self.handle(loadingRequest, realURL: realURL)
        }
        return true
    }

    private func handle(_ loadingRequest: AVAssetResourceLoadingRequest, realURL: URL) async {
        // Playlist de sous-titres : générée localement, aucun fetch
        if realURL.path.hasSuffix("subtitles.m3u8") {
            guard let vttURL = Self.wholeFileVTTURL(forSubtitlePlaylist: realURL) else {
                loadingRequest.finishLoading(with: URLError(.badURL))
                return
            }
            let playlist = Self.makeSingleSegmentPlaylist(vttURL: vttURL, duration: mediaDuration)
            respond(loadingRequest, data: playlist, contentType: "application/vnd.apple.mpegurl")
            return
        }

        // Master (ou autre playlist) : fetch + réécriture
        do {
            let (data, response) = try await session.data(from: realURL)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                loadingRequest.finishLoading(with: URLError(.badServerResponse))
                return
            }

            let processed: Data
            if realURL.path.hasSuffix("master.m3u8") {
                processed = Self.rewriteMasterPlaylist(data, baseURL: realURL)
            } else {
                processed = data
            }
            respond(loadingRequest, data: processed, contentType: "application/vnd.apple.mpegurl")
        } catch {
            loadingRequest.finishLoading(with: error)
        }
    }

    private func respond(_ loadingRequest: AVAssetResourceLoadingRequest, data: Data, contentType: String) {
        loadingRequest.contentInformationRequest?.contentType = contentType
        loadingRequest.contentInformationRequest?.contentLength = Int64(data.count)
        loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = false
        loadingRequest.dataRequest?.respond(with: data)
        loadingRequest.finishLoading()
    }

    // MARK: - Réécritures (fonctions pures, testées dans xfinnTests)

    /// Master : la vidéo part en direct (URLs absolues http), les playlists de
    /// sous-titres pointent vers nos playlists virtuelles (scheme custom)
    static func rewriteMasterPlaylist(_ data: Data, baseURL: URL) -> Data {
        guard let text = String(data: data, encoding: .utf8) else { return data }

        let lines = text.components(separatedBy: "\n").map { line -> String in
            if line.hasPrefix("#EXT-X-MEDIA:") && line.contains("TYPE=SUBTITLES") {
                return rewriteURIAttribute(in: line, baseURL: baseURL, keepInProxy: true)
            }
            if line.hasPrefix("#EXT-X-MEDIA:") {
                return rewriteURIAttribute(in: line, baseURL: baseURL, keepInProxy: false)
            }
            if !line.hasPrefix("#") && !line.trimmingCharacters(in: .whitespaces).isEmpty {
                return absoluteURL(line, baseURL: baseURL, keepInProxy: false) ?? line
            }
            return line
        }

        return Data(lines.joined(separator: "\n").utf8)
    }

    /// URL du VTT fichier-entier correspondant à une playlist de sous-titres
    /// Jellyfin : .../{mediaSourceId}/Subtitles/{index}/subtitles.m3u8?...ApiKey=K
    ///        →  .../{mediaSourceId}/Subtitles/{index}/Stream.vtt?ApiKey=K
    static func wholeFileVTTURL(forSubtitlePlaylist url: URL) -> URL? {
        guard url.path.hasSuffix("/subtitles.m3u8"),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.path = String(components.path.dropLast("subtitles.m3u8".count)) + "Stream.vtt"
        // Ne garder que l'authentification (SegmentLength & co n'ont plus de sens)
        components.queryItems = components.queryItems?.filter {
            $0.name.lowercased() == "apikey" || $0.name.lowercased() == "api_key"
        }
        if components.queryItems?.isEmpty == true {
            components.queryItems = nil
        }
        return components.url
    }

    /// Playlist VOD minimale : un unique segment = le VTT complet en http direct
    /// (les segments média ne passent jamais par le resource loader)
    static func makeSingleSegmentPlaylist(vttURL: URL, duration: TimeInterval) -> Data {
        let target = Int(duration.rounded(.up))
        let playlist = """
        #EXTM3U
        #EXT-X-VERSION:3
        #EXT-X-TARGETDURATION:\(target)
        #EXT-X-MEDIA-SEQUENCE:0
        #EXT-X-PLAYLIST-TYPE:VOD
        #EXTINF:\(String(format: "%.3f", duration)),
        \(vttURL.absoluteString)
        #EXT-X-ENDLIST
        """
        return Data(playlist.utf8)
    }

    private static func rewriteURIAttribute(in line: String, baseURL: URL, keepInProxy: Bool) -> String {
        guard let range = line.range(of: #"URI="[^"]*""#, options: .regularExpression) else {
            return line
        }
        let uri = String(line[range].dropFirst(5).dropLast(1))
        guard let absolute = absoluteURL(uri, baseURL: baseURL, keepInProxy: keepInProxy) else {
            return line
        }
        return line.replacingCharacters(in: range, with: #"URI="\#(absolute)""#)
    }

    private static func absoluteURL(_ reference: String, baseURL: URL, keepInProxy: Bool) -> String? {
        guard let resolved = URL(string: reference, relativeTo: baseURL)?.absoluteURL else {
            return nil
        }
        if keepInProxy {
            return customURL(for: resolved)?.absoluteString ?? resolved.absoluteString
        }
        return resolved.absoluteString
    }
}
