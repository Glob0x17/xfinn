//
//  AuthService.swift
//  xfinn
//
//  Created by Dorian Galiana on 05/01/2026.
//  Extracted from JellyfinService for better separation of concerns.
//

import Foundation

/// Service d'authentification Jellyfin
/// @MainActor: l'état mutable (baseURL/accessToken/userId) est lu par
/// MediaService/PlaybackService pendant que authenticate()/logout() le mutent ;
/// l'isolation sur le main actor élimine ces courses de données
@MainActor
final class AuthService {

    // MARK: - Properties

    private(set) var baseURL: String = ""
    private(set) var accessToken: String = ""
    private(set) var userId: String = ""

    let deviceId: String
    let clientName = "xfinn"
    let clientVersion = "1.0.0"

    /// Session API partagée par tous les services : timeout court (une app TV
    /// ne doit pas geler 60 s sur un serveur éteint), pas de cache HTTP pour
    /// les réponses JSON (données de bibliothèque toujours fraîches)
    let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }()

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
        self.baseURL = try validateAndNormalizeURL(serverURL)

        guard let url = URL(string: "\(baseURL)/System/Info/Public") else {
            throw JellyfinError.invalidURL
        }

        var request = URLRequest(url: url)
        request.addJellyfinHeaders(clientName: clientName, deviceId: deviceId, version: clientVersion)

        let (data, response) = try await session.data(for: request)

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

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw JellyfinError.authenticationFailed
        }

        let authResult = try JSONDecoder().decode(AuthenticationResult.self, from: data)

        return completeAuthentication(authResult)
    }

    /// Finalise une authentification réussie (login classique ou Quick Connect) :
    /// installe la session en mémoire et la persiste dans le Keychain
    private func completeAuthentication(_ result: AuthenticationResult) -> User {
        self.accessToken = result.accessToken
        self.userId = result.user.id

        saveCredentials()

        return result.user
    }

    // MARK: - Quick Connect

    /// Indique si le serveur a Quick Connect activé
    /// Toute erreur (serveur ancien, 404, réseau) est traitée comme "non disponible"
    func isQuickConnectEnabled() async -> Bool {
        guard let url = URL(string: "\(baseURL)/QuickConnect/Enabled") else {
            return false
        }

        var request = URLRequest(url: url)
        request.addJellyfinHeaders(clientName: clientName, deviceId: deviceId, version: clientVersion)

        guard let (data, response) = try? await session.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return false
        }

        return (try? JSONDecoder().decode(Bool.self, from: data)) ?? false
    }

    /// Démarre une session Quick Connect et retourne le code à afficher
    func initiateQuickConnect() async throws -> QuickConnectResult {
        guard let url = URL(string: "\(baseURL)/QuickConnect/Initiate") else {
            throw JellyfinError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addJellyfinHeaders(clientName: clientName, deviceId: deviceId, version: clientVersion)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw JellyfinError.connectionFailed
        }

        return try JSONDecoder().decode(QuickConnectResult.self, from: data)
    }

    /// Vérifie si le code a été approuvé côté serveur
    /// - Returns: true dès que l'utilisateur a validé le code
    /// - Throws: `JellyfinError.quickConnectExpired` si le secret n'est plus valide (404)
    ///   Ne mappe JAMAIS vers authenticationFailed : un échec de polling ne doit
    ///   pas déclencher la déconnexion globale gérée par JellyfinService
    func checkQuickConnect(secret: String) async throws -> Bool {
        guard var components = URLComponents(string: "\(baseURL)/QuickConnect/Connect") else {
            throw JellyfinError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "secret", value: secret)]

        guard let url = components.url else {
            throw JellyfinError.invalidURL
        }

        var request = URLRequest(url: url)
        request.addJellyfinHeaders(clientName: clientName, deviceId: deviceId, version: clientVersion)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw JellyfinError.connectionFailed
        }

        if httpResponse.statusCode == 404 {
            throw JellyfinError.quickConnectExpired
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw JellyfinError.connectionFailed
        }

        return try JSONDecoder().decode(QuickConnectResult.self, from: data).authenticated
    }

    /// Échange un secret Quick Connect approuvé contre une session authentifiée
    func authenticateWithQuickConnect(secret: String) async throws -> User {
        guard let url = URL(string: "\(baseURL)/Users/AuthenticateWithQuickConnect") else {
            throw JellyfinError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addJellyfinHeaders(clientName: clientName, deviceId: deviceId, version: clientVersion)
        request.httpBody = try JSONSerialization.data(withJSONObject: ["Secret": secret])

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw JellyfinError.quickConnectExpired
        }

        let authResult = try JSONDecoder().decode(AuthenticationResult.self, from: data)

        return completeAuthentication(authResult)
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

        // Sessions antérieures à l'extension Top Shelf : peupler le miroir
        mirrorSessionToAppGroup()

        return true
    }

    /// Sauvegarde les identifiants dans Keychain
    private func saveCredentials() {
        UserDefaults.standard.jellyfinServerURL = baseURL
        UserDefaults.standard.jellyfinAccessToken = accessToken
        UserDefaults.standard.jellyfinUserId = userId

        mirrorSessionToAppGroup()
    }

    // MARK: - App Group (extension Top Shelf)

    static let appGroupIdentifier = "group.doriang.xfinn"

    /// Miroir de la session dans le conteneur partagé, lu par l'extension
    /// Top Shelf (qui n'a pas accès au Keychain de l'app).
    /// Compromis assumé : token en clair dans le conteneur app group (tvOS,
    /// local, token révocable côté serveur) — durcissement keychain
    /// access-group envisagé en follow-up.
    private func mirrorSessionToAppGroup() {
        guard let shared = UserDefaults(suiteName: Self.appGroupIdentifier) else { return }
        shared.set(baseURL, forKey: "serverURL")
        shared.set(accessToken, forKey: "accessToken")
        shared.set(userId, forKey: "userId")
        shared.set(deviceId, forKey: "deviceId")
    }

    private func clearAppGroupSession() {
        guard let shared = UserDefaults(suiteName: Self.appGroupIdentifier) else { return }
        shared.removeObject(forKey: "serverURL")
        shared.removeObject(forKey: "accessToken")
        shared.removeObject(forKey: "userId")
        shared.removeObject(forKey: "deviceId")
    }

    /// Déconnecte l'utilisateur et efface les données sauvegardées
    func logout() {
        UserDefaults.standard.clearJellyfinData()
        clearAppGroupSession()

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

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw JellyfinError.connectionFailed
        }

        // 401 = token révoqué/invalide, à distinguer d'une simple erreur réseau
        if httpResponse.statusCode == 401 {
            throw JellyfinError.authenticationFailed
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw JellyfinError.connectionFailed
        }

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

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw JellyfinError.responseError("Failed to register device capabilities")
        }
    }

    // MARK: - Request Helpers

    /// Crée une URLRequest authentifiée
    func authenticatedRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.addAuthorizationHeader(token: accessToken, clientName: clientName, deviceId: deviceId, version: clientVersion)
        return request
    }

    // MARK: - URL Validation

    /// Valide et normalise une URL de serveur
    /// - Parameter urlString: L'URL entrée par l'utilisateur
    /// - Returns: L'URL normalisée (avec protocole, sans slash final)
    /// - Throws: JellyfinError.invalidURL si l'URL est invalide
    private func validateAndNormalizeURL(_ urlString: String) throws -> String {
        // Supprimer les espaces
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)

        // Vérifier que ce n'est pas vide
        guard !trimmed.isEmpty else {
            throw JellyfinError.invalidURL
        }

        var normalized = trimmed

        // Ajouter le protocole si manquant (HTTPS par défaut)
        if !normalized.lowercased().hasPrefix("http://") && !normalized.lowercased().hasPrefix("https://") {
            normalized = "https://\(normalized)"
        }

        // Supprimer le slash final si présent
        if normalized.hasSuffix("/") {
            normalized = String(normalized.dropLast())
        }

        // Vérifier que l'URL est valide
        guard URL(string: normalized) != nil else {
            throw JellyfinError.invalidURL
        }

        return normalized
    }
}
