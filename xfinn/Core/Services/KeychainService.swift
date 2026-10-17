//
//  KeychainService.swift
//  xfinn
//
//  Created by Dorian Galiana on 05/01/2026.
//  Updated: Added username/password storage per server
//

import Foundation
import Security
import CryptoKit

/// Service pour stocker les credentials de manière sécurisée dans le Keychain
final class KeychainService {

    static let shared = KeychainService()

    private let serviceName = "com.xfinn.jellyfin"
    private let credentialsServiceName = "com.xfinn.jellyfin.credentials"

    private enum Keys {
        static let accessToken = "accessToken"
        static let userId = "userId"
        static let serverURL = "serverURL"
        static let lastUsername = "lastUsername"
    }

    private init() {}

    // MARK: - Public API (Session courante)

    /// Token d'accès Jellyfin
    var accessToken: String? {
        get { getString(forKey: Keys.accessToken) }
        set {
            if let value = newValue {
                setString(value, forKey: Keys.accessToken)
            } else {
                deleteItem(forKey: Keys.accessToken)
            }
        }
    }

    /// ID de l'utilisateur Jellyfin
    var userId: String? {
        get { getString(forKey: Keys.userId) }
        set {
            if let value = newValue {
                setString(value, forKey: Keys.userId)
            } else {
                deleteItem(forKey: Keys.userId)
            }
        }
    }

    /// URL du serveur Jellyfin
    var serverURL: String? {
        get { getString(forKey: Keys.serverURL) }
        set {
            if let value = newValue {
                setString(value, forKey: Keys.serverURL)
            } else {
                deleteItem(forKey: Keys.serverURL)
            }
        }
    }

    /// Dernier username utilisé (pour pré-remplir le formulaire)
    var lastUsername: String? {
        get { getString(forKey: Keys.lastUsername) }
        set {
            if let value = newValue {
                setString(value, forKey: Keys.lastUsername)
            } else {
                deleteItem(forKey: Keys.lastUsername)
            }
        }
    }

    // MARK: - Credentials par serveur (username uniquement)
    // Le mot de passe n'est jamais persisté : seul le token de session l'est.

    /// Sauvegarde le nom d'utilisateur pour un serveur donné
    func saveUsername(_ username: String, forServer serverURL: String) {
        let serverKey = serverURL.keychainSafeKey
        setCredential(username, forKey: "\(serverKey)_username")
        lastUsername = username
    }

    /// Récupère le nom d'utilisateur pour un serveur donné
    /// Purge au passage tout mot de passe stocké par une ancienne version de l'app
    func getUsername(forServer serverURL: String) -> String? {
        purgeStoredPassword(forServer: serverURL)

        let serverKey = serverURL.keychainSafeKey
        if let username = getCredential(forKey: "\(serverKey)_username") {
            return username
        }

        // Migration automatique depuis l'ancien format de clé
        let legacyKey = serverURL.legacyKeychainSafeKey
        guard let legacyUsername = getCredential(forKey: "\(legacyKey)_username") else {
            return nil
        }

        saveUsername(legacyUsername, forServer: serverURL)
        deleteCredential(forKey: "\(legacyKey)_username")
        #if DEBUG
        print("[KeychainService] Migrated legacy username for \(serverURL.redactedForLogs)")
        #endif
        return legacyUsername
    }

    /// Supprime tout mot de passe persisté par une ancienne version de l'app
    func purgeStoredPassword(forServer serverURL: String) {
        deleteCredential(forKey: "\(serverURL.keychainSafeKey)_password")
        deleteCredential(forKey: "\(serverURL.legacyKeychainSafeKey)_password")
    }

    /// Purge les mots de passe persistés pour une liste de serveurs
    func purgeStoredPasswords(forServers serverURLs: [String]) {
        for url in serverURLs {
            purgeStoredPassword(forServer: url)
        }
    }

    /// Supprime les credentials pour un serveur donné
    func deleteCredentials(forServer serverURL: String) {
        let serverKey = serverURL.keychainSafeKey
        deleteCredential(forKey: "\(serverKey)_username")
        deleteCredential(forKey: "\(serverKey)_password")
        let legacyKey = serverURL.legacyKeychainSafeKey
        deleteCredential(forKey: "\(legacyKey)_username")
        deleteCredential(forKey: "\(legacyKey)_password")
    }

    /// Efface toutes les credentials Jellyfin (session courante uniquement)
    func clearAll() {
        deleteItem(forKey: Keys.accessToken)
        deleteItem(forKey: Keys.userId)
        deleteItem(forKey: Keys.serverURL)
        // Note: on garde les usernames sauvegardés par serveur
    }

    /// Efface TOUT (session + usernames sauvegardés)
    func clearEverything() {
        clearAll()
        deleteItem(forKey: Keys.lastUsername)
        // Les usernames par serveur ne sont pas trackés individuellement ;
        // les mots de passe, eux, ne sont plus jamais persistés
    }

    // MARK: - Private Keychain Operations

    private func getString(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    @discardableResult
    private func setString(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Supprimer l'ancien élément s'il existe
        deleteItem(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    @discardableResult
    private func deleteItem(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Credentials Storage (service séparé pour les mots de passe)

    private func getCredential(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: credentialsServiceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    @discardableResult
    private func setCredential(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Supprimer l'ancien élément s'il existe
        deleteCredential(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: credentialsServiceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    @discardableResult
    private func deleteCredential(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: credentialsServiceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// MARK: - String Extension pour clé Keychain

extension String {
    /// Matériau normalisé pour la dérivation de clé Keychain
    var normalizedServerKeyMaterial: String {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed) else {
            return trimmed.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }

        components.scheme = components.scheme?.lowercased()
        components.host = components.host?.lowercased()
        components.fragment = nil
        components.query = nil

        if components.path.hasSuffix("/") && components.path.count > 1 {
            components.path = String(components.path.dropLast())
        }

        return (components.string ?? trimmed)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    /// Convertit une URL en clé safe pour le Keychain
    var keychainSafeKey: String {
        let digest = SHA256.hash(data: Data(normalizedServerKeyMaterial.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Ancien format de clé conservé pour la migration des credentials existants
    var legacyKeychainSafeKey: String {
        let allowedCharacters = CharacterSet.alphanumerics
        return self.unicodeScalars
            .map { allowedCharacters.contains($0) ? String($0) : "_" }
            .joined()
    }

    /// URL masquée pour logs DEBUG (évite d'afficher le chemin complet)
    var redactedForLogs: String {
        guard let components = URLComponents(string: self),
              let host = components.host else {
            return "<unknown-host>"
        }
        let scheme = components.scheme ?? "unknown"
        return "\(scheme)://\(host)"
    }
}
