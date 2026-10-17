//
//  String+Extensions.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//  Reorganized on 23/12/2025.
//  18/08/2026: moved Jellyfin URL variant/normalization logic here from
//  LoginView (pure, security-sensitive logic — kept out of view code so it
//  can be unit-tested). Removed dead isValidURL/cleanedJellyfinURL (the
//  latter added an implicit http:// prefix, contrary to the HTTPS-first
//  policy below).
//

import Foundation

// MARK: - Localization

extension String {
    /// Returns the localized version of the string
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// Returns the localized string with format arguments
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}

// MARK: - Jellyfin Server URL Handling

extension String {
    /// Génère une liste de variantes d'URL à essayer pour la connexion Jellyfin
    /// L'ordre est optimisé pour essayer les cas les plus probables en premier
    /// Politique de sécurité : HTTP n'est jamais tenté implicitement pour un
    /// domaine public — uniquement pour les IP privées (RFC 1918) ou si
    /// l'utilisateur l'a tapé explicitement.
    /// Exemples pour "jellyfin.example.com":
    /// → ["https://jellyfin.example.com", "https://jellyfin.example.com:8920"]
    /// Exemples pour "192.168.1.10":
    /// → ["http://192.168.1.10:8096", "http://192.168.1.10", "https://192.168.1.10"]
    func jellyfinURLVariants() -> [String] {
        let input = self.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return [] }

        var variants: [String] = []
        let lowercased = input.lowercased()

        // Déterminer le schéma et le host
        let hasHTTPS = lowercased.hasPrefix("https://")
        let hasHTTP = lowercased.hasPrefix("http://")
        let hasScheme = hasHTTPS || hasHTTP

        // Extraire le host sans schéma
        var hostPart = input
        if hasHTTPS {
            hostPart = String(input.dropFirst(8)) // "https://".count
        } else if hasHTTP {
            hostPart = String(input.dropFirst(7)) // "http://".count
        }

        // Vérifier si un port est déjà spécifié
        let hasExplicitPort = hostPart.contains(":") && !hostPart.hasPrefix("[") // Éviter confusion avec IPv6

        // Vérifier si c'est une IP locale
        let hostWithoutPort = hostPart.split(separator: ":").first.map(String.init) ?? hostPart
        let hostWithoutPath = hostWithoutPort.split(separator: "/").first.map(String.init) ?? hostWithoutPort
        let isLocalIP = hostWithoutPath.isPrivateIPAddress

        // Si l'utilisateur a spécifié un schéma et un port, utiliser tel quel
        if hasScheme && hasExplicitPort {
            return [input]
        }

        // Si l'utilisateur a spécifié HTTPS explicitement
        if hasHTTPS {
            variants.append(input) // https://domain.com tel quel
            if !hasExplicitPort {
                variants.append("https://\(hostPart):8920") // Port HTTPS Jellyfin alternatif
            }
            return variants
        }

        // Si l'utilisateur a spécifié HTTP explicitement
        if hasHTTP {
            variants.append(input) // http://domain.com tel quel
            if !hasExplicitPort && isLocalIP {
                variants.append("http://\(hostPart):8096") // Ajouter port Jellyfin pour IP locale
            }
            return variants
        }

        // Pas de schéma spécifié - générer les variantes intelligemment
        if isLocalIP {
            // IP locale : priorité HTTP avec port 8096
            if !hasExplicitPort {
                variants.append("http://\(hostPart):8096")
            }
            variants.append("http://\(hostPart)")
            variants.append("https://\(hostPart)")
        } else {
            // Domaine public : forcer HTTPS par défaut (pas de fallback HTTP implicite)
            variants.append("https://\(hostPart)")
            if !hasExplicitPort {
                variants.append("https://\(hostPart):8920")
            }
        }

        return variants
    }

    /// Vérifie si la chaîne est une adresse IP privée (RFC 1918)
    var isPrivateIPAddress: Bool {
        // Pattern pour les IPs privées
        // 10.0.0.0 - 10.255.255.255
        // 172.16.0.0 - 172.31.255.255
        // 192.168.0.0 - 192.168.255.255
        // 127.0.0.0 - 127.255.255.255 (localhost)

        let components = self.split(separator: ".").compactMap { Int($0) }
        guard components.count == 4 else { return false }

        let first = components[0]
        let second = components[1]

        // 10.x.x.x
        if first == 10 { return true }

        // 172.16.x.x - 172.31.x.x
        if first == 172 && (16...31).contains(second) { return true }

        // 192.168.x.x
        if first == 192 && second == 168 { return true }

        // 127.x.x.x (localhost)
        if first == 127 { return true }

        return false
    }
}
