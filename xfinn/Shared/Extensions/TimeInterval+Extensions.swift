//
//  TimeInterval+Extensions.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//  Reorganized on 23/12/2025.
//  18/08/2026: single source of truth for duration formatting
//  (replaces 6 near-identical private copies across views/viewmodels).
//

import Foundation

// MARK: - TimeInterval Extensions

extension TimeInterval {
    /// Durée lisible pour un média (ex: "1h 23min", "45min")
    var formattedDuration: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)min" : "\(minutes)min"
    }

    /// Temps de lecture au format horloge (ex: "3:07"), sûr face à NaN/Infinity
    var formattedPlaybackTime: String {
        guard isFinite else { return "0:00" }
        let cleanSeconds = max(0, self)
        let minutes = Int(cleanSeconds) / 60
        let seconds = Int(cleanSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
