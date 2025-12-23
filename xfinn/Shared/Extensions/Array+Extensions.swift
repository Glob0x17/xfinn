//
//  Array+Extensions.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//  Reorganized on 23/12/2025.
//

import Foundation

// MARK: - Array Extensions (MediaItem)

extension Array where Element == MediaItem {
    /// Groupe les épisodes par numéro de saison
    func groupedBySeason() -> [Int: [MediaItem]] {
        Dictionary(grouping: self) { $0.parentIndexNumber ?? 0 }
    }
    
    /// Trie les médias par date de sortie (plus récent en premier)
    func sortedByReleaseDate() -> [MediaItem] {
        self.sorted { ($0.productionYear ?? 0) > ($1.productionYear ?? 0) }
    }
    
    /// Filtre les médias non visionnés
    var unwatched: [MediaItem] {
        self.filter { $0.userData?.played != true }
    }
    
    /// Filtre les médias en cours de lecture
    var inProgress: [MediaItem] {
        self.filter { 
            guard let userData = $0.userData else { return false }
            return !userData.played && userData.playbackPositionTicks > 0
        }
    }
    
    /// Trie les épisodes par index (saison et épisode)
    func sortedByIndex() -> [MediaItem] {
        self.sorted { first, second in
            // Comparer d'abord par saison
            let season1 = first.parentIndexNumber ?? 0
            let season2 = second.parentIndexNumber ?? 0
            
            if season1 != season2 {
                return season1 < season2
            }
            
            // Puis par numéro d'épisode
            let episode1 = first.indexNumber ?? 0
            let episode2 = second.indexNumber ?? 0
            return episode1 < episode2
        }
    }
}
