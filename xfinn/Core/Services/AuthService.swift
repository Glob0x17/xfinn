//
//  AuthService.swift
//  xfinn
//
//  Created by Claude on 05/01/2026.
//  Extracted from JellyfinService for better separation of concerns.
//

import Foundation

/// Service d'authentification Jellyfin
final class AuthService {

    // MARK: - Properties

    private(set) var baseURL: String = ""
    private(set) var accessToken: String = ""
    private(set) var userId: String = ""

    let deviceId: String
    let clientName = "xfinn"
    let clientVersion = "1.0.0"

    // MARK: - Computed Properties

    var isAuthenticated: Bool {
        !accessToken.isEmpty && !userId.isEmpty && !baseURL.isEmpty
    }

    var serverURL: String {
        baseURL
    }

    // MARK: - Initialization

    init() {
        self.deviceId = UserDefaults.standard.deviceId
    }

    // MARK: - Connection

    /// Se connecte au serveur Jellyfin et récupère les informations
    func connect(to serverURL: String) async throws -> ServerInfo {
        self.baseURL = serverURL

        guard let url = URL(string: "\(baseURL)/System/Info/Public") else {
            throw JellyfinError.invalidURL
        }

        var request = URLRequest(url: url)
        request.addJellyfinHeaders(clientName: clientName, deviceId: deviceId, version: clientVersion)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw JellyfinError.connectionFailed
        }

        return try JSONDecoder().decode(ServerInfo.self, from: data)
    }

    // MARK: - Authentication

    /// Authentifie l'utilisateur avec son nom d'utilisateur et mot de passe
    func authenticate(username: String, password: String) async throws -> User {
        guard let url = URL(string: "\(baseURL)/Users/AuthenticateByName") else {
            throw JellyfinError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addJellyfinHeaders(clientName: clientName, deviceId: deviceId, version: clientVersion)

        let authBody: [String: Any] = [
            "Username": username,
            "Pw": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: authBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw JellyfinError.authenticationFailed
        }

        let authResult = try JSONDecoder().decode(AuthenticationResult.self, from: data)

        self.accessToken = authResult.accessToken
        self.userId = authResult.user.id

        saveCredentials()

        return authResult.user
    }

    // MARK: - Credentials Management

    /// Charge les identifiants sauvegardés depuis Keychain
    func loadSavedCredentials() -> Bool {
        guard let savedURL = UserDefaults.standard.jellyfinServerURL,
              let savedToken = UserDefaults.standard.jellyfinAccessToken,
              let savedUserId = UserDefaults.standard.jellyfinUserId else {
            return false
        }

        self.baseURL = savedURL
        self.accessToken = savedToken
        self.userId = savedUserId

        return true
    }

    /// Sauvegarde les identifiants dans Keychain
    private func saveCredentials() {
        UserDefaults.standard.jellyfinServerURL = baseURL
        UserDefaults.standard.jellyfinAccessToken = accessToken
        UserDefaults.standard.jellyfinUserId = userId
    }

    /// Déconnecte l'utilisateur et efface les données sauvegardées
    func logout() {
        UserDefaults.standard.clearJellyfinData()

        self.accessToken = ""
        self.userId = ""
        self.baseURL = ""
    }

    // MARK: - User Management

    /// Charge les informations de l'utilisateur actuel
    func loadCurrentUser() async throws -> User {
        guard let url = URL(string: "\(baseURL)/Users/\(userId)") else {
            throw JellyfinError.invalidURL
        }

        var request = URLRequest(url: url)
        request.addAuthorizationHeader(token: accessToken, clientName: clientName, deviceId: deviceId, version: clientVersion)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(User.self, from: data)
    }

    // MARK: - Device Capabilities

    /// Enregistre les capacités du device auprès du serveur
    func registerDeviceCapabilities() async throws {
        guard let url = URL(string: "\(baseURL)/Sessions/Capabilities/Full") else {
            throw JellyfinError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addAuthorizationHeader(token: accessToken, clientName: clientName, deviceId: deviceId, version: clientVersion)

        let capabilities: [String: Any] = [
            "PlayableMediaTypes": ["Video", "Audio"],
            "SupportedCommands": [
                "Play",
                "Playstate",
                "PlayNext",
                "PlayMediaSource"
            ],
            "SupportsMediaControl": true,
            "SupportsPersistentIdentifier": true
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: capabilities)

        let (_, _) = try await URLSession.shared.data(for: request)
    }

    // MARK: - Request Helpers

    /// Crée une URLRequest authentifiée
    func authenticatedRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.addAuthorizationHeader(token: accessToken, clientName: clientName, deviceId: deviceId, version: clientVersion)
        return request
    }
}
