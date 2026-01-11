//
//  MetadataRow.swift
//  xfinn
//
//  Created by Refactoring Phase 1
//

import SwiftUI

/// Élément de métadonnée individuel
struct MetadataItem: Identifiable {
    let id = UUID()
    let icon: String
    let value: String
    var iconColor: Color = .appTextSecondary
    var valueColor: Color = .appTextSecondary
}

/// Ligne de métadonnées avec icônes (année, note, durée, etc.)
struct MetadataRow: View {
    let items: [MetadataItem]
    var spacing: CGFloat = 15
    var iconSize: CGFloat = 14
    var textSize: CGFloat = 16
    var showSeparators: Bool = true
    var separatorColor: Color = .appTextTertiary

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                // Séparateur avant (sauf premier élément)
                if showSeparators && index > 0 {
                    Circle()
                        .fill(separatorColor)
                        .frame(width: 4, height: 4)
                }

                // Élément
                HStack(spacing: 5) {
                    Image(systemName: item.icon)
                        .font(.system(size: iconSize))
                        .foregroundColor(item.iconColor)

                    Text(item.value)
                        .font(.system(size: textSize, weight: .medium))
                        .foregroundStyle(item.valueColor)
                }
            }
        }
    }
}

/// Version simplifiée pour les métadonnées média courantes
struct MediaMetadataRow: View {
    var year: Int? = nil
    var rating: Double? = nil
    var duration: TimeInterval? = nil
    var episodeInfo: String? = nil

    var spacing: CGFloat = 15
    var iconSize: CGFloat = 14
    var textSize: CGFloat = 16

    var body: some View {
        HStack(spacing: spacing) {
            // Année
            if let year = year {
                metadataItem(icon: "calendar", value: String(year))
            }

            // Séparateur
            if year != nil && (rating != nil || duration != nil || episodeInfo != nil) {
                separator
            }

            // Note
            if let rating = rating {
                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .font(.system(size: iconSize))
                        .foregroundColor(.yellow)

                    Text(String(format: "%.1f", rating))
                        .font(.system(size: textSize, weight: .medium))
                        .foregroundStyle(Color.appTextPrimary)
                }
            }

            // Séparateur
            if rating != nil && (duration != nil || episodeInfo != nil) {
                separator
            }

            // Durée
            if let duration = duration {
                metadataItem(icon: "clock", value: formatDuration(duration))
            }

            // Séparateur
            if duration != nil && episodeInfo != nil {
                separator
            }

            // Info épisode
            if let episodeInfo = episodeInfo {
                metadataItem(icon: "tv", value: episodeInfo)
            }
        }
    }

    private func metadataItem(icon: String, value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: iconSize))
            Text(value)
                .font(.system(size: textSize, weight: .medium))
        }
        .foregroundStyle(Color.appTextSecondary)
    }

    private var separator: some View {
        Circle()
            .fill(Color.appTextTertiary)
            .frame(width: 4, height: 4)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes) min"
        }
    }
}

/// Badge de type média (Film, Série, Épisode)
struct MediaTypeBadge: View {
    let type: String
    var accentColor: Color = .appPrimary
    var fontSize: CGFloat = 16

    private var displayText: String {
        switch type.lowercased() {
        case "movie":
            return "media_type.movie".localized
        case "series":
            return "media_type.series".localized
        case "episode":
            return "media_type.episode".localized
        case "season":
            return "media_type.season".localized
        default:
            return type
        }
    }

    private var icon: String {
        switch type.lowercased() {
        case "movie":
            return "film"
        case "series":
            return "tv"
        case "episode":
            return "play.rectangle"
        case "season":
            return "square.stack"
        default:
            return "questionmark"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: fontSize - 2))

            Text(displayText)
                .font(.system(size: fontSize, weight: .semibold))
        }
        .foregroundStyle(accentColor)
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(AppTheme.glassBackground)
                .overlay(
                    Capsule()
                        .stroke(accentColor.opacity(0.5), lineWidth: 1.5)
                )
        )
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Metadata Components") {
    ZStack {
        AppTheme.backgroundGradient.ignoresSafeArea()

        VStack(spacing: 40) {
            // MetadataRow avec items personnalisés
            VStack(alignment: .leading, spacing: 10) {
                Text("Custom MetadataRow")
                    .font(AppTheme.caption)
                    .foregroundStyle(Color.appTextTertiary)

                MetadataRow(items: [
                    MetadataItem(icon: "calendar", value: "2024"),
                    MetadataItem(icon: "star.fill", value: "8.5", iconColor: .yellow, valueColor: .appTextPrimary),
                    MetadataItem(icon: "clock", value: "2h 15min")
                ])
            }

            // MediaMetadataRow
            VStack(alignment: .leading, spacing: 10) {
                Text("MediaMetadataRow")
                    .font(AppTheme.caption)
                    .foregroundStyle(Color.appTextTertiary)

                MediaMetadataRow(
                    year: 2024,
                    rating: 8.5,
                    duration: 8100
                )
            }

            // Avec info épisode
            VStack(alignment: .leading, spacing: 10) {
                Text("Episode Metadata")
                    .font(AppTheme.caption)
                    .foregroundStyle(Color.appTextTertiary)

                MediaMetadataRow(
                    year: 2024,
                    duration: 2700,
                    episodeInfo: "S02E05"
                )
            }

            // MediaTypeBadge
            VStack(alignment: .leading, spacing: 15) {
                Text("MediaTypeBadge")
                    .font(AppTheme.caption)
                    .foregroundStyle(Color.appTextTertiary)

                HStack(spacing: 15) {
                    MediaTypeBadge(type: "Movie", accentColor: .appPrimary)
                    MediaTypeBadge(type: "Series", accentColor: .appSecondary)
                    MediaTypeBadge(type: "Episode", accentColor: .appTertiary)
                }
            }
        }
        .padding()
    }
}
#endif
