//
//  PlayerOptionsMenu.swift
//  xfinn
//
//  iOS : bouton de menu par-dessus le player pour choisir la piste audio et
//  la qualité (sur tvOS ce sont les onglets customInfoViewControllers, qui
//  n'existent pas sur iOS). Les sous-titres restent dans le menu natif
//  d'AVPlayerViewController, sauf en AirPlay (incrustés, voir PlayerManager).
//

#if os(iOS)
import SwiftUI

struct PlayerOptionsMenu: View {
    @ObservedObject var playerManager: PlayerManager

    var body: some View {
        Menu {
            if let item = playerManager.currentItem, item.hasMultipleAudioTracks {
                Picker(selection: audioSelection(for: item)) {
                    Text("media.audio_auto".localized).tag(Int?.none)
                    ForEach(item.audioStreams, id: \.index) { stream in
                        Text(stream.displayName).tag(Int?.some(stream.index))
                    }
                } label: {
                    Label("media.audio".localized, systemImage: "waveform")
                }
                .pickerStyle(.menu)
            }

            // En AirPlay, sous-titres incrustés par Jellyfin : le menu natif
            // n'a plus de piste à proposer, le choix passe par ici
            if playerManager.isExternalPlaybackActive,
               let item = playerManager.currentItem, !item.subtitleStreams.isEmpty {
                Picker(selection: subtitleSelection) {
                    Text("common.none".localized).tag(Int?.none)
                    ForEach(item.subtitleStreams, id: \.index) { stream in
                        Text(stream.displayName).tag(Int?.some(stream.index))
                    }
                } label: {
                    Label("media.subtitles".localized, systemImage: "captions.bubble")
                }
                .pickerStyle(.menu)
            }

            Picker(selection: qualitySelection) {
                ForEach(StreamQuality.allCases) { quality in
                    Text(quality.displayName).tag(quality)
                }
            } label: {
                Label("media.streaming_quality".localized, systemImage: "dial.medium")
            }
            .pickerStyle(.menu)
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(.ultraThinMaterial))
        }
        .accessibilityLabel("media.streaming_quality".localized)
    }

    private func audioSelection(for item: MediaItem) -> Binding<Int?> {
        Binding(
            get: { playerManager.currentAudioStreamIndex },
            set: { playerManager.switchAudioTrack(to: $0) }
        )
    }

    private var subtitleSelection: Binding<Int?> {
        Binding(
            get: { playerManager.selectedSubtitleIndex },
            set: { playerManager.switchSubtitle(to: $0) }
        )
    }

    private var qualitySelection: Binding<StreamQuality> {
        Binding(
            get: { playerManager.currentQuality },
            set: { playerManager.switchQuality(to: $0) }
        )
    }
}
#endif
