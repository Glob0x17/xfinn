//
//  ServerItem.swift
//  xfinn
//
//  Created by Dorian Galiana on 11/01/2026.
//

import Foundation

/// Représente un serveur Jellyfin (découvert ou récent)
struct ServerItem: Identifiable, Codable, Hashable {
    /// Identifiant unique du serveur (fourni par Jellyfin)
    let id: String

    /// Nom du serveur
    let name: String

    /// URL complète du serveur
    let url: String

    /// Date de dernière connexion (nil si jamais connecté)
    var lastConnected: Date?

    /// Source du serveur
    var source: ServerSource

    /// Source d'où provient le serveur
    enum ServerSource: String, Codable {
        case discovered  // Trouvé via UDP broadcast
        case recent      // Serveur récemment utilisé
        case manual      // Saisi manuellement
    }

    /// URL formatée pour l'affichage (sans http://)
    var displayURL: String {
        url.replacingOccurrences(of: "http://", with: "")
           .replacingOccurrences(of: "https://", with: "")
    }

    /// Indique si le serveur utilise HTTPS
    var isSecure: Bool {
        url.lowercased().hasPrefix("https://")
    }
}

// MARK: - Jellyfin Discovery Response

/// Réponse JSON du serveur Jellyfin lors de la découverte UDP
struct JellyfinDiscoveryResponse: Codable {
    let address: String
    let id: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case address = "Address"
        case id = "Id"
        case name = "Name"
    }

    /// Convertit en ServerItem
    var asServerItem: ServerItem {
        ServerItem(
            id: id,
            name: name,
            url: address,
            lastConnected: nil,
            source: .discovered
        )
    }
}
