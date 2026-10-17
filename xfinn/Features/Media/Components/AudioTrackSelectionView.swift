//
//  AudioTrackSelectionView.swift
//  xfinn
//
//  Onglet « Audio » du panneau d'infos du lecteur tvOS : liste les vraies
//  pistes audio du média et permet de basculer en cours de lecture.
//  (Le menu audio système est inutilisable sur un flux transcodé Jellyfin :
//  une seule piste muxée sans étiquette de langue → « Inconnue ».)
//

import SwiftUI
#if os(tvOS)
import UIKit
#endif

struct AudioTrackSelectionView: View {
    let streams: [MediaStream]
    let currentIndex: Int?
    let noneLabel: String
    let onSelect: (Int?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            trackButton(title: noneLabel, index: nil)

            ForEach(streams) { stream in
                trackButton(title: stream.displayName, index: stream.index)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
    }

    private func trackButton(title: String, index: Int?) -> some View {
        Button {
            onSelect(index)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: index == currentIndex ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(index == currentIndex ? .appSecondary : .appTextTertiary)
                Text(title)
                    .font(.system(size: 24, weight: index == currentIndex ? .semibold : .regular))
                    .lineLimit(1)
                Spacer()
            }
            .foregroundColor(.appTextPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(CustomCardButtonStyle(cornerRadius: 12))
    }
}

#if os(tvOS)
final class AudioTrackViewController: UIHostingController<AudioTrackSelectionView> {

    init(title: String, streams: [MediaStream], currentIndex: Int?,
         noneLabel: String, onSelect: @escaping (Int?) -> Void) {
        super.init(rootView: AudioTrackSelectionView(
            streams: streams,
            currentIndex: currentIndex,
            noneLabel: noneLabel,
            onSelect: onSelect
        ))
        self.title = title
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        preferredContentSize = CGSize(width: 600, height: 300)
    }
}
#endif
