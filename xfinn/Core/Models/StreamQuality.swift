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
            return "quality.auto_desc".localized
        case .maximum:
            return "quality.maximum_desc".localized
        case .mbps120:
            return "quality.4k_hdr".localized
        case .mbps80:
            return "quality.4k".localized
        case .mbps60:
            return "quality.4k".localized
        case .mbps40:
            return "quality.1080p_high".localized
        case .mbps20:
            return "quality.1080p".localized
        case .mbps15:
            return "quality.1080p".localized
        case .mbps10:
            return "quality.1080p".localized
        case .mbps8:
            return "quality.720p_high".localized
        case .mbps6:
            return "quality.720p".localized
        case .mbps4:
            return "quality.480p_high".localized
        case .mbps3:
            return "quality.480p".localized
        case .kbps1500:
            return "quality.360p".localized
        case .kbps720:
            return "quality.240p".localized
        case .kbps420:
            return "quality.144p".localized
        }
    }

    /// Bitrate maximum pour ce niveau de qualité
    /// `.auto` retourne nil : les appelants utilisent alors le bitrate Maximum,
    /// ce qui favorise le Direct Play et laisse le serveur arbitrer via PlaybackInfo
    var maxBitrate: Int? {
        switch self {
        case .auto:
            return nil
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
