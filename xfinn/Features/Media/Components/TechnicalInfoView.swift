//
//  TechnicalInfoView.swift
//  xfinn
//
//  Created by Dorian Galiana on 10/01/2026.
//  Redesigned 08/2026: pill mode de lecture + cartes de verre par domaine
//  (vidéo, audio, fichier, transcodage), fond clair — le panneau d'infos
//  tvOS applique déjà son propre blur.
//

import SwiftUI
#if os(tvOS)
import UIKit
#endif

/// Panneau des informations techniques de lecture (onglet du lecteur tvOS)
struct TechnicalInfoView: View {
    let info: PlaybackTechnicalInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            playMethodPill

            HStack(spacing: 16) {
                if info.videoCodec != nil || info.videoResolution != nil {
                    statCard(
                        icon: "film",
                        label: "tech.video".localized,
                        value: joined(info.videoCodec, info.videoResolution)
                    )
                }

                if info.audioCodec != nil || info.audioChannels != nil {
                    statCard(
                        icon: "waveform",
                        label: "tech.audio".localized,
                        value: joined(info.audioCodec, info.audioChannels)
                    )
                }

                if info.container != nil || info.sourceBitrateFormatted != nil {
                    statCard(
                        icon: "doc",
                        label: "tech.container".localized,
                        value: joined(info.container?.uppercased(), info.sourceBitrateFormatted)
                    )
                }

                if info.isTranscoding,
                   info.transcodingVideoCodec != nil || info.transcodingBitrateFormatted != nil {
                    statCard(
                        icon: "arrow.triangle.2.circlepath",
                        label: "tech.video_transcode".localized,
                        value: joined(info.transcodingVideoCodec, info.transcodingBitrateFormatted),
                        accent: .orange
                    )
                }
            }
        }
        .padding(24)
    }

    // MARK: - Play Method

    private var playMethodPill: some View {
        HStack(spacing: 12) {
            Image(systemName: info.playMethodIcon)
                .font(.system(size: 24, weight: .semibold))

            VStack(alignment: .leading, spacing: 2) {
                Text(info.playMethodDescription)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Text(playMethodSubtitle)
                    .font(.system(size: 19))
                    .foregroundColor(.appTextSecondary)
            }
        }
        .foregroundColor(playMethodColor)
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(playMethodColor.opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(playMethodColor.opacity(0.6), lineWidth: 1.5)
        )
    }

    private var playMethodColor: Color {
        switch info.playMethod {
        case .directPlay: return .green
        case .directStream: return .blue
        case .transcode: return .orange
        }
    }

    private var playMethodSubtitle: String {
        switch info.playMethod {
        case .directPlay: return "tech.direct_play".localized
        case .directStream: return "tech.direct_stream".localized
        case .transcode: return "tech.transcoding".localized
        }
    }

    // MARK: - Stat Cards

    private func statCard(icon: String, label: String, value: String, accent: Color = .appSecondary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(accent)
                Text(label.uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appTextTertiary)
                    .kerning(1.0)
            }

            Text(value)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.appTextPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(minWidth: 180, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.glassBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent == .orange ? accent.opacity(0.5) : AppTheme.glassStroke, lineWidth: 1.5)
        )
    }

    /// "HEVC · 4K" à partir de composantes optionnelles
    private func joined(_ parts: String?...) -> String {
        parts.compactMap { $0 }.joined(separator: " · ")
    }
}

// MARK: - UIKit Hosting Controller (tvOS only)

#if os(tvOS)
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
        preferredContentSize = CGSize(width: 1000, height: 280)
    }
}
#endif
