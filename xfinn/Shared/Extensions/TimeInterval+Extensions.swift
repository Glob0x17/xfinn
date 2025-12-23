//
//  TimeInterval+Extensions.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//  Reorganized on 23/12/2025.
//

import Foundation

// MARK: - TimeInterval Extensions

extension TimeInterval {
    /// Convertit un TimeInterval en format lisible (ex: "1h 23min")
    var formattedDuration: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else if minutes > 0 {
            return "\(minutes)min"
        } else {
            return "\(seconds)s"
        }
    }
    
    /// Convertit un TimeInterval en ticks Jellyfin
    /// - Note: Jellyfin utilise 10 000 000 ticks par seconde
    var toTicks: Int64 {
        return Int64(self * 10_000_000)
    }
}

// MARK: - Int64 Extensions

extension Int64 {
    /// Convertit des ticks Jellyfin en TimeInterval
    /// - Note: Jellyfin utilise 10 000 000 ticks par seconde
    var fromTicks: TimeInterval {
        return Double(self) / 10_000_000.0
    }
}
