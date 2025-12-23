//
//  StreamQuality.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import Foundation

/// Qualités de streaming disponibles
enum StreamQuality: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case original = "Original (qualité maximale)"
    case high = "Haute (1080p)"
    case medium = "Moyenne (720p)"
    case low = "Basse (480p)"
    
    var id: String { rawValue }
    
    var maxBitrate: Int? {
        switch self {
        case .auto: return nil // Sera défini à 15 Mbps dans getStreamURL
        case .original: return nil // Sera défini à 15 Mbps dans getStreamURL
        case .high: return 12_000_000 // 12 Mbps pour 1080p de haute qualité
        case .medium: return 6_000_000 // 6 Mbps pour 720p
        case .low: return 3_000_000 // 3 Mbps pour 480p
        }
    }
    
    var maxWidth: Int? {
        switch self {
        case .auto: return nil // Sera défini à 1920 dans getStreamURL
        case .original: return nil // Sera défini à 1920 dans getStreamURL
        case .high: return 1920
        case .medium: return 1280
        case .low: return 854
        }
    }
    
    /// Description détaillée de la qualité
    var description: String {
        switch self {
        case .auto:
            return "Qualité automatique (1080p, 15 Mbps)"
        case .original:
            return "Qualité originale sans limite"
        case .high:
            return "Haute qualité (1080p, 12 Mbps)"
        case .medium:
            return "Qualité moyenne (720p, 6 Mbps)"
        case .low:
            return "Qualité basse (480p, 3 Mbps)"
        }
    }
}
