//
//  DeviceCapabilities.swift
//  xfinn
//
//  Automatic detection of Apple TV capabilities to adapt the DeviceProfile.
//

import Foundation

// MARK: - Device Capabilities

/// Capacités de décodage vidéo de l'appareil
struct DeviceCapabilities {
    let supportsHEVC: Bool
    let supportsHEVC10Bit: Bool
    let supportsHDR10: Bool
    let supportsDolbyVision: Bool
    let supportsHDR10Plus: Bool
    let supportsAV1: Bool
    let maxResolution: Resolution
    let modelName: String

    enum Resolution {
        case hd1080p
        case uhd4K

        var maxWidth: Int {
            switch self {
            case .hd1080p: return 1920
            case .uhd4K: return 3840
            }
        }

        var maxHeight: Int {
            switch self {
            case .hd1080p: return 1080
            case .uhd4K: return 2160
            }
        }
    }

    /// Capacités de l'appareil actuel (détectées automatiquement)
    static let current: DeviceCapabilities = detectCapabilities()

    /// Détecte les capacités en fonction du modèle d'Apple TV
    private static func detectCapabilities() -> DeviceCapabilities {
        let model = getMachineIdentifier()

        // Mapping des modèles Apple TV vers leurs capacités
        // Ref: https://everymac.com/systems/apple/apple-tv/index-apple-tv.html
        switch model {

        // Apple TV 4K 3rd gen (2022) - A15 Bionic
        // WiFi: AppleTV14,1 | WiFi+Ethernet: AppleTV14,1
        case let m where m.hasPrefix("AppleTV14"):
            return DeviceCapabilities(
                supportsHEVC: true,
                supportsHEVC10Bit: true,
                supportsHDR10: true,
                supportsDolbyVision: true,
                supportsHDR10Plus: true,  // A15 supporte HDR10+
                supportsAV1: true,         // A15 supporte AV1
                maxResolution: .uhd4K,
                modelName: "Apple TV 4K (3rd gen)"
            )

        // Apple TV 4K 2nd gen (2021) - A12 Bionic
        // AppleTV11,1
        case let m where m.hasPrefix("AppleTV11"):
            return DeviceCapabilities(
                supportsHEVC: true,
                supportsHEVC10Bit: true,
                supportsHDR10: true,
                supportsDolbyVision: true,
                supportsHDR10Plus: false,  // A12 ne supporte pas HDR10+
                supportsAV1: false,         // A12 ne supporte pas AV1
                maxResolution: .uhd4K,
                modelName: "Apple TV 4K (2nd gen)"
            )

        // Apple TV 4K 1st gen (2017) - A10X Fusion
        // AppleTV6,2
        case let m where m.hasPrefix("AppleTV6"):
            return DeviceCapabilities(
                supportsHEVC: true,
                supportsHEVC10Bit: true,
                supportsHDR10: true,
                supportsDolbyVision: true,
                supportsHDR10Plus: false,
                supportsAV1: false,
                maxResolution: .uhd4K,
                modelName: "Apple TV 4K (1st gen)"
            )

        // Apple TV HD (4th gen, 2015) - A8
        // AppleTV5,3
        case let m where m.hasPrefix("AppleTV5"):
            return DeviceCapabilities(
                supportsHEVC: false,       // A8 ne supporte pas HEVC hardware
                supportsHEVC10Bit: false,
                supportsHDR10: false,
                supportsDolbyVision: false,
                supportsHDR10Plus: false,
                supportsAV1: false,
                maxResolution: .hd1080p,
                modelName: "Apple TV HD"
            )

        // Simulateur ou modèle inconnu - profil conservateur
        default:
            #if targetEnvironment(simulator)
            // Simulateur - utiliser H.264 uniquement (pas de HEVC hardware)
            return DeviceCapabilities(
                supportsHEVC: false,
                supportsHEVC10Bit: false,
                supportsHDR10: false,
                supportsDolbyVision: false,
                supportsHDR10Plus: false,
                supportsAV1: false,
                maxResolution: .hd1080p,
                modelName: "Simulator"
            )
            #else
            // Unknown future model - assume maximum capabilities
            return DeviceCapabilities(
                supportsHEVC: true,
                supportsHEVC10Bit: true,
                supportsHDR10: true,
                supportsDolbyVision: true,
                supportsHDR10Plus: true,
                supportsAV1: true,
                maxResolution: .uhd4K,
                modelName: "Unknown (\(model))"
            )
            #endif
        }
    }

    /// Récupère l'identifiant machine via sysctl
    private static func getMachineIdentifier() -> String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)

        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)

        return String(cString: machine)
    }
}

// MARK: - Debug Description

extension DeviceCapabilities: CustomStringConvertible {
    var description: String {
        """
        DeviceCapabilities:
          Model: \(modelName)
          HEVC: \(supportsHEVC) (10-bit: \(supportsHEVC10Bit))
          HDR10: \(supportsHDR10)
          Dolby Vision: \(supportsDolbyVision)
          HDR10+: \(supportsHDR10Plus)
          AV1: \(supportsAV1)
          Max Resolution: \(maxResolution.maxWidth)x\(maxResolution.maxHeight)
        """
    }
}
