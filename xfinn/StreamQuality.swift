//
//  StreamQuality.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//  Refactored on 10/01/2026: Added comprehensive bitrate options like Swiftfin
//

import Foundation

/// Qualités de streaming disponibles avec bitrates précis
enum StreamQuality: Int, CaseIterable, Identifiable, Codable {
    case auto = 0
    case maximum = 360_000_000
    case mbps120 = 120_000_000
    case mbps80 = 80_000_000
    case mbps60 = 60_000_000
    case mbps40 = 40_000_000
    case mbps20 = 20_000_000
    case mbps15 = 15_000_000
    case mbps10 = 10_000_000
    case mbps8 = 8_000_000
    case mbps6 = 6_000_000
    case mbps4 = 4_000_000
    case mbps3 = 3_000_000
    case kbps1500 = 1_500_000
    case kbps720 = 720_000
    case kbps420 = 420_000

    var id: Int { rawValue }

    /// Nom d'affichage
    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .maximum: return "Maximum"
        case .mbps120: return "120 Mbps"
        case .mbps80: return "80 Mbps"
        case .mbps60: return "60 Mbps"
        case .mbps40: return "40 Mbps"
        case .mbps20: return "20 Mbps"
        case .mbps15: return "15 Mbps"
        case .mbps10: return "10 Mbps"
        case .mbps8: return "8 Mbps"
        case .mbps6: return "6 Mbps"
        case .mbps4: return "4 Mbps"
        case .mbps3: return "3 Mbps"
        case .kbps1500: return "1.5 Mbps"
        case .kbps720: return "720 Kbps"
        case .kbps420: return "420 Kbps"
        }
    }

    /// Description détaillée de la qualité
    var description: String {
        switch self {
        case .auto:
            return "Test automatique de la connexion"
        case .maximum:
            return "Qualité maximale (4K HDR)"
        case .mbps120:
            return "4K HDR"
        case .mbps80:
            return "4K"
        case .mbps60:
            return "4K"
        case .mbps40:
            return "1080p haute qualité"
        case .mbps20:
            return "1080p"
        case .mbps15:
            return "1080p"
        case .mbps10:
            return "1080p"
        case .mbps8:
            return "720p haute qualité"
        case .mbps6:
            return "720p"
        case .mbps4:
            return "480p haute qualité"
        case .mbps3:
            return "480p"
        case .kbps1500:
            return "360p"
        case .kbps720:
            return "240p"
        case .kbps420:
            return "144p"
        }
    }

    /// Bitrate maximum pour ce niveau de qualité
    var maxBitrate: Int? {
        switch self {
        case .auto:
            return nil // Sera déterminé par le test de débit
        default:
            return rawValue
        }
    }

    /// Résolution maximale suggérée
    var maxWidth: Int? {
        switch self {
        case .auto, .maximum, .mbps120, .mbps80, .mbps60:
            return 3840 // 4K
        case .mbps40, .mbps20, .mbps15, .mbps10:
            return 1920 // 1080p
        case .mbps8, .mbps6:
            return 1280 // 720p
        case .mbps4, .mbps3:
            return 854 // 480p
        case .kbps1500:
            return 640 // 360p
        case .kbps720:
            return 426 // 240p
        case .kbps420:
            return 256 // 144p
        }
    }

    /// Obtient le bitrate effectif (avec test réseau si auto)
    func getEffectiveBitrate(authService: AuthService? = nil) async -> Int {
        switch self {
        case .auto:
            // Test de débit si possible
            if let authService = authService {
                do {
                    return try await BitrateTest.performTest(authService: authService)
                } catch {
                    // Fallback à 20 Mbps si le test échoue
                    return 20_000_000
                }
            }
            // Pas de service auth, utiliser une valeur par défaut
            return 20_000_000
        default:
            return rawValue
        }
    }
}

// MARK: - Bitrate Test

/// Utilitaire pour tester le débit réseau
enum BitrateTest {
    /// Taille du test en octets (1 MB par défaut)
    static let defaultTestSize = 1_000_000

    /// Effectue un test de débit vers le serveur Jellyfin
    static func performTest(authService: AuthService, testSize: Int = defaultTestSize) async throws -> Int {
        guard let url = URL(string: "\(authService.baseURL)/System/Ping") else {
            throw BitrateTestError.invalidURL
        }

        // Faire plusieurs requêtes pour avoir une moyenne plus fiable
        var totalTime: TimeInterval = 0
        let iterations = 3

        for _ in 0..<iterations {
            let request = authService.authenticatedRequest(for: url)
            let startTime = Date()

            let (data, _) = try await URLSession.shared.data(for: request)

            let elapsed = Date().timeIntervalSince(startTime)
            totalTime += elapsed

            // Utiliser la taille des données reçues si disponible
            _ = data.count
        }

        // Calculer le débit moyen
        let averageTime = totalTime / Double(iterations)

        // Pour le ping, on estime le débit basé sur la latence
        // Latence < 50ms = excellent (40+ Mbps)
        // Latence < 100ms = bon (20-40 Mbps)
        // Latence < 200ms = moyen (10-20 Mbps)
        // Latence > 200ms = lent (< 10 Mbps)
        let estimatedBitrate: Int
        if averageTime < 0.05 {
            estimatedBitrate = 40_000_000
        } else if averageTime < 0.1 {
            estimatedBitrate = 20_000_000
        } else if averageTime < 0.2 {
            estimatedBitrate = 15_000_000
        } else if averageTime < 0.5 {
            estimatedBitrate = 10_000_000
        } else {
            estimatedBitrate = 6_000_000
        }

        return estimatedBitrate
    }
}

enum BitrateTestError: Error {
    case invalidURL
    case networkError
}

// MARK: - UserDefaults Extension

extension StreamQuality {
    /// Clé pour sauvegarder dans UserDefaults
    private static let userDefaultsKey = "preferredStreamQuality"

    /// Sauvegarde la qualité préférée
    func save() {
        UserDefaults.standard.set(rawValue, forKey: Self.userDefaultsKey)
    }

    /// Charge la qualité préférée depuis UserDefaults
    static func load() -> StreamQuality {
        let savedValue = UserDefaults.standard.integer(forKey: userDefaultsKey)
        return StreamQuality(rawValue: savedValue) ?? .auto
    }
}
