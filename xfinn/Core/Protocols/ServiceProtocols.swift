//
//  ServiceProtocols.swift
//  xfinn
//
//  Created by Dorian Galiana on 05/02/2026.
//  Protocols for dependency injection and testability.
//

import Foundation
import Combine

// MARK: - Server Discovery Protocol

/// Protocol pour le service de découverte de serveurs
/// Permet l'injection de dépendances et facilite les tests
protocol ServerDiscoveryProtocol: ObservableObject {
    /// Serveurs découverts sur le réseau
    var discoveredServers: [ServerItem] { get }

    /// Indique si une recherche est en cours
    var isSearching: Bool { get }

    /// Démarre la découverte des serveurs
    func startDiscovery()

    /// Arrête la découverte
    func stopDiscovery()
}

// MARK: - Recent Servers Protocol

/// Protocol pour le service de gestion des serveurs récents
/// Permet l'injection de dépendances et facilite les tests
protocol RecentServersProtocol {
    /// Récupère la liste des serveurs récents
    func getRecentServers() -> [ServerItem]

    /// Ajoute ou met à jour un serveur dans les récents
    func addRecentServer(_ server: ServerItem)

    /// Ajoute un serveur à partir des infos de connexion
    func addRecentServer(id: String, name: String, url: String)

    /// Supprime un serveur des récents
    func removeServer(_ server: ServerItem)

    /// Efface tous les serveurs récents
    func clearAll()
}

// MARK: - Protocol Conformance

extension ServerDiscoveryService: ServerDiscoveryProtocol {}
extension RecentServersService: RecentServersProtocol {}
