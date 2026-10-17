//
//  PlaybackConstants.swift
//  xfinn
//
//  Created by Dorian Galiana on 05/02/2026.
//  Centralizes playback-related constants to avoid magic numbers.
//

import AVFoundation

/// Constantes liées à la lecture média
enum PlaybackConstants {
    // MARK: - Timing (en secondes)
    
    /// Intervalle de reporting de progression au serveur Jellyfin
    static let progressReportInterval: TimeInterval = 5.0
    
    /// Seuil avant la fin pour déclencher le callback "approche de la fin"
    static let endApproachThreshold: TimeInterval = 10.0

    /// Intervalle de détection du segment actif (intro/générique) —
    /// plus fin que progressReportInterval pour un bouton de skip réactif
    static let segmentCheckInterval: TimeInterval = 0.5

    /// Durée d'affichage du bouton de skip avant masquage automatique
    /// (pattern Netflix — indispensable pour les génériques de fin, dont le
    /// segment s'étend jusqu'à la fin du fichier et n'est donc jamais "quitté")
    static let skipButtonDisplayDuration: TimeInterval = 8.0
    
    /// Intervalle de mise à jour des statistiques de buffer
    static let bufferUpdateInterval: TimeInterval = 0.5
    
    /// Buffer minimum requis pour le calcul des statistiques
    static let minimumBufferRequired: TimeInterval = 10.0

    /// Délai max de chargement d'un fichier en Direct Play avant repli HLS.
    /// Un fichier sain répond en ~1 s ; au-delà, AVPlayer est typiquement
    /// en train de parcourir un MP4 fragmenté non détecté par la sonde
    static let directPlayLoadTimeout: TimeInterval = 15.0

    // MARK: - Jellyfin API
    
    /// Nombre de ticks Jellyfin par seconde (pour conversion position)
    static let jellyfinTicksPerSecond: Int64 = 10_000_000
    
    // MARK: - AVFoundation
    
    /// Timescale préféré pour CMTime
    static let cmTimePreferredTimescale: CMTimeScale = 600
    
    // MARK: - Calculs
    
    /// Multiplicateur pour compenser l'intervalle de 0.5s dans le calcul de vitesse
    static let bufferSpeedMultiplier: Double = 2.0
    
    /// Plafond de pourcentage pour les calculs
    static let percentageCeiling: Double = 100.0
}

/// Constantes liées au compte à rebours auto-play
enum AutoplayConstants {
    /// Durée par défaut du countdown avant auto-play (en secondes)
    static let defaultCountdownDuration: Int = 10
}
