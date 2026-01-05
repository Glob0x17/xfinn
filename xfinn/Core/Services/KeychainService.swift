//
//  KeychainService.swift
//  xfinn
//
//  Created by Claude on 05/01/2026.
//

import Foundation
import Security

/// Service pour stocker les credentials de manière sécurisée dans le Keychain
final class KeychainService {

    static let shared = KeychainService()

    private let serviceName = "com.xfinn.jellyfin"

    private enum Keys {
        static let accessToken = "accessToken"
        static let userId = "userId"
        static let serverURL = "serverURL"
    }

    private init() {}

    // MARK: - Public API

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

    /// Efface toutes les credentials Jellyfin
    func clearAll() {
        deleteItem(forKey: Keys.accessToken)
        deleteItem(forKey: Keys.userId)
        deleteItem(forKey: Keys.serverURL)
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
}
