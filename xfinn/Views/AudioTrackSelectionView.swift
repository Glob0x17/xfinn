//
//  AudioTrackSelectionView.swift
//  xfinn
//
//  Audio track selection panel for tvOS player.
//  Shows available audio tracks with proper names from Jellyfin metadata
//  and allows switching during playback via AVMediaSelectionGroup.
//

import SwiftUI

#if os(tvOS)
import UIKit
import AVFoundation

/// Vue pour sélectionner la piste audio pendant la lecture
struct AudioTrackSelectionView: View {
    let audioStreams: [MediaStream]
    @Binding var selectedIndex: Int?
    let onTrackSelected: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // En-tête
            HStack(spacing: 12) {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.title3)
                    .foregroundColor(.blue)

                Text("media.audio_track".localized)
                    .font(.headline)
                    .foregroundColor(.white)
            }

            Divider()
                .background(Color.white.opacity(0.3))

            if audioStreams.isEmpty {
                Text("audio.default".localized)
                    .font(.callout)
                    .foregroundColor(.secondary)
            } else {
                // Liste des pistes audio
                ForEach(audioStreams) { stream in
                    audioTrackRow(stream: stream)
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

    private func audioTrackRow(stream: MediaStream) -> some View {
        Button(action: {
            selectedIndex = stream.index
            onTrackSelected(stream.index)
        }) {
            HStack(spacing: 12) {
                // Indicateur de sélection
                Image(systemName: selectedIndex == stream.index ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(selectedIndex == stream.index ? .blue : .gray)

                VStack(alignment: .leading, spacing: 4) {
                    // Nom de la piste (ex: "English - AAC 5.1 Surround")
                    Text(stream.displayName)
                        .font(.callout)
                        .fontWeight(selectedIndex == stream.index ? .bold : .medium)
                        .foregroundColor(selectedIndex == stream.index ? .white : .secondary)

                    // Détails (codec, langue)
                    HStack(spacing: 8) {
                        if let codec = stream.codec {
                            Text(codec.uppercased())
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                        if let lang = stream.language {
                            Text(lang.uppercased())
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        if stream.isDefault == true {
                            Text("Default")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - UIKit Hosting Controller

/// UIHostingController pour intégrer AudioTrackSelectionView dans AVPlayerViewController
final class AudioTrackSelectionViewController: UIHostingController<AudioTrackSelectionViewWrapper> {

    init(
        audioStreams: [MediaStream],
        selectedIndex: Int?,
        onTrackSelected: @escaping (Int) -> Void
    ) {
        let wrapper = AudioTrackSelectionViewWrapper(
            audioStreams: audioStreams,
            initialSelectedIndex: selectedIndex,
            onTrackSelected: onTrackSelected
        )
        super.init(rootView: wrapper)
        self.title = "media.audio_track".localized
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        preferredContentSize = CGSize(width: 500, height: 400)
    }
}

/// Wrapper pour gérer le state @Binding dans le hosting controller
struct AudioTrackSelectionViewWrapper: View {
    let audioStreams: [MediaStream]
    let onTrackSelected: (Int) -> Void
    @State private var selectedIndex: Int?

    init(audioStreams: [MediaStream], initialSelectedIndex: Int?, onTrackSelected: @escaping (Int) -> Void) {
        self.audioStreams = audioStreams
        self._selectedIndex = State(initialValue: initialSelectedIndex)
        self.onTrackSelected = onTrackSelected
    }

    var body: some View {
        AudioTrackSelectionView(
            audioStreams: audioStreams,
            selectedIndex: $selectedIndex,
            onTrackSelected: onTrackSelected
        )
    }
}

#endif
