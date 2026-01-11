//
//  BufferStats.swift
//  xfinn
//
//  Buffer statistics model for playback monitoring.
//

import Foundation

/// Statistiques de buffering pour l'affichage du chargement
struct BufferStats {
    /// Pourcentage de chargement (0-100)
    let percentage: Double

    /// Vitesse de téléchargement en bytes par seconde
    let downloadSpeed: Double

    /// Temps restant estimé en secondes
    let remainingTime: TimeInterval?

    /// Quantité de données téléchargées
    let downloadedBytes: Int64

    /// Quantité totale estimée
    let totalBytes: Int64?

    // MARK: - Computed Properties

    /// Vitesse formatée (ex: "12.5 MB/s")
    var formattedSpeed: String {
        formatBytes(downloadSpeed) + "/s"
    }

    /// Temps restant formaté (ex: "2:30")
    var formattedRemainingTime: String? {
        guard let remaining = remainingTime, remaining.isFinite, remaining > 0 else {
            return nil
        }

        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60

        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }

    /// Pourcentage formaté (ex: "45%")
    var formattedPercentage: String {
        String(format: "%.0f%%", min(percentage, 100))
    }

    /// Données téléchargées formatées
    var formattedDownloaded: String {
        formatBytes(Double(downloadedBytes))
    }

    // MARK: - Helpers

    private func formatBytes(_ bytes: Double) -> String {
        if bytes >= 1_000_000_000 {
            return String(format: "%.1f GB", bytes / 1_000_000_000)
        } else if bytes >= 1_000_000 {
            return String(format: "%.1f MB", bytes / 1_000_000)
        } else if bytes >= 1000 {
            return String(format: "%.0f KB", bytes / 1000)
        } else {
            return "\(Int(bytes)) B"
        }
    }

    // MARK: - Factory

    static var empty: BufferStats {
        BufferStats(
            percentage: 0,
            downloadSpeed: 0,
            remainingTime: nil,
            downloadedBytes: 0,
            totalBytes: nil
        )
    }
}
