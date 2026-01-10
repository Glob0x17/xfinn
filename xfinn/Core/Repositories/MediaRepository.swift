//
//  MediaRepository.swift
//  xfinn
//
//  Created by Refactoring Phase 1
//

import Foundation

/// Repository de médias - Wrapper autour de JellyfinService
/// Permet une abstraction pour les ViewModels et facilite les tests
final class MediaRepository: MediaRepositoryProtocol {
    // MARK: - Properties

    private let jellyfinService: JellyfinService

    // MARK: - Initialization

    init(jellyfinService: JellyfinService) {
        self.jellyfinService = jellyfinService
    }

    // MARK: - MediaRepositoryProtocol

    func getLibraries() async throws -> [LibraryItem] {
        try await jellyfinService.getLibraries()
    }

    func getItems(
        parentId: String,
        includeItemTypes: [String]? = nil,
        recursive: Bool = false,
        limit: Int? = nil
    ) async throws -> [MediaItem] {
        try await jellyfinService.getItems(
            parentId: parentId,
            includeItemTypes: includeItemTypes,
            recursive: recursive,
            limit: limit
        )
    }

    func getResumeItems(limit: Int = 12) async throws -> [MediaItem] {
        try await jellyfinService.getResumeItems(limit: limit)
    }

    func getLatestItems(parentId: String? = nil, limit: Int = 16) async throws -> [MediaItem] {
        try await jellyfinService.getLatestItems(parentId: parentId, limit: limit)
    }

    func search(query: String, includeItemTypes: [String]? = nil, limit: Int = 50) async throws -> [MediaItem] {
        try await jellyfinService.search(query: query, includeItemTypes: includeItemTypes, limit: limit)
    }

    func getItem(itemId: String) async throws -> MediaItem {
        try await jellyfinService.getItem(itemId: itemId)
    }

    func getItemDetails(itemId: String) async throws -> MediaItem {
        try await jellyfinService.getItemDetails(itemId: itemId)
    }

    func getNextEpisode(currentItemId: String) async throws -> MediaItem? {
        try await jellyfinService.getNextEpisode(currentItemId: currentItemId)
    }

    func getImageURL(itemId: String, imageType: String = "Primary", maxWidth: Int = 400) -> String {
        jellyfinService.getImageURL(itemId: itemId, imageType: imageType, maxWidth: maxWidth)
    }

    func getPrimaryImageURL(itemId: String, maxWidth: Int = 400) -> String {
        jellyfinService.getPrimaryImageURL(itemId: itemId, maxWidth: maxWidth)
    }

    func getBackdropImageURL(itemId: String, maxWidth: Int = 1920) -> String {
        jellyfinService.getBackdropImageURL(itemId: itemId, maxWidth: maxWidth)
    }
}

// MARK: - Cached Media Repository

/// Version avec cache du MediaRepository (pour optimisation future)
final class CachedMediaRepository: MediaRepositoryProtocol {
    // MARK: - Properties

    private let repository: MediaRepository
    private let cache = NSCache<NSString, CacheEntry>()

    /// Durée de validité du cache en secondes
    private let cacheDuration: TimeInterval

    // MARK: - Cache Entry

    private class CacheEntry {
        let data: Any
        let timestamp: Date

        init(data: Any) {
            self.data = data
            self.timestamp = Date()
        }

        func isValid(duration: TimeInterval) -> Bool {
            Date().timeIntervalSince(timestamp) < duration
        }
    }

    // MARK: - Initialization

    init(jellyfinService: JellyfinService, cacheDuration: TimeInterval = 300) {
        self.repository = MediaRepository(jellyfinService: jellyfinService)
        self.cacheDuration = cacheDuration

        // Configuration du cache
        cache.countLimit = 100
    }

    // MARK: - Cache Helpers

    private func getCached<T>(_ key: String) -> T? {
        guard let entry = cache.object(forKey: key as NSString),
              entry.isValid(duration: cacheDuration) else {
            return nil
        }
        return entry.data as? T
    }

    private func setCache<T>(_ key: String, value: T) {
        cache.setObject(CacheEntry(data: value), forKey: key as NSString)
    }

    /// Invalide tout le cache
    func invalidateCache() {
        cache.removeAllObjects()
    }

    /// Invalide une entrée spécifique
    func invalidate(_ key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    // MARK: - MediaRepositoryProtocol (avec cache)

    func getLibraries() async throws -> [LibraryItem] {
        let cacheKey = "libraries"

        if let cached: [LibraryItem] = getCached(cacheKey) {
            return cached
        }

        let result = try await repository.getLibraries()
        setCache(cacheKey, value: result)
        return result
    }

    func getItems(
        parentId: String,
        includeItemTypes: [String]? = nil,
        recursive: Bool = false,
        limit: Int? = nil
    ) async throws -> [MediaItem] {
        // Pas de cache pour les items (trop variable)
        try await repository.getItems(
            parentId: parentId,
            includeItemTypes: includeItemTypes,
            recursive: recursive,
            limit: limit
        )
    }

    func getResumeItems(limit: Int = 12) async throws -> [MediaItem] {
        let cacheKey = "resume_\(limit)"

        if let cached: [MediaItem] = getCached(cacheKey) {
            return cached
        }

        let result = try await repository.getResumeItems(limit: limit)
        setCache(cacheKey, value: result)
        return result
    }

    func getLatestItems(parentId: String? = nil, limit: Int = 16) async throws -> [MediaItem] {
        let cacheKey = "latest_\(parentId ?? "all")_\(limit)"

        if let cached: [MediaItem] = getCached(cacheKey) {
            return cached
        }

        let result = try await repository.getLatestItems(parentId: parentId, limit: limit)
        setCache(cacheKey, value: result)
        return result
    }

    func search(query: String, includeItemTypes: [String]? = nil, limit: Int = 50) async throws -> [MediaItem] {
        // Pas de cache pour la recherche
        try await repository.search(query: query, includeItemTypes: includeItemTypes, limit: limit)
    }

    func getItem(itemId: String) async throws -> MediaItem {
        let cacheKey = "item_\(itemId)"

        if let cached: MediaItem = getCached(cacheKey) {
            return cached
        }

        let result = try await repository.getItem(itemId: itemId)
        setCache(cacheKey, value: result)
        return result
    }

    func getItemDetails(itemId: String) async throws -> MediaItem {
        let cacheKey = "itemDetails_\(itemId)"

        if let cached: MediaItem = getCached(cacheKey) {
            return cached
        }

        let result = try await repository.getItemDetails(itemId: itemId)
        setCache(cacheKey, value: result)
        return result
    }

    func getNextEpisode(currentItemId: String) async throws -> MediaItem? {
        // Pas de cache pour l'épisode suivant (dépend de la progression)
        try await repository.getNextEpisode(currentItemId: currentItemId)
    }

    func getImageURL(itemId: String, imageType: String = "Primary", maxWidth: Int = 400) -> String {
        repository.getImageURL(itemId: itemId, imageType: imageType, maxWidth: maxWidth)
    }

    func getPrimaryImageURL(itemId: String, maxWidth: Int = 400) -> String {
        repository.getPrimaryImageURL(itemId: itemId, maxWidth: maxWidth)
    }

    func getBackdropImageURL(itemId: String, maxWidth: Int = 1920) -> String {
        repository.getBackdropImageURL(itemId: itemId, maxWidth: maxWidth)
    }
}
