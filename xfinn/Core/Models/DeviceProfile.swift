//
//  DeviceProfile.swift
//  xfinn
//
//  Created by Claude on 10/01/2026.
//  Device profile for Jellyfin playback with subtitle support.
//

import Foundation

// MARK: - Device Profile

/// Profil de l'appareil pour Jellyfin avec support des sous-titres
struct DeviceProfile: Codable {
    var maxStreamingBitrate: Int?
    var maxStaticBitrate: Int?
    var musicStreamingTranscodingBitrate: Int?
    var directPlayProfiles: [DirectPlayProfile]?
    var transcodingProfiles: [TranscodingProfile]?
    var subtitleProfiles: [SubtitleProfile]?
    var codecProfiles: [CodecProfile]?

    enum CodingKeys: String, CodingKey {
        case maxStreamingBitrate = "MaxStreamingBitrate"
        case maxStaticBitrate = "MaxStaticBitrate"
        case musicStreamingTranscodingBitrate = "MusicStreamingTranscodingBitrate"
        case directPlayProfiles = "DirectPlayProfiles"
        case transcodingProfiles = "TranscodingProfiles"
        case subtitleProfiles = "SubtitleProfiles"
        case codecProfiles = "CodecProfiles"
    }

    /// Crée un profil optimisé pour tvOS avec support HLS et sous-titres
    static func tvOSProfile(maxBitrate: Int? = nil) -> DeviceProfile {
        var profile = DeviceProfile()

        // Bitrate
        let bitrate = maxBitrate ?? 20_000_000
        profile.maxStreamingBitrate = bitrate
        profile.maxStaticBitrate = bitrate
        profile.musicStreamingTranscodingBitrate = 192000

        // Direct Play - Formats supportés nativement par tvOS
        profile.directPlayProfiles = [
            DirectPlayProfile(
                type: "Video",
                container: "mp4,m4v",
                videoCodec: "h264,hevc",
                audioCodec: "aac,ac3,eac3,alac,flac"
            ),
            DirectPlayProfile(
                type: "Video",
                container: "mov",
                videoCodec: "h264,hevc,mjpeg,mpeg4",
                audioCodec: "aac,ac3,eac3,mp3,pcm_s16le,pcm_s24le"
            ),
            DirectPlayProfile(
                type: "Video",
                container: "mpegts,ts",
                videoCodec: "h264",
                audioCodec: "aac,ac3,eac3,mp3"
            )
        ]

        // Transcoding Profile - HLS avec sous-titres dans le manifest
        profile.transcodingProfiles = [
            TranscodingProfile(
                type: "Video",
                container: "ts",
                videoCodec: "h264",
                audioCodec: "aac,ac3,eac3",
                context: "Streaming",
                protocol: "hls",
                maxAudioChannels: "6",
                minSegments: 2,
                breakOnNonKeyFrames: true,
                enableSubtitlesInManifest: true  // Clé ! Sous-titres dans le manifest HLS
            )
        ]

        // Subtitle Profiles - Support des différentes méthodes de livraison
        profile.subtitleProfiles = [
            // HLS - Pour intégration dans le manifest (menu CC natif)
            SubtitleProfile(format: "vtt", method: "Hls"),

            // External - Pour téléchargement séparé si nécessaire
            SubtitleProfile(format: "srt", method: "External"),
            SubtitleProfile(format: "ass", method: "External"),
            SubtitleProfile(format: "ssa", method: "External"),
            SubtitleProfile(format: "sub", method: "External"),

            // Encode - Pour burn-in si nécessaire
            SubtitleProfile(format: "pgssub", method: "Encode"),
            SubtitleProfile(format: "dvdsub", method: "Encode"),
            SubtitleProfile(format: "dvbsub", method: "Encode")
        ]

        // Codec Profiles - Conditions pour les codecs vidéo
        profile.codecProfiles = [
            CodecProfile(
                type: "Video",
                codec: "h264",
                conditions: [
                    ProfileCondition(
                        condition: "NotEquals",
                        property: "IsAnamorphic",
                        value: "true",
                        isRequired: false
                    ),
                    ProfileCondition(
                        condition: "NotEquals",
                        property: "IsInterlaced",
                        value: "true",
                        isRequired: false
                    ),
                    ProfileCondition(
                        condition: "LessThanEqual",
                        property: "VideoLevel",
                        value: "51",
                        isRequired: false
                    )
                ]
            ),
            CodecProfile(
                type: "Video",
                codec: "hevc",
                conditions: [
                    ProfileCondition(
                        condition: "NotEquals",
                        property: "IsAnamorphic",
                        value: "true",
                        isRequired: false
                    ),
                    ProfileCondition(
                        condition: "NotEquals",
                        property: "IsInterlaced",
                        value: "true",
                        isRequired: false
                    )
                ]
            )
        ]

        return profile
    }
}

// MARK: - Direct Play Profile

struct DirectPlayProfile: Codable {
    var type: String
    var container: String?
    var videoCodec: String?
    var audioCodec: String?

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case container = "Container"
        case videoCodec = "VideoCodec"
        case audioCodec = "AudioCodec"
    }
}

// MARK: - Transcoding Profile

struct TranscodingProfile: Codable {
    var type: String
    var container: String
    var videoCodec: String
    var audioCodec: String
    var context: String
    var `protocol`: String
    var maxAudioChannels: String?
    var minSegments: Int?
    var breakOnNonKeyFrames: Bool?
    var enableSubtitlesInManifest: Bool?

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case container = "Container"
        case videoCodec = "VideoCodec"
        case audioCodec = "AudioCodec"
        case context = "Context"
        case `protocol` = "Protocol"
        case maxAudioChannels = "MaxAudioChannels"
        case minSegments = "MinSegments"
        case breakOnNonKeyFrames = "BreakOnNonKeyFrames"
        case enableSubtitlesInManifest = "EnableSubtitlesInManifest"
    }
}

// MARK: - Subtitle Profile

struct SubtitleProfile: Codable {
    var format: String
    var method: String

    enum CodingKeys: String, CodingKey {
        case format = "Format"
        case method = "Method"
    }
}

// MARK: - Codec Profile

struct CodecProfile: Codable {
    var type: String
    var codec: String?
    var conditions: [ProfileCondition]?

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case codec = "Codec"
        case conditions = "Conditions"
    }
}

// MARK: - Profile Condition

struct ProfileCondition: Codable {
    var condition: String
    var property: String
    var value: String
    var isRequired: Bool

    enum CodingKeys: String, CodingKey {
        case condition = "Condition"
        case property = "Property"
        case value = "Value"
        case isRequired = "IsRequired"
    }
}

// MARK: - Playback Info

/// Corps de la requête PlaybackInfo
struct PlaybackInfoRequest: Codable {
    var userId: String
    var maxStreamingBitrate: Int?
    var mediaSourceId: String?
    var deviceProfile: DeviceProfile?
    var autoOpenLiveStream: Bool?

    enum CodingKeys: String, CodingKey {
        case userId = "UserId"
        case maxStreamingBitrate = "MaxStreamingBitrate"
        case mediaSourceId = "MediaSourceId"
        case deviceProfile = "DeviceProfile"
        case autoOpenLiveStream = "AutoOpenLiveStream"
    }
}

/// Réponse de PlaybackInfo
struct PlaybackInfoResponse: Codable {
    var mediaSources: [MediaSourceInfo]?
    var playSessionId: String?

    enum CodingKeys: String, CodingKey {
        case mediaSources = "MediaSources"
        case playSessionId = "PlaySessionId"
    }
}

/// Informations sur une source média
struct MediaSourceInfo: Codable {
    var id: String?
    var name: String?
    var path: String?
    var container: String?
    var size: Int64?
    var bitrate: Int?
    var supportsDirectPlay: Bool?
    var supportsDirectStream: Bool?
    var supportsTranscoding: Bool?
    var transcodingUrl: String?
    var directStreamUrl: String?
    var mediaStreams: [MediaStreamInfo]?
    var defaultAudioStreamIndex: Int?
    var defaultSubtitleStreamIndex: Int?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case path = "Path"
        case container = "Container"
        case size = "Size"
        case bitrate = "Bitrate"
        case supportsDirectPlay = "SupportsDirectPlay"
        case supportsDirectStream = "SupportsDirectStream"
        case supportsTranscoding = "SupportsTranscoding"
        case transcodingUrl = "TranscodingUrl"
        case directStreamUrl = "DirectStreamUrl"
        case mediaStreams = "MediaStreams"
        case defaultAudioStreamIndex = "DefaultAudioStreamIndex"
        case defaultSubtitleStreamIndex = "DefaultSubtitleStreamIndex"
    }
}

/// Informations sur un flux média (audio, vidéo, sous-titres)
struct MediaStreamInfo: Codable {
    var type: String?
    var index: Int?
    var codec: String?
    var language: String?
    var displayTitle: String?
    var isDefault: Bool?
    var isForced: Bool?
    var isExternal: Bool?

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case index = "Index"
        case codec = "Codec"
        case language = "Language"
        case displayTitle = "DisplayTitle"
        case isDefault = "IsDefault"
        case isForced = "IsForced"
        case isExternal = "IsExternal"
    }
}
