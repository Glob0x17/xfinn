//
//  MediaService.swift
//  xfinn
//
//  Created by Claude on 05/01/2026.
//  Extracted from JellyfinService for better separation of concerns.
//

import Foundation

/// Service de gestion des médias Jellyfin
final class MediaService {

    // MARK: - Properties

    private let authService: AuthService

    // MARK: - Initialization

    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - Libraries

    /// Récupère toutes les bibliothèques de l'utilisateur
    func getLibraries() async throws -> [LibraryItem] {
        guard let url = URL(string: "\(authService.baseURL)/Users/\(authService.userId)/Views") else {
            throw JellyfinError.invalidURL
        }

        let request = authService.authenticatedRequest(for: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ItemsResponse.self, from: data)

        return response.items.map { item in
            LibraryItem(
                id: item.id,
                name: item.name,
                collectionType: item.type,
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
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ItemsResponse.self, from: data)

        return response.items
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
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ItemsResponse.self, from: data)

        return response.items
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
        let (data, _) = try await URLSession.shared.data(for: request)

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
            queryItems.append(URLQueryItem(name: "IncludeItemTypes", value: "Movie,Series,Episode"))
        }

        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw JellyfinError.invalidURL
        }

        let request = authService.authenticatedRequest(for: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ItemsResponse.self, from: data)

        return response.items
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
        let (data, _) = try await URLSession.shared.data(for: request)

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
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ItemsResponse.self, from: data)

        let episodes = response.items.sorted { lhs, rhs in
            if lhs.parentIndexNumber == rhs.parentIndexNumber {
                return (lhs.indexNumber ?? 0) < (rhs.indexNumber ?? 0)
            }
            return (lhs.parentIndexNumber ?? 0) < (rhs.parentIndexNumber ?? 0)
        }

        guard let currentIndex = episodes.firstIndex(where: { $0.id == currentItemId }) else {
            return nil
        }

        let nextIndex = currentIndex + 1
        if nextIndex < episodes.count {
            return episodes[nextIndex]
        }

        return nil
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
