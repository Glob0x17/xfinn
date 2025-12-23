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

struct UserData: Codable, Hashable {
    let played: Bool
    let playbackPositionTicks: Int64
    let playCount: Int
    
    enum CodingKeys: String, CodingKey {
        case played = "Played"
        case playbackPositionTicks = "PlaybackPositionTicks"
        case playCount = "PlayCount"
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
