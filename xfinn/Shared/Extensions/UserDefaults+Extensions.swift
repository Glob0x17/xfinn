//
//  UserDefaults+Extensions.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//  Reorganized on 23/12/2025.
//  Updated 05/01/2026: Migration credentials sensibles vers Keychain
//

import Foundation

// MARK: - UserDefaults Extensions

extension UserDefaults {
    private enum Keys {
        static let deviceId = "deviceId"
        static let preferredStreamQuality = "preferredStreamQuality"
        // Note: serverURL, accessToken et userId sont maintenant dans Keychain
    }

    /// URL du serveur Jellyfin (stocké dans Keychain)
    var jellyfinServerURL: String? {
        get { KeychainService.shared.serverURL }
        set { KeychainService.shared.serverURL = newValue }
    }

    /// Token d'accès Jellyfin (stocké dans Keychain)
    var jellyfinAccessToken: String? {
        get { KeychainService.shared.accessToken }
        set { KeychainService.shared.accessToken = newValue }
    }

    /// ID de l'utilisateur Jellyfin (stocké dans Keychain)
    var jellyfinUserId: String? {
        get { KeychainService.shared.userId }
        set { KeychainService.shared.userId = newValue }
    }

    /// ID unique de l'appareil (généré automatiquement si inexistant)
    var deviceId: String {
        if let id = string(forKey: Keys.deviceId) {
            return id
        }
        let id = UUID().uuidString
        set(id, forKey: Keys.deviceId)
        return id
    }

    /// Qualité de streaming préférée
    var preferredStreamQuality: String? {
        get { string(forKey: Keys.preferredStreamQuality) }
        set { set(newValue, forKey: Keys.preferredStreamQuality) }
    }

    /// Efface toutes les données Jellyfin (utile lors de la déconnexion)
    func clearJellyfinData() {
        KeychainService.shared.clearAll()
        // Ne pas supprimer deviceId et preferredStreamQuality
    }
}
