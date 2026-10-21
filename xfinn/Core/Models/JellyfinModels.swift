//
//  JellyfinModels.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import Foundation

// MARK: - Serveur et Authentification

struct ServerInfo: Codable, Identifiable {
    let id: String
    let serverName: String
    let version: String
    let operatingSystem: String
    
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case serverName = "ServerName"
        case version = "Version"
        case operatingSystem = "OperatingSystem"
    }
}

struct AuthenticationResult: Codable {
    let user: User
    let accessToken: String
    let serverId: String

    enum CodingKeys: String, CodingKey {
        case user = "User"
        case accessToken = "AccessToken"
        case serverId = "ServerId"
    }
}

/// État d'une session Quick Connect (réponses de /QuickConnect/Initiate et /Connect)
struct QuickConnectResult: Codable {
    let authenticated: Bool
    let secret: String
    let code: String

    enum CodingKeys: String, CodingKey {
        case authenticated = "Authenticated"
        case secret = "Secret"
        case code = "Code"
    }

    /// Code groupé pour l'affichage : "482917" → "482 917"
    /// Un code de longueur impaire ou non standard est rendu tel quel
    var formattedCode: String {
        guard code.count == 6 else { return code }
        let mid = code.index(code.startIndex, offsetBy: 3)
        return "\(code[..<mid]) \(code[mid...])"
    }
}

// MARK: - Media Segments (intro/générique, Jellyfin 10.9+)

/// Segment temporel d'un média détecté côté serveur (plugin Intro Skipper ou
/// équivalent) — réponse de GET /MediaSegments/{itemId}
struct MediaSegment: Codable, Identifiable, Equatable {
    enum SegmentType: String, Codable, Equatable {
        case intro = "Intro"
        case outro = "Outro"
        case recap = "Recap"
        case preview = "Preview"
        case commercial = "Commercial"
        case unknown

        /// Seuls intro/générique/récap sont proposés au skip
        var isSkippable: Bool {
            switch self {
            case .intro, .outro, .recap: return true
            case .preview, .commercial, .unknown: return false
            }
        }
    }

    let id: String
    let itemId: String
    let type: SegmentType
    let startTicks: Int64
    let endTicks: Int64

    var startSeconds: TimeInterval { Double(startTicks) / 10_000_000.0 }
    var endSeconds: TimeInterval { Double(endTicks) / 10_000_000.0 }

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case itemId = "ItemId"
        case type = "Type"
        case startTicks = "StartTicks"
        case endTicks = "EndTicks"
    }

    init(id: String, itemId: String, type: SegmentType, startTicks: Int64, endTicks: Int64) {
        self.id = id
        self.itemId = itemId
        self.type = type
        self.startTicks = startTicks
        self.endTicks = endTicks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        itemId = try container.decode(String.self, forKey: .itemId)
        startTicks = try container.decode(Int64.self, forKey: .startTicks)
        endTicks = try container.decode(Int64.self, forKey: .endTicks)
        // Tolérant aux types futurs : inconnu ≠ erreur de décodage
        let rawType = try container.decode(String.self, forKey: .type)
        type = SegmentType(rawValue: rawType) ?? .unknown
    }
}

struct MediaSegmentsResponse: Codable {
    let items: [MediaSegment]

    enum CodingKeys: String, CodingKey {
        case items = "Items"
    }
}

extension Array where Element == MediaSegment {
    /// Segment skippable actif à l'instant t (bornes [start, end)), en
    /// ignorant le segment volontairement supprimé après un skip manuel.
    /// Logique pure, testée dans xfinnTests/MediaSegmentTests
    func activeSegment(at time: TimeInterval, excluding suppressedID: String?) -> MediaSegment? {
        first { segment in
            segment.type.isSkippable
                && segment.id != suppressedID
                && time >= segment.startSeconds
                && time < segment.endSeconds
        }
    }
}

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let serverId: String
    let hasPassword: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case serverId = "ServerId"
        case hasPassword = "HasPassword"
    }
}

// MARK: - Bibliothèques

struct LibraryItem: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let collectionType: String?
    var imageUrl: String? // Calculée après décodage, non incluse dans l'API
    
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case collectionType = "CollectionType"
        // imageUrl n'est pas décodée depuis l'API
    }
    
    // Initializer personnalisé pour créer avec imageUrl
    init(id: String, name: String, collectionType: String?, imageUrl: String?) {
        self.id = id
        self.name = name
        self.collectionType = collectionType
        self.imageUrl = imageUrl
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: LibraryItem, rhs: LibraryItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Médias

/// Représente un artiste dans les métadonnées musicales
struct ArtistItem: Codable, Identifiable, Hashable {
    let id: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
    }
}

extension MediaItem {
    /// Type affiché à l'utilisateur (« Film », « Série »…), le type Jellyfin
    /// brut (« Movie ») pour un type inconnu
    var localizedTypeName: String {
        switch type {
        case "Movie": return "media_type.movie".localized
        case "Series": return "media_type.series".localized
        case "Episode": return "media_type.episode".localized
        case "Season": return "media_type.season".localized
        case "MusicAlbum": return "media_type.music_album".localized
        case "MusicArtist": return "media_type.music_artist".localized
        case "Audio": return "media_type.audio".localized
        default: return type
        }
    }
}

struct MediaItem: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let type: String
    let overview: String?
    let productionYear: Int?
    let indexNumber: Int?
    let parentIndexNumber: Int?
    let communityRating: Double?
    let officialRating: String?
    let runTimeTicks: Int64?
    let userData: UserData?
    let seriesName: String?
    let seriesId: String?
    let seasonId: String?
    let mediaStreams: [MediaStream]?

    // MARK: - Music Properties
    let artists: [String]?
    let artistItems: [ArtistItem]?
    let album: String?
    let albumId: String?
    let albumPrimaryImageTag: String?
    let albumArtist: String?
    let albumArtists: [ArtistItem]?
    let container: String?
    let hasLyrics: Bool?
    let normalizationGain: Double?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case type = "Type"
        case overview = "Overview"
        case productionYear = "ProductionYear"
        case indexNumber = "IndexNumber"
        case parentIndexNumber = "ParentIndexNumber"
        case communityRating = "CommunityRating"
        case officialRating = "OfficialRating"
        case runTimeTicks = "RunTimeTicks"
        case userData = "UserData"
        case seriesName = "SeriesName"
        case seriesId = "SeriesId"
        case seasonId = "SeasonId"
        case mediaStreams = "MediaStreams"

        // Music properties
        case artists = "Artists"
        case artistItems = "ArtistItems"
        case album = "Album"
        case albumId = "AlbumId"
        case albumPrimaryImageTag = "AlbumPrimaryImageTag"
        case albumArtist = "AlbumArtist"
        case albumArtists = "AlbumArtists"
        case container = "Container"
        case hasLyrics = "HasLyrics"
        case normalizationGain = "NormalizationGain"
    }

    // Initializer manuel pour créer des MediaItem (utile pour tests/previews)
    init(
        id: String,
        name: String,
        type: String,
        overview: String? = nil,
        productionYear: Int? = nil,
        indexNumber: Int? = nil,
        parentIndexNumber: Int? = nil,
        communityRating: Double? = nil,
        officialRating: String? = nil,
        runTimeTicks: Int64? = nil,
        userData: UserData? = nil,
        seriesName: String? = nil,
        seriesId: String? = nil,
        seasonId: String? = nil,
        mediaStreams: [MediaStream]? = nil,
        artists: [String]? = nil,
        artistItems: [ArtistItem]? = nil,
        album: String? = nil,
        albumId: String? = nil,
        albumPrimaryImageTag: String? = nil,
        albumArtist: String? = nil,
        albumArtists: [ArtistItem]? = nil,
        container: String? = nil,
        hasLyrics: Bool? = nil,
        normalizationGain: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.overview = overview
        self.productionYear = productionYear
        self.indexNumber = indexNumber
        self.parentIndexNumber = parentIndexNumber
        self.communityRating = communityRating
        self.officialRating = officialRating
        self.runTimeTicks = runTimeTicks
        self.userData = userData
        self.seriesName = seriesName
        self.seriesId = seriesId
        self.seasonId = seasonId
        self.mediaStreams = mediaStreams
        self.artists = artists
        self.artistItems = artistItems
        self.album = album
        self.albumId = albumId
        self.albumPrimaryImageTag = albumPrimaryImageTag
        self.albumArtist = albumArtist
        self.albumArtists = albumArtists
        self.container = container
        self.hasLyrics = hasLyrics
        self.normalizationGain = normalizationGain
    }
    
    var displayTitle: String {
        if let episode = indexNumber, let season = parentIndexNumber {
            return "\(seriesName ?? name) - S\(season)E\(episode)"
        }
        return name
    }

    var duration: TimeInterval? {
        guard let ticks = runTimeTicks else { return nil }
        return Double(ticks) / 10_000_000.0
    }

    // Récupérer les sous-titres disponibles
    var subtitleStreams: [MediaStream] {
        return mediaStreams?.filter { $0.type == "Subtitle" } ?? []
    }

    // Récupérer les pistes audio disponibles
    var audioStreams: [MediaStream] {
        return mediaStreams?.filter { $0.type == "Audio" } ?? []
    }

    /// Plusieurs langues audio disponibles ?
    var hasMultipleAudioTracks: Bool {
        audioStreams.count > 1
    }

    // MARK: - Music Helpers

    /// Indique si c'est un item musical
    var isMusicItem: Bool {
        return type == "Audio" || type == "MusicAlbum" || type == "MusicArtist"
    }

    /// Retourne le nom du premier artiste (pratique pour l'affichage)
    var primaryArtist: String? {
        return artists?.first ?? albumArtist
    }

    /// Numéro de piste formaté (ex: "01")
    var formattedTrackNumber: String? {
        guard let trackNum = indexNumber else { return nil }
        return String(format: "%02d", trackNum)
    }

    /// Durée formatée en mm:ss
    var formattedDuration: String? {
        duration?.formattedPlaybackTime
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Media Streams (Audio/Subtitles)

struct MediaStream: Codable, Identifiable, Hashable {
    let index: Int
    let type: String
    let displayTitle: String?
    let language: String?
    let codec: String?
    let isDefault: Bool?
    let isForced: Bool?
    let deliveryUrl: String?
    
    var id: Int { index }
    
    enum CodingKeys: String, CodingKey {
        case index = "Index"
        case type = "Type"
        case displayTitle = "DisplayTitle"
        case language = "Language"
        case codec = "Codec"
        case isDefault = "IsDefault"
        case isForced = "IsForced"
        case deliveryUrl = "DeliveryUrl"
    }
    
    var displayName: String {
        if let title = displayTitle {
            return title
        }
        if let lang = language {
            return lang.uppercased()
        }
        return "Track \(index)"
    }
}

extension Array where Element == MediaStream {
    /// Index de la première piste dont la langue correspond (fre/fra
    /// normalisés) — utilisé pour l'auto-sélection audio.
    /// Logique pure, testée dans xfinnTests
    func firstAudioIndex(matchingLanguage preferred: String?) -> Int? {
        guard let preferred, !preferred.isEmpty else { return nil }
        let normalized = Self.normalizeLanguage(preferred)
        return first { Self.normalizeLanguage($0.language ?? "") == normalized }?.index
    }

    /// "fra"/"fre"/"fr"/"fr-FR" → "fre" ; les autres codes en minuscules
    static func normalizeLanguage(_ code: String) -> String {
        let lower = String(code.lowercased().split(separator: "-").first ?? "")
        switch lower {
        case "fra", "fr", "fre": return "fre"
        case "eng", "en": return "eng"
        case "spa", "es": return "spa"
        case "por", "pt": return "por"
        case "deu", "ger", "de": return "ger"
        default: return lower
        }
    }
}

struct UserData: Codable, Hashable {
    let played: Bool
    let playbackPositionTicks: Int64
    let playCount: Int
    /// Optionnel : absent des réponses de vieux serveurs, présent partout en 10.x
    let isFavorite: Bool?

    enum CodingKeys: String, CodingKey {
        case played = "Played"
        case playbackPositionTicks = "PlaybackPositionTicks"
        case playCount = "PlayCount"
        case isFavorite = "IsFavorite"
    }

    var playbackPosition: TimeInterval {
        return Double(playbackPositionTicks) / 10_000_000.0
    }
}

struct ItemsResponse: Codable {
    let items: [MediaItem]
    let totalRecordCount: Int
    
    enum CodingKeys: String, CodingKey {
        case items = "Items"
        case totalRecordCount = "TotalRecordCount"
    }
}
