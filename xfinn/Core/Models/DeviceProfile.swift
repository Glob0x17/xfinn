//
//  DeviceProfile.swift
//  xfinn
//
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

    /// Crée un profil optimisé pour tvOS basé sur les capacités détectées de l'appareil
    /// Adapte automatiquement les codecs et résolutions supportés selon le modèle d'Apple TV
    static func tvOSProfile(maxBitrate: Int? = nil) -> DeviceProfile {
        let capabilities = DeviceCapabilities.current

        var profile = DeviceProfile()

        // Bitrate adapté à la résolution max supportée
        let defaultBitrate = capabilities.maxResolution == .uhd4K ? 200_000_000 : 40_000_000
        let bitrate = maxBitrate ?? defaultBitrate
        profile.maxStreamingBitrate = bitrate
        profile.maxStaticBitrate = bitrate
        profile.musicStreamingTranscodingBitrate = 192000

        // Construire les codecs vidéo supportés
        var videoCodecs: [String] = []
        if capabilities.supportsHEVC {
            videoCodecs.append("hevc")
        }
        videoCodecs.append("h264")  // H.264 toujours supporté
        if capabilities.supportsAV1 {
            videoCodecs.append("av1")
        }
        let videoCodecString = videoCodecs.joined(separator: ",")

        // Codecs audio (identiques pour tous les modèles)
        let audioCodecs = "aac,ac3,eac3,alac,mp3,flac"

        // Direct Play - Formats supportés nativement par AVPlayer
        // IMPORTANT: MKV n'est JAMAIS supporté par AVPlayer
        profile.directPlayProfiles = buildDirectPlayProfiles(
            videoCodecs: videoCodecString,
            audioCodecs: audioCodecs,
            capabilities: capabilities
        )

        // Transcoding Profile - HLS avec fMP4 pour compatibilité HEVC/HDR
        profile.transcodingProfiles = [
            TranscodingProfile(
                type: "Video",
                container: "mp4",  // fMP4 pour HLS - CRUCIAL pour HEVC/DV !
                videoCodec: videoCodecString,
                audioCodec: audioCodecs,
                context: "Streaming",
                protocol: "hls",
                maxAudioChannels: "8",
                minSegments: 2,
                breakOnNonKeyFrames: true,
                enableSubtitlesInManifest: true
            )
        ]

        // Subtitle Profiles (identiques pour tous les modèles)
        profile.subtitleProfiles = [
            SubtitleProfile(format: "vtt", method: "Hls"),
            SubtitleProfile(format: "srt", method: "External"),
            SubtitleProfile(format: "ass", method: "External"),
            SubtitleProfile(format: "ssa", method: "External"),
            SubtitleProfile(format: "sub", method: "External"),
            SubtitleProfile(format: "pgssub", method: "Encode"),
            SubtitleProfile(format: "dvdsub", method: "Encode"),
            SubtitleProfile(format: "dvbsub", method: "Encode")
        ]

        // Codec Profiles - Conditions selon les capacités
        profile.codecProfiles = buildCodecProfiles(capabilities: capabilities)

        return profile
    }

    /// Construit les profils Direct Play selon les capacités
    private static func buildDirectPlayProfiles(
        videoCodecs: String,
        audioCodecs: String,
        capabilities: DeviceCapabilities
    ) -> [DirectPlayProfile] {
        var profiles: [DirectPlayProfile] = []

        // MP4/M4V - Format principal pour HEVC et H.264
        profiles.append(DirectPlayProfile(
            type: "Video",
            container: "mp4,m4v",
            videoCodec: videoCodecs,
            audioCodec: audioCodecs
        ))

        // MOV - Format Apple natif
        profiles.append(DirectPlayProfile(
            type: "Video",
            container: "mov",
            videoCodec: videoCodecs,
            audioCodec: audioCodecs
        ))

        // HLS/TS - H.264 uniquement (HEVC dans TS pose des problèmes avec HDR/DV)
        profiles.append(DirectPlayProfile(
            type: "Video",
            container: "mpegts,ts",
            videoCodec: "h264",  // Pas de HEVC dans TS !
            audioCodec: "aac,ac3,eac3,mp3"
        ))

        return profiles
    }

    /// Construit les profils de codec selon les capacités
    private static func buildCodecProfiles(capabilities: DeviceCapabilities) -> [CodecProfile] {
        var profiles: [CodecProfile] = []

        // Conditions de base pour H.264
        let h264Level = capabilities.maxResolution == .uhd4K ? "52" : "42"
        profiles.append(CodecProfile(
            type: "Video",
            codec: "h264",
            conditions: [
                ProfileCondition(condition: "NotEquals", property: "IsAnamorphic", value: "true", isRequired: false),
                ProfileCondition(condition: "NotEquals", property: "IsInterlaced", value: "true", isRequired: false),
                ProfileCondition(condition: "LessThanEqual", property: "VideoLevel", value: h264Level, isRequired: false)
            ]
        ))

        // HEVC si supporté
        if capabilities.supportsHEVC {
            var hevcConditions: [ProfileCondition] = [
                ProfileCondition(condition: "NotEquals", property: "IsAnamorphic", value: "true", isRequired: false),
                ProfileCondition(condition: "NotEquals", property: "IsInterlaced", value: "true", isRequired: false),
                ProfileCondition(condition: "LessThanEqual", property: "VideoLevel", value: "186", isRequired: false)
            ]

            // Ajouter les types HDR supportés
            if capabilities.supportsHDR10 || capabilities.supportsDolbyVision {
                var videoRangeTypes = ["SDR"]
                if capabilities.supportsHDR10 {
                    videoRangeTypes.append("HDR10")
                }
                if capabilities.supportsHDR10Plus {
                    videoRangeTypes.append("HDR10Plus")
                }
                if capabilities.supportsDolbyVision {
                    videoRangeTypes.append(contentsOf: ["DOVI", "DOVIWithHDR10", "DOVIWithHDR10Plus", "DOVIWithSDR"])
                }

                hevcConditions.append(ProfileCondition(
                    condition: "EqualsAny",
                    property: "VideoRangeType",
                    value: videoRangeTypes.joined(separator: "|"),
                    isRequired: false
                ))
            }

            profiles.append(CodecProfile(
                type: "Video",
                codec: "hevc",
                conditions: hevcConditions
            ))
        }

        // AV1 si supporté (Apple TV 4K 3rd gen uniquement)
        if capabilities.supportsAV1 {
            profiles.append(CodecProfile(
                type: "Video",
                codec: "av1",
                conditions: [
                    ProfileCondition(condition: "NotEquals", property: "IsAnamorphic", value: "true", isRequired: false),
                    ProfileCondition(condition: "NotEquals", property: "IsInterlaced", value: "true", isRequired: false)
                ]
            ))
        }

        return profiles
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
