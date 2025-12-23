//
//  UserDefaults+Extensions.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//  Reorganized on 23/12/2025.
//

import Foundation

// MARK: - UserDefaults Extensions

extension UserDefaults {
    private enum Keys {
        static let serverURL = "jellyfinServerURL"
        static let accessToken = "jellyfinAccessToken"
        static let userId = "jellyfinUserId"
        static let deviceId = "deviceId"
        static let preferredStreamQuality = "preferredStreamQuality"
    }
    
    /// URL du serveur Jellyfin sauvegardé
    var jellyfinServerURL: String? {
        get { string(forKey: Keys.serverURL) }
        set { set(newValue, forKey: Keys.serverURL) }
    }
    
    /// Token d'accès Jellyfin sauvegardé
    var jellyfinAccessToken: String? {
        get { string(forKey: Keys.accessToken) }
        set { set(newValue, forKey: Keys.accessToken) }
    }
    
    /// ID de l'utilisateur Jellyfin sauvegardé
    var jellyfinUserId: String? {
        get { string(forKey: Keys.userId) }
        set { set(newValue, forKey: Keys.userId) }
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
        removeObject(forKey: Keys.serverURL)
        removeObject(forKey: Keys.accessToken)
        removeObject(forKey: Keys.userId)
        // Ne pas supprimer deviceId et preferredStreamQuality
    }
}
