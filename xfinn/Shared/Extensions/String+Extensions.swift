//
//  String+Extensions.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//  Reorganized on 23/12/2025.
//

import Foundation

// MARK: - String Extensions

extension String {
    /// Valide si la chaîne est une URL valide
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.scheme != nil && url.host != nil
    }
    
    /// Nettoie une URL pour l'utilisation avec Jellyfin
    /// - Supprime les espaces blancs
    /// - Supprime les slashes finaux
    /// - Ajoute http:// si aucun schéma n'est présent
    var cleanedJellyfinURL: String {
        var cleaned = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Supprimer le slash final
        while cleaned.hasSuffix("/") {
            cleaned = String(cleaned.dropLast())
        }
        
        // Ajouter http:// si aucun schéma n'est présent
        if !cleaned.lowercased().hasPrefix("http://") && !cleaned.lowercased().hasPrefix("https://") {
            cleaned = "http://" + cleaned
        }
        
        return cleaned
    }
}
