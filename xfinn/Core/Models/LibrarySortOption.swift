//
//  LibrarySortOption.swift
//  xfinn
//
//  Options de tri des bibliothèques, mappées vers les paramètres
//  SortBy/SortOrder de l'API Jellyfin (validées contre un serveur 10.11).
//

import Foundation

/// Tri d'une bibliothèque
enum LibrarySortOption: String, CaseIterable, Identifiable {
    case name
    case dateAdded
    case rating
    case year

    var id: String { rawValue }

    /// Valeur du paramètre SortBy de l'API Jellyfin
    /// (SortName en tri secondaire pour un ordre stable)
    var apiSortBy: String {
        switch self {
        case .name: return "SortName"
        case .dateAdded: return "DateCreated,SortName"
        case .rating: return "CommunityRating,SortName"
        case .year: return "ProductionYear,SortName"
        }
    }

    /// Ordre naturel : alphabétique croissant, tout le reste décroissant
    /// (plus récent / mieux noté d'abord)
    var apiSortOrder: String {
        self == .name ? "Ascending" : "Descending"
    }

    var displayName: String {
        switch self {
        case .name: return "library.sort.name".localized
        case .dateAdded: return "library.sort.date_added".localized
        case .rating: return "library.sort.rating".localized
        case .year: return "library.sort.year".localized
        }
    }

    var icon: String {
        switch self {
        case .name: return "textformat.abc"
        case .dateAdded: return "clock.arrow.circlepath"
        case .rating: return "star.fill"
        case .year: return "calendar"
        }
    }
}
