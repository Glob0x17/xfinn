//
//  APIClient.swift
//  xfinn
//
//  Created by Refactoring Phase 1
//

import Foundation

// MARK: - API Client Protocol

/// Protocole pour un client API générique
protocol APIClientProtocol {
    /// Effectue une requête GET et décode la réponse
    func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem]?) async throws -> T

    /// Effectue une requête POST avec un body JSON et décode la réponse
    func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T

    /// Effectue une requête POST sans attendre de réponse décodable
    func post(_ path: String, body: [String: Any]) async throws
}

// MARK: - Jellyfin API Client

/// Client API centralisé pour les requêtes Jellyfin
final class JellyfinAPIClient: APIClientProtocol {
    // MARK: - Properties

    private let baseURL: String
    private let accessToken: String
    private let userId: String
    private let deviceId: String
    private let clientName: String
    private let clientVersion: String

    private let session: URLSession
    private let decoder: JSONDecoder

    // MARK: - Initialization

    init(
        baseURL: String,
        accessToken: String,
        userId: String,
        deviceId: String = UserDefaults.standard.deviceId,
        clientName: String = "xfinn",
        clientVersion: String = "1.0.0",
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.accessToken = accessToken
        self.userId = userId
        self.deviceId = deviceId
        self.clientName = clientName
        self.clientVersion = clientVersion
        self.session = session
        self.decoder = JSONDecoder()
    }

    // MARK: - APIClientProtocol Implementation

    func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        let url = try buildURL(path: path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addAuthorizationHeaders(to: &request)

        return try await execute(request)
    }

    func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        let url = try buildURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        addAuthorizationHeaders(to: &request)

        return try await execute(request)
    }

    func post(_ path: String, body: [String: Any]) async throws {
        let url = try buildURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        addAuthorizationHeaders(to: &request)

        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Helper Methods

    private func buildURL(path: String, queryItems: [URLQueryItem]? = nil) throws -> URL {
        var urlString = baseURL

        // Ajouter le path
        if !path.hasPrefix("/") {
            urlString += "/"
        }
        urlString += path

        guard var components = URLComponents(string: urlString) else {
            throw JellyfinError.invalidURL
        }

        if let queryItems = queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw JellyfinError.invalidURL
        }

        return url
    }

    private func addAuthorizationHeaders(to request: inout URLRequest) {
        let authHeader = "MediaBrowser Client=\"\(clientName)\", Device=\"Apple TV\", DeviceId=\"\(deviceId)\", Version=\"\(clientVersion)\", Token=\"\(accessToken)\""
        request.addValue(authHeader, forHTTPHeaderField: "X-Emby-Authorization")
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw JellyfinError.decodingError(error)
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw JellyfinError.networkError(URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401, 403:
            throw JellyfinError.authenticationFailed
        default:
            throw JellyfinError.serverError(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - API Client Factory

/// Factory pour créer des clients API configurés
enum APIClientFactory {
    /// Crée un client API à partir du JellyfinService
    static func create(from service: JellyfinService, authService: AuthService) -> JellyfinAPIClient? {
        guard !authService.serverURL.isEmpty,
              !authService.accessToken.isEmpty,
              !authService.userId.isEmpty else {
            return nil
        }

        return JellyfinAPIClient(
            baseURL: authService.serverURL,
            accessToken: authService.accessToken,
            userId: authService.userId
        )
    }
}

// MARK: - URL Builder Helper

/// Helper pour construire les URLs Jellyfin
struct JellyfinURLBuilder {
    let baseURL: String
    let userId: String

    /// Construit une URL pour les items utilisateur
    func userItems(queryItems: [URLQueryItem] = []) -> String {
        "/Users/\(userId)/Items"
    }

    /// Construit une URL pour les items à reprendre
    func resumeItems() -> String {
        "/Users/\(userId)/Items/Resume"
    }

    /// Construit une URL pour les derniers items
    func latestItems() -> String {
        "/Users/\(userId)/Items/Latest"
    }

    /// Construit une URL pour les vues utilisateur (bibliothèques)
    func userViews() -> String {
        "/Users/\(userId)/Views"
    }

    /// Construit une URL pour un item spécifique
    func item(itemId: String) -> String {
        "/Users/\(userId)/Items/\(itemId)"
    }

    /// Construit une URL pour les épisodes d'une série
    func episodes(seriesId: String) -> String {
        "/Shows/\(seriesId)/Episodes"
    }

    /// Construit une URL d'image
    func image(itemId: String, imageType: String = "Primary", maxWidth: Int = 400) -> String {
        "\(baseURL)/Items/\(itemId)/Images/\(imageType)?maxWidth=\(maxWidth)"
    }

    /// Construit une URL de stream HLS
    func stream(itemId: String, queryItems: [URLQueryItem]) -> URL? {
        var components = URLComponents(string: "\(baseURL)/Videos/\(itemId)/master.m3u8")
        components?.queryItems = queryItems
        return components?.url
    }

    /// Construit une URL de sous-titres
    func subtitles(itemId: String, mediaSourceId: String, streamIndex: Int, format: String = "vtt") -> URL? {
        URL(string: "\(baseURL)/Videos/\(itemId)/\(mediaSourceId)/Subtitles/\(streamIndex)/Stream.\(format)")
    }
}
