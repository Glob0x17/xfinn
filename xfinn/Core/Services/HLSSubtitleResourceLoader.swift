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

    /// Retirer du master la variante réencodée de secours (voir
    /// `dropReencodedFallbackVariants`)
    private let dropsReencodedFallback: Bool

    private let lock = NSLock()
    private var _didDropReencodedFallback = false

    /// Le master servi à AVPlayer n'avait plus sa variante réencodée : un
    /// échec avant la première image justifie une relance qui la garde
    var didDropReencodedFallback: Bool {
        lock.withLock { _didDropReencodedFallback }
    }

    init(mediaDuration: TimeInterval, dropsReencodedFallback: Bool = false) {
        // Durée inconnue : borne large, AVPlayer tronque à la durée réelle
        self.mediaDuration = mediaDuration > 0 ? mediaDuration : 4 * 3600
        self.dropsReencodedFallback = dropsReencodedFallback
    }

    private func markDroppedReencodedFallback() {
        lock.withLock { _didDropReencodedFallback = true }
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
                let dropped = dropsReencodedFallback && Self.hasReencodedFallbackToDrop(data)
                if dropped { markDroppedReencodedFallback() }
                processed = Self.rewriteMasterPlaylist(data, baseURL: realURL, dropReencodedFallback: dropped)
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
    static func rewriteMasterPlaylist(_ data: Data, baseURL: URL, dropReencodedFallback: Bool = false) -> Data {
        guard let text = String(data: data, encoding: .utf8) else { return data }

        var variants = text.components(separatedBy: "\n")
        if dropReencodedFallback {
            variants = dropReencodedFallbackVariants(variants)
        }
        let lines = variants.map { line -> String in
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

    /// Source HDR copiée telle quelle : Jellyfin ajoute une variante de secours
    /// H.264 SDR (`AllowVideoStreamCopy=false`, réencodage 4K + tone mapping à
    /// ~8 i/s) que l'Apple TV choisit même sur une TV capable de HDR dès
    /// qu'elle est réglée en SDR. On ne garde que les variantes copiées, s'il
    /// en existe. TV réglée en SDR : AVPlayer refuse alors la variante HDR
    /// (« ouverture impossible ») et PlayerManager relance avec le master
    /// d'origine, variante réencodée comprise.
    static func hasReencodedFallbackToDrop(_ data: Data) -> Bool {
        guard let text = String(data: data, encoding: .utf8) else { return false }
        let lines = text.components(separatedBy: "\n")
        return dropReencodedFallbackVariants(lines).count != lines.count
    }

    static func dropReencodedFallbackVariants(_ lines: [String]) -> [String] {
        let isFallbackURI = { (line: String) in
            !line.hasPrefix("#") && line.contains("AllowVideoStreamCopy=false")
        }
        let variantURIs = lines.indices.filter { $0 > 0 && lines[$0 - 1].hasPrefix("#EXT-X-STREAM-INF:") }
        let fallbacks = Set(variantURIs.filter { isFallbackURI(lines[$0]) })
        guard !fallbacks.isEmpty, fallbacks.count < variantURIs.count else { return lines }

        return lines.indices.compactMap { index in
            fallbacks.contains(index) || fallbacks.contains(index + 1) ? nil : lines[index]
        }
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
