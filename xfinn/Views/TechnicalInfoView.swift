//
//  TechnicalInfoView.swift
//  xfinn
//
//  Created by Claude on 10/01/2026.
//  Technical playback information panel for tvOS player.
//

import SwiftUI

#if os(tvOS)
import UIKit

/// Vue compacte affichant les informations techniques de lecture
struct TechnicalInfoView: View {
    let info: PlaybackTechnicalInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // En-tête mode de lecture
            HStack(spacing: 12) {
                Image(systemName: info.playMethodIcon)
                    .font(.title3)
                    .foregroundColor(playMethodColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(info.playMethodDescription)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(playMethodSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()
                .background(Color.white.opacity(0.3))

            // Grille d'informations compacte
            LazyVGrid(columns: [
                GridItem(.flexible(), alignment: .leading),
                GridItem(.flexible(), alignment: .leading)
            ], spacing: 12) {
                // Source
                if let container = info.container {
                    infoItem(label: "tech.container".localized, value: container)
                }
                if let bitrate = info.sourceBitrateFormatted {
                    infoItem(label: "tech.source_bitrate".localized, value: bitrate)
                }

                // Vidéo
                if let codec = info.videoCodec {
                    infoItem(label: "tech.video".localized, value: codec)
                }
                if let resolution = info.videoResolution {
                    infoItem(label: "tech.resolution".localized, value: resolution)
                }

                // Audio
                if let codec = info.audioCodec {
                    infoItem(label: "tech.audio".localized, value: codec)
                }
                if let channels = info.audioChannels {
                    infoItem(label: "tech.channels".localized, value: channels)
                }

                // Transcodage
                if info.isTranscoding {
                    if let videoCodec = info.transcodingVideoCodec {
                        infoItem(label: "tech.video_transcode".localized, value: videoCodec, highlight: true)
                    }
                    if let bitrate = info.transcodingBitrateFormatted {
                        infoItem(label: "tech.target_bitrate".localized, value: bitrate, highlight: true)
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 500)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
        )
    }

    private var playMethodColor: Color {
        switch info.playMethod {
        case .directPlay:
            return .green
        case .directStream:
            return .blue
        case .transcode:
            return .orange
        }
    }

    private var playMethodSubtitle: String {
        switch info.playMethod {
        case .directPlay:
            return "tech.direct_play".localized
        case .directStream:
            return "tech.direct_stream".localized
        case .transcode:
            return "tech.transcoding".localized
        }
    }

    private func infoItem(label: String, value: String, highlight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(highlight ? .orange : .white)
        }
    }
}

// MARK: - UIKit Hosting Controller

/// UIHostingController pour intégrer TechnicalInfoView dans AVPlayerViewController
final class TechnicalInfoViewController: UIHostingController<TechnicalInfoView> {

    init(info: PlaybackTechnicalInfo) {
        super.init(rootView: TechnicalInfoView(info: info))
        self.title = "tech.details".localized
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        // Taille préférée pour le panneau
        preferredContentSize = CGSize(width: 500, height: 300)
    }
}

#endif
