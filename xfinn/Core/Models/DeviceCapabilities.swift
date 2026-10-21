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

    /// Détecte les capacités en fonction du modèle d'appareil
    private static func detectCapabilities() -> DeviceCapabilities {
        let model = getMachineIdentifier()

        #if os(tvOS)
        return detectTVCapabilities(model: model)
        #else
        return detectIOSCapabilities(model: model)
        #endif
    }

    // MARK: - tvOS Detection

    private static func detectTVCapabilities(model: String) -> DeviceCapabilities {
        switch model {
        // Apple TV 4K 3rd gen (2022) - A15 Bionic
        case let m where m.hasPrefix("AppleTV14"):
            return DeviceCapabilities(
                supportsHEVC: true, supportsHEVC10Bit: true,
                supportsHDR10: true, supportsDolbyVision: true,
                supportsHDR10Plus: true, supportsAV1: true,
                maxResolution: .uhd4K, modelName: "Apple TV 4K (3rd gen)"
            )
        // Apple TV 4K 2nd gen (2021) - A12 Bionic
        case let m where m.hasPrefix("AppleTV11"):
            return DeviceCapabilities(
                supportsHEVC: true, supportsHEVC10Bit: true,
                supportsHDR10: true, supportsDolbyVision: true,
                supportsHDR10Plus: false, supportsAV1: false,
                maxResolution: .uhd4K, modelName: "Apple TV 4K (2nd gen)"
            )
        // Apple TV 4K 1st gen (2017) - A10X Fusion
        case let m where m.hasPrefix("AppleTV6"):
            return DeviceCapabilities(
                supportsHEVC: true, supportsHEVC10Bit: true,
                supportsHDR10: true, supportsDolbyVision: true,
                supportsHDR10Plus: false, supportsAV1: false,
                maxResolution: .uhd4K, modelName: "Apple TV 4K (1st gen)"
            )
        // Apple TV HD (4th gen, 2015) - A8
        case let m where m.hasPrefix("AppleTV5"):
            return DeviceCapabilities(
                supportsHEVC: false, supportsHEVC10Bit: false,
                supportsHDR10: false, supportsDolbyVision: false,
                supportsHDR10Plus: false, supportsAV1: false,
                maxResolution: .hd1080p, modelName: "Apple TV HD"
            )
        default:
            return defaultCapabilities(model: model)
        }
    }

    // MARK: - iOS/iPadOS Detection

    private static func detectIOSCapabilities(model: String) -> DeviceCapabilities {
        switch model {
        // iPhone 16 Pro / Pro Max - A18 Pro
        case let m where m.hasPrefix("iPhone17,1") || m.hasPrefix("iPhone17,2"):
            return DeviceCapabilities(
                supportsHEVC: true, supportsHEVC10Bit: true,
                supportsHDR10: true, supportsDolbyVision: true,
                supportsHDR10Plus: true, supportsAV1: true,
                maxResolution: .uhd4K, modelName: "iPhone 16 Pro"
            )
        // iPhone 16 / 16 Plus - A18
        case let m where m.hasPrefix("iPhone17"):
            return DeviceCapabilities(
                supportsHEVC: true, supportsHEVC10Bit: true,
                supportsHDR10: true, supportsDolbyVision: true,
                supportsHDR10Plus: true, supportsAV1: true,
                maxResolution: .uhd4K, modelName: "iPhone 16"
            )
        // iPhone 15 Pro / Pro Max - A17 Pro (first iPhone with AV1 hardware decode)
        case let m where m.hasPrefix("iPhone16,1") || m.hasPrefix("iPhone16,2"):
            return DeviceCapabilities(
                supportsHEVC: true, supportsHEVC10Bit: true,
                supportsHDR10: true, supportsDolbyVision: true,
                supportsHDR10Plus: true, supportsAV1: true,
                maxResolution: .uhd4K, modelName: "iPhone 15 Pro"
            )
        // iPhone 15 / 15 Plus - A16
        case let m where m.hasPrefix("iPhone15,4") || m.hasPrefix("iPhone15,5") || m.hasPrefix("iPhone16"):
            return DeviceCapabilities(
                supportsHEVC: true, supportsHEVC10Bit: true,
                supportsHDR10: true, supportsDolbyVision: true,
                supportsHDR10Plus: false, supportsAV1: false,
                maxResolution: .uhd4K, modelName: "iPhone 15"
            )
        // iPad Pro M4 (2024)
        case let m where m.hasPrefix("iPad16"):
            return DeviceCapabilities(
                supportsHEVC: true, supportsHEVC10Bit: true,
                supportsHDR10: true, supportsDolbyVision: true,
                supportsHDR10Plus: true, supportsAV1: true,
                maxResolution: .uhd4K, modelName: "iPad Pro M4"
            )
        // iPad Pro M2/M1, iPad Air M2/M1
        case let m where m.hasPrefix("iPad14") || m.hasPrefix("iPad13"):
            return DeviceCapabilities(
                supportsHEVC: true, supportsHEVC10Bit: true,
                supportsHDR10: true, supportsDolbyVision: true,
                supportsHDR10Plus: false, supportsAV1: false,
                maxResolution: .uhd4K, modelName: "iPad Pro/Air M-series"
            )
        // Older iPhones (A12+) — HEVC but no AV1
        case let m where m.hasPrefix("iPhone"):
            return DeviceCapabilities(
                supportsHEVC: true, supportsHEVC10Bit: true,
                supportsHDR10: true, supportsDolbyVision: true,
                supportsHDR10Plus: false, supportsAV1: false,
                maxResolution: .hd1080p, modelName: "iPhone"
            )
        // Older iPads
        case let m where m.hasPrefix("iPad"):
            return DeviceCapabilities(
                supportsHEVC: true, supportsHEVC10Bit: true,
                supportsHDR10: true, supportsDolbyVision: false,
                supportsHDR10Plus: false, supportsAV1: false,
                maxResolution: .hd1080p, modelName: "iPad"
            )
        default:
            return defaultCapabilities(model: model)
        }
    }

    // MARK: - Default / Simulator

    private static func defaultCapabilities(model: String) -> DeviceCapabilities {
        #if targetEnvironment(simulator)
        // QA : XFINN_DEBUG_FULL_CAPS=1 (simctl : SIMCTL_CHILD_…) fait déclarer au
        // simulateur les capacités d'un appareil réel (HEVC, HDR), pour obtenir
        // du serveur le même flux qu'un iPhone ou une Apple TV
        if ProcessInfo.processInfo.environment["XFINN_DEBUG_FULL_CAPS"] == "1" {
            return DeviceCapabilities(
                supportsHEVC: true, supportsHEVC10Bit: true,
                supportsHDR10: true, supportsDolbyVision: true,
                supportsHDR10Plus: true, supportsAV1: false,
                maxResolution: .uhd4K, modelName: "Simulator (full caps)"
            )
        }
        return DeviceCapabilities(
            supportsHEVC: false, supportsHEVC10Bit: false,
            supportsHDR10: false, supportsDolbyVision: false,
            supportsHDR10Plus: false, supportsAV1: false,
            maxResolution: .hd1080p, modelName: "Simulator"
        )
        #else
        return DeviceCapabilities(
            supportsHEVC: true, supportsHEVC10Bit: true,
            supportsHDR10: true, supportsDolbyVision: true,
            supportsHDR10Plus: true, supportsAV1: true,
            maxResolution: .uhd4K, modelName: "Unknown (\(model))"
        )
        #endif
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
