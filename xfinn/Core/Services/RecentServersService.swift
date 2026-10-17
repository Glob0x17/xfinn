//
//  RecentServersService.swift
//  xfinn
//
//  Created by Dorian Galiana on 11/01/2026.
//

import Foundation

/// Service pour gérer l'historique des serveurs récemment utilisés
final class RecentServersService {

    static let shared = RecentServersService()

    private let userDefaults = UserDefaults.standard
    private let storageKey = "com.xfinn.recentServers"
    private let maxRecentServers = 10

    private init() {}

    // MARK: - Public API

    /// Récupère la liste des serveurs récents, triés par date de dernière connexion
    func getRecentServers() -> [ServerItem] {
        guard let data = userDefaults.data(forKey: storageKey),
              let servers = try? JSONDecoder().decode([ServerItem].self, from: data) else {
            return []
        }
        return servers.sorted { ($0.lastConnected ?? .distantPast) > ($1.lastConnected ?? .distantPast) }
    }

    /// Ajoute ou met à jour un serveur dans les récents
    func addRecentServer(_ server: ServerItem) {
        var servers = getRecentServers()

        // Supprimer si déjà présent (on va le réajouter avec la nouvelle date)
        servers.removeAll { $0.id == server.id || $0.url == server.url }

        // Créer une copie avec la date de connexion mise à jour
        var updatedServer = server
        updatedServer.lastConnected = Date()
        updatedServer.source = .recent

        // Ajouter en premier
        servers.insert(updatedServer, at: 0)

        // Limiter le nombre de serveurs
        if servers.count > maxRecentServers {
            servers = Array(servers.prefix(maxRecentServers))
        }

        saveServers(servers)
    }

    /// Ajoute un serveur à partir des infos de connexion
    func addRecentServer(id: String, name: String, url: String) {
        let server = ServerItem(
            id: id,
            name: name,
            url: url,
            lastConnected: Date(),
            source: .recent
        )
        addRecentServer(server)
    }

    /// Supprime un serveur des récents
    func removeServer(_ server: ServerItem) {
        var servers = getRecentServers()
        servers.removeAll { $0.id == server.id }
        saveServers(servers)
    }

    /// Supprime un serveur par son ID
    func removeServer(byId id: String) {
        var servers = getRecentServers()
        servers.removeAll { $0.id == id }
        saveServers(servers)
    }

    /// Efface tous les serveurs récents
    func clearAll() {
        userDefaults.removeObject(forKey: storageKey)
    }

    /// Vérifie si un serveur est dans les récents
    func hasServer(withURL url: String) -> Bool {
        getRecentServers().contains { $0.url == url }
    }

    /// Récupère un serveur par son URL
    func getServer(byURL url: String) -> ServerItem? {
        getRecentServers().first { $0.url == url }
    }

    // MARK: - Private

    private func saveServers(_ servers: [ServerItem]) {
        guard let data = try? JSONEncoder().encode(servers) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}
