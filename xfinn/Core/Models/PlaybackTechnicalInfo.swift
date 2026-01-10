//
//  PlaybackTechnicalInfo.swift
//  xfinn
//
//  Created by Claude on 10/01/2026.
//  Technical playback information for display in player info panel.
//

import Foundation

/// Informations techniques de lecture
struct PlaybackTechnicalInfo {
    // MARK: - Mode de lecture
    let playMethod: PlayMethod
    let isTranscoding: Bool

    // MARK: - Source
    let container: String?
    let sourceBitrate: Int?
    let sourceSize: Int64?

    // MARK: - Vidéo
    let videoCodec: String?
    let videoResolution: String?
    let videoBitrate: Int?

    // MARK: - Audio
    let audioCodec: String?
    let audioChannels: String?
    let audioBitrate: Int?

    // MARK: - Transcodage
    let transcodingVideoCodec: String?
    let transcodingAudioCodec: String?
    let transcodingContainer: String?
    let transcodingBitrate: Int?

    // MARK: - Réseau
    let streamUrl: String?

    // MARK: - Computed Properties

    /// Description du mode de lecture
    var playMethodDescription: String {
        switch playMethod {
        case .directPlay:
            return "Lecture directe"
        case .directStream:
            return "Stream direct"
        case .transcode:
            return "Transcodage"
        }
    }

    /// Icône SF Symbol pour le mode de lecture
    var playMethodIcon: String {
        switch playMethod {
        case .directPlay:
            return "play.circle.fill"
        case .directStream:
            return "arrow.right.circle.fill"
        case .transcode:
            return "arrow.triangle.2.circlepath"
        }
    }

    /// Couleur pour le mode de lecture (nom de la couleur)
    var playMethodColorName: String {
        switch playMethod {
        case .directPlay:
            return "green"
        case .directStream:
            return "blue"
        case .transcode:
            return "orange"
        }
    }

    /// Format du bitrate source
    var sourceBitrateFormatted: String? {
        guard let bitrate = sourceBitrate else { return nil }
        return formatBitrate(bitrate)
    }

    /// Format de la taille source
    var sourceSizeFormatted: String? {
        guard let size = sourceSize else { return nil }
        return formatFileSize(size)
    }

    /// Format du bitrate de transcodage
    var transcodingBitrateFormatted: String? {
        guard let bitrate = transcodingBitrate else { return nil }
        return formatBitrate(bitrate)
    }

    // MARK: - Helpers

    private func formatBitrate(_ bitrate: Int) -> String {
        if bitrate >= 1_000_000 {
            return String(format: "%.1f Mbps", Double(bitrate) / 1_000_000)
        } else if bitrate >= 1000 {
            return "\(bitrate / 1000) Kbps"
        } else {
            return "\(bitrate) bps"
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Play Method

enum PlayMethod: String {
    case directPlay = "DirectPlay"
    case directStream = "DirectStream"
    case transcode = "Transcode"

    var displayName: String {
        switch self {
        case .directPlay: return "Lecture directe"
        case .directStream: return "Stream direct"
        case .transcode: return "Transcodage"
        }
    }
}

// MARK: - Factory

extension PlaybackTechnicalInfo {
    /// Crée les infos techniques à partir du résultat de PlaybackInfo
    static func from(
        playbackResult: PlaybackResult,
        requestedBitrate: Int?
    ) -> PlaybackTechnicalInfo {
        let mediaSource = playbackResult.mediaSource

        // Déterminer le mode de lecture
        let playMethod: PlayMethod
        if playbackResult.isTranscoding {
            playMethod = .transcode
        } else if mediaSource.supportsDirectPlay == true {
            playMethod = .directPlay
        } else {
            playMethod = .directStream
        }

        // Extraire les infos vidéo et audio
        var videoCodec: String?
        var videoResolution: String?
        var videoBitrate: Int?
        var audioCodec: String?
        var audioChannels: String?
        var audioBitrate: Int?

        if let streams = mediaSource.mediaStreams {
            for stream in streams {
                if stream.type == "Video" {
                    videoCodec = stream.codec?.uppercased()
                    if let title = stream.displayTitle {
                        videoResolution = title
                    }
                } else if stream.type == "Audio" && audioCodec == nil {
                    audioCodec = stream.codec?.uppercased()
                    audioChannels = stream.displayTitle
                }
            }
        }

        // Extraire les infos de transcodage depuis l'URL si disponible
        var transcodingVideoCodec: String?
        var transcodingAudioCodec: String?
        var transcodingContainer: String?

        if let transcodingUrl = mediaSource.transcodingUrl {
            // Parser les paramètres de l'URL de transcodage
            if let components = URLComponents(string: transcodingUrl) {
                for item in components.queryItems ?? [] {
                    switch item.name {
                    case "VideoCodec":
                        transcodingVideoCodec = item.value?.uppercased()
                    case "AudioCodec":
                        transcodingAudioCodec = item.value?.uppercased()
                    case "TranscodingContainer":
                        transcodingContainer = item.value?.uppercased()
                    default:
                        break
                    }
                }
            }
        }

        return PlaybackTechnicalInfo(
            playMethod: playMethod,
            isTranscoding: playbackResult.isTranscoding,
            container: mediaSource.container?.uppercased(),
            sourceBitrate: mediaSource.bitrate,
            sourceSize: mediaSource.size,
            videoCodec: videoCodec,
            videoResolution: videoResolution,
            videoBitrate: videoBitrate,
            audioCodec: audioCodec,
            audioChannels: audioChannels,
            audioBitrate: audioBitrate,
            transcodingVideoCodec: transcodingVideoCodec,
            transcodingAudioCodec: transcodingAudioCodec,
            transcodingContainer: transcodingContainer,
            transcodingBitrate: requestedBitrate,
            streamUrl: playbackResult.streamURL.absoluteString
        )
    }
}
