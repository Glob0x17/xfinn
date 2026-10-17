//
//  MediaService.swift
//  xfinn
//
//  Created by Dorian Galiana on 05/01/2026.
//  Extracted from JellyfinService for better separation of concerns.
//

import Foundation

/// Service de gestion des médias Jellyfin
@MainActor
final class MediaService {

    // MARK: - Properties

    private let authService: AuthService

    // MARK: - Initialization

    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - Libraries

    /// Réponse de l'endpoint /Users/{id}/Views — expose le vrai CollectionType
    /// ("movies", "tvshows", "music"...), que MediaItem.type ne contient pas
    /// (il vaut "CollectionFolder" pour toutes les bibliothèques)
    private struct LibraryViewsResponse: Decodable {
        struct Item: Decodable {
            let id: String
            let name: String
            let collectionType: String?

            enum CodingKeys: String, CodingKey {
                case id = "Id"
                case name = "Name"
                case collectionType = "CollectionType"
            }
        }

        let items: [Item]

        enum CodingKeys: String, CodingKey {
            case items = "Items"
        }
    }

    /// Récupère toutes les bibliothèques de l'utilisateur
    func getLibraries() async throws -> [LibraryItem] {
        guard let url = URL(string: "\(authService.baseURL)/Users/\(authService.userId)/Views") else {
            throw JellyfinError.invalidURL
        }

        let request = authService.authenticatedRequest(for: url)
        let (data, response) = try await authService.session.data(for: request)
        try response.validateJellyfinResponse()
        let viewsResponse = try JSONDecoder().decode(LibraryViewsResponse.self, from: data)

        return viewsResponse.items.map { item in
            LibraryItem(
                id: item.id,
                name: item.name,
                collectionType: item.collectionType,
                imageUrl: getImageURL(itemId: item.id, imageType: "Primary")
            )
        }
    }

    // MARK: - Media Items

    /// Récupère les médias d'une bibliothèque ou d'un parent
    func getItems(
        parentId: String,
        includeItemTypes: [String]? = nil,
        recursive: Bool = false,
        limit: Int? = nil
    ) async throws -> [MediaItem] {
        guard var urlComponents = URLComponents(string: "\(authService.baseURL)/Users/\(authService.userId)/Items") else {
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

        let request = authService.authenticatedRequest(for: url)
        let (data, response) = try await authService.session.data(for: request)
        try response.validateJellyfinResponse()
        let itemsResponse = try JSONDecoder().decode(ItemsResponse.self, from: data)

        return itemsResponse.items
    }

    /// Page de résultats d'une bibliothèque (pagination serveur)
    struct ItemsPage {
        let items: [MediaItem]
        let totalCount: Int
    }

    /// Récupère une page de médias d'une bibliothèque, avec tri et filtre
    /// UserData est demandé dans Fields (badges vu/favori sur les cartes)
    func getItemsPage(
        parentId: String,
        sortBy: LibrarySortOption,
        unwatchedOnly: Bool,
        startIndex: Int,
        limit: Int
    ) async throws -> ItemsPage {
        guard var urlComponents = URLComponents(string: "\(authService.baseURL)/Users/\(authService.userId)/Items") else {
            throw JellyfinError.invalidURL
        }

        var queryItems = [
            URLQueryItem(name: "ParentId", value: parentId),
            URLQueryItem(name: "Fields", value: "Overview,PrimaryImageAspectRatio,MediaStreams,UserData"),
            URLQueryItem(name: "SortBy", value: sortBy.apiSortBy),
            URLQueryItem(name: "SortOrder", value: sortBy.apiSortOrder),
            URLQueryItem(name: "StartIndex", value: "\(startIndex)"),
            URLQueryItem(name: "Limit", value: "\(limit)")
        ]

        if unwatchedOnly {
            queryItems.append(URLQueryItem(name: "Filters", value: "IsUnplayed"))
        }

        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw JellyfinError.invalidURL
        }

        let request = authService.authenticatedRequest(for: url)
        let (data, response) = try await authService.session.data(for: request)
        try response.validateJellyfinResponse()
        let itemsResponse = try JSONDecoder().decode(ItemsResponse.self, from: data)

        return ItemsPage(items: itemsResponse.items, totalCount: itemsResponse.totalRecordCount)
    }

    /// Récupère les médias en cours de lecture
    func getResumeItems(limit: Int = 12) async throws -> [MediaItem] {
        guard var urlComponents = URLComponents(string: "\(authService.baseURL)/Users/\(authService.userId)/Items/Resume") else {
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

        let request = authService.authenticatedRequest(for: url)
        let (data, response) = try await authService.session.data(for: request)
        try response.validateJellyfinResponse()
        let itemsResponse = try JSONDecoder().decode(ItemsResponse.self, from: data)

        return itemsResponse.items
    }

    /// Récupère les médias récemment ajoutés
    func getLatestItems(parentId: String? = nil, limit: Int = 16) async throws -> [MediaItem] {
        guard var urlComponents = URLComponents(string: "\(authService.baseURL)/Users/\(authService.userId)/Items/Latest") else {
            throw JellyfinError.invalidURL
        }

        var queryItems = [
            URLQueryItem(name: "Limit", value: "\(limit)"),
            URLQueryItem(name: "Fields", value: "Overview,PrimaryImageAspectRatio,MediaStreams")
        ]

        if let parentId = parentId {
            queryItems.insert(URLQueryItem(name: "ParentId", value: parentId), at: 0)
        }

        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw JellyfinError.invalidURL
        }

        let request = authService.authenticatedRequest(for: url)
        let (data, response) = try await authService.session.data(for: request)
        try response.validateJellyfinResponse()

        // L'endpoint Latest retourne un tableau direct, pas un ItemsResponse
        return try JSONDecoder().decode([MediaItem].self, from: data)
    }

    /// Recherche des médias par mots-clés
    func search(query: String, includeItemTypes: [String]? = nil, limit: Int = 50) async throws -> [MediaItem] {
        guard !query.isEmpty else { return [] }

        guard var urlComponents = URLComponents(string: "\(authService.baseURL)/Users/\(authService.userId)/Items") else {
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

        if let types = includeItemTypes, !types.isEmpty {
            queryItems.append(URLQueryItem(name: "IncludeItemTypes", value: types.joined(separator: ",")))
        } else {
            queryItems.append(URLQueryItem(name: "IncludeItemTypes", value: "Movie,Series,Episode,MusicAlbum,MusicArtist,Audio"))
        }

        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw JellyfinError.invalidURL
        }

        let request = authService.authenticatedRequest(for: url)
        let (data, response) = try await authService.session.data(for: request)
        try response.validateJellyfinResponse()
        let itemsResponse = try JSONDecoder().decode(ItemsResponse.self, from: data)

        return itemsResponse.items
    }

    /// Récupère les détails d'un média spécifique
    func getItem(itemId: String) async throws -> MediaItem {
        guard var urlComponents = URLComponents(string: "\(authService.baseURL)/Users/\(authService.userId)/Items/\(itemId)") else {
            throw JellyfinError.invalidURL
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "Fields", value: "Overview,MediaStreams")
        ]

        guard let url = urlComponents.url else {
            throw JellyfinError.invalidURL
        }

        let request = authService.authenticatedRequest(for: url)
        let (data, response) = try await authService.session.data(for: request)
        try response.validateJellyfinResponse()

        return try JSONDecoder().decode(MediaItem.self, from: data)
    }

    /// Récupère les détails d'un média spécifique (alias de getItem)
    func getItemDetails(itemId: String) async throws -> MediaItem {
        return try await getItem(itemId: itemId)
    }

    /// Récupère l'épisode suivant d'une série
    func getNextEpisode(currentItemId: String) async throws -> MediaItem? {
        let currentItem = try await getItem(itemId: currentItemId)

        guard currentItem.type == "Episode",
              let seriesId = currentItem.seriesId else {
            return nil
        }

        guard var urlComponents = URLComponents(string: "\(authService.baseURL)/Shows/\(seriesId)/Episodes") else {
            throw JellyfinError.invalidURL
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "UserId", value: authService.userId),
            URLQueryItem(name: "Fields", value: "Overview,PrimaryImageAspectRatio,MediaStreams")
        ]

        guard let url = urlComponents.url else {
            throw JellyfinError.invalidURL
        }

        let request = authService.authenticatedRequest(for: url)
        let (data, response) = try await authService.session.data(for: request)
        try response.validateJellyfinResponse()
        let itemsResponse = try JSONDecoder().decode(ItemsResponse.self, from: data)

        let episodes = itemsResponse.items.sortedByEpisodeOrder()

        guard let currentIndex = episodes.firstIndex(where: { $0.id == currentItemId }) else {
            return nil
        }

        let nextIndex = currentIndex + 1
        if nextIndex < episodes.count {
            return episodes[nextIndex]
        }

        return nil
    }

    // MARK: - Watched / Favorites

    /// Marque un média vu ou non vu ; retourne le UserData mis à jour
    /// (endpoints validés sur serveur 10.11 : POST/DELETE /UserPlayedItems/{id})
    func setPlayed(itemId: String, played: Bool) async throws -> UserData {
        try await sendUserDataToggle(path: "UserPlayedItems", itemId: itemId, enable: played)
    }

    /// Ajoute/retire un média des favoris ; retourne le UserData mis à jour
    func setFavorite(itemId: String, favorite: Bool) async throws -> UserData {
        try await sendUserDataToggle(path: "UserFavoriteItems", itemId: itemId, enable: favorite)
    }

    private func sendUserDataToggle(path: String, itemId: String, enable: Bool) async throws -> UserData {
        guard let url = URL(string: "\(authService.baseURL)/\(path)/\(itemId)") else {
            throw JellyfinError.invalidURL
        }

        var request = authService.authenticatedRequest(for: url)
        request.httpMethod = enable ? "POST" : "DELETE"

        let (data, response) = try await authService.session.data(for: request)
        try response.validateJellyfinResponse()

        return try JSONDecoder().decode(UserData.self, from: data)
    }

    /// Récupère les favoris de l'utilisateur (rangée d'accueil)
    func getFavoriteItems(limit: Int = 10) async throws -> [MediaItem] {
        guard var urlComponents = URLComponents(string: "\(authService.baseURL)/Users/\(authService.userId)/Items") else {
            throw JellyfinError.invalidURL
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "Filters", value: "IsFavorite"),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "IncludeItemTypes", value: "Movie,Series,Episode"),
            URLQueryItem(name: "SortBy", value: "DateCreated"),
            URLQueryItem(name: "SortOrder", value: "Descending"),
            URLQueryItem(name: "Limit", value: "\(limit)"),
            URLQueryItem(name: "Fields", value: "Overview,PrimaryImageAspectRatio,MediaStreams,UserData")
        ]

        guard let url = urlComponents.url else {
            throw JellyfinError.invalidURL
        }

        let request = authService.authenticatedRequest(for: url)
        let (data, response) = try await authService.session.data(for: request)
        try response.validateJellyfinResponse()
        let itemsResponse = try JSONDecoder().decode(ItemsResponse.self, from: data)

        return itemsResponse.items
    }

    // MARK: - Music Items

    /// Récupère les artistes d'une bibliothèque musicale
    func getMusicArtists(parentId: String, limit: Int? = nil) async throws -> [MediaItem] {
        return try await getItems(
            parentId: parentId,
            includeItemTypes: ["MusicArtist"],
            recursive: false,
            limit: limit
        )
    }

    /// Récupère les albums d'un artiste
    func getArtistAlbums(artistId: String) async throws -> [MediaItem] {
        return try await getItems(
            parentId: artistId,
            includeItemTypes: ["MusicAlbum"],
            recursive: false,
            limit: nil
        )
    }

    /// Récupère les pistes d'un album
    func getAlbumTracks(albumId: String) async throws -> [MediaItem] {
        return try await getItems(
            parentId: albumId,
            includeItemTypes: ["Audio"],
            recursive: false,
            limit: nil
        )
    }

    /// Récupère les albums récents d'une bibliothèque musicale
    func getLatestAlbums(parentId: String, limit: Int = 16) async throws -> [MediaItem] {
        return try await getLatestItems(parentId: parentId, limit: limit)
    }

    // MARK: - Images

    /// Génère l'URL de l'image d'un média avec type spécifique
    func getImageURL(itemId: String, imageType: String = "Primary", maxWidth: Int = 400) -> String {
        return "\(authService.baseURL)/Items/\(itemId)/Images/\(imageType)?maxWidth=\(maxWidth)"
    }

    /// Génère l'URL de l'image principale d'un média
    func getPrimaryImageURL(itemId: String, maxWidth: Int = 400) -> String {
        return "\(authService.baseURL)/Items/\(itemId)/Images/Primary?maxWidth=\(maxWidth)"
    }

    /// Génère l'URL de l'image backdrop d'un média
    func getBackdropImageURL(itemId: String, maxWidth: Int = 1920) -> String {
        return "\(authService.baseURL)/Items/\(itemId)/Images/Backdrop?maxWidth=\(maxWidth)"
    }

}

// MARK: - Episode Ordering

extension Array where Element == MediaItem {
    /// Trie des épisodes par saison (parentIndexNumber) puis numéro (indexNumber)
    /// Logique pure, testée dans xfinnTests/EpisodeOrderingTests
    func sortedByEpisodeOrder() -> [MediaItem] {
        sorted { lhs, rhs in
            if lhs.parentIndexNumber == rhs.parentIndexNumber {
                return (lhs.indexNumber ?? 0) < (rhs.indexNumber ?? 0)
            }
            return (lhs.parentIndexNumber ?? 0) < (rhs.parentIndexNumber ?? 0)
        }
    }
}
