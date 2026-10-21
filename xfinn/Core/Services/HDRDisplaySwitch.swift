//
//  HDRDisplaySwitch.swift
//  xfinn
//
//  tvOS : bascule l'écran en HDR AVANT de charger un flux HLS HDR.
//
//  Avec « Respecter la plage dynamique », l'Apple TV reste en SDR jusqu'à ce
//  que le contenu soit connu ; or AVPlayer choisit sa variante HLS au
//  chargement, écran encore SDR : il écarte la variante HEVC HDR copiée par
//  Jellyfin (« ouverture impossible ») et prend la variante H.264 SDR que le
//  serveur réencode en 4K à ~8 i/s. En annonçant le format à l'avance, l'écran
//  bascule, et la variante copiée est acceptée.
//

#if os(tvOS)
import AVKit
import CoreMedia
import UIKit

enum HDRDisplaySwitch {

    /// Critères d'affichage d'une vidéo HDR (nil : SDR ou format inconnu)
    static func criteria(for video: MediaStreamInfo) -> AVDisplayCriteria? {
        guard let rangeType = video.videoRangeType else { return nil }

        let isDolbyVision = rangeType.hasPrefix("DOVI")
        let transfer: CFString
        switch rangeType {
        case "HDR10", "HDR10Plus", "DOVI", "DOVIWithHDR10", "DOVIWithHDR10Plus":
            transfer = kCMFormatDescriptionTransferFunction_SMPTE_ST_2084_PQ
        case "HLG", "DOVIWithHLG":
            transfer = kCMFormatDescriptionTransferFunction_ITU_R_2100_HLG
        default:
            return nil
        }

        let extensions: [CFString: Any] = [
            kCMFormatDescriptionExtension_ColorPrimaries: kCMFormatDescriptionColorPrimaries_ITU_R_2020,
            kCMFormatDescriptionExtension_TransferFunction: transfer,
            kCMFormatDescriptionExtension_YCbCrMatrix: kCMFormatDescriptionYCbCrMatrix_ITU_R_2020
        ]
        var formatDescription: CMVideoFormatDescription?
        let status = CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: isDolbyVision ? kCMVideoCodecType_DolbyVisionHEVC : kCMVideoCodecType_HEVC,
            width: Int32(video.width ?? 3840),
            height: Int32(video.height ?? 2160),
            extensions: extensions as CFDictionary,
            formatDescriptionOut: &formatDescription
        )
        guard status == noErr, let formatDescription else { return nil }

        let frameRate = Float(video.realFrameRate ?? video.averageFrameRate ?? 0)
        return AVDisplayCriteria(refreshRate: frameRate, formatDescription: formatDescription)
    }

    /// Demande la bascule et attend qu'elle se termine (bornée : l'écran
    /// peut ne jamais basculer, réglage désactivé ou TV sans HDR)
    @MainActor
    static func apply(_ criteria: AVDisplayCriteria) async {
        guard let manager = displayManager, manager.isDisplayCriteriaMatchingEnabled else { return }
        manager.preferredDisplayCriteria = criteria

        // La bascule démarre un peu après la demande, puis dure 1 à 3 s
        let start = Date()
        while !manager.isDisplayModeSwitchInProgress, Date().timeIntervalSince(start) < 1 {
            try? await Task.sleep(for: .milliseconds(100))
        }
        while manager.isDisplayModeSwitchInProgress, Date().timeIntervalSince(start) < 8 {
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    /// Retour au mode de l'interface en quittant le lecteur
    @MainActor
    static func reset() {
        guard let manager = displayManager, manager.preferredDisplayCriteria != nil else { return }
        manager.preferredDisplayCriteria = nil
    }

    @MainActor
    private static var displayManager: AVDisplayManager? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .avDisplayManager
    }
}
#endif
