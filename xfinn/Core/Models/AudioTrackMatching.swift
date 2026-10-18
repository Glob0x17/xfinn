//
//  AudioTrackMatching.swift
//  xfinn
//
//  Choix de la piste audio d'un fichier lu en Direct Play.
//
//  En Direct Play, AVPlayer lit le fichier tel quel : l'AudioStreamIndex envoyé à
//  Jellyfin ne sert qu'au transcodage. Un MP4 dont toutes les pistes audio sont
//  actives (sans groupe alternatif) les joue simultanément — VF et VO superposées.
//  La piste voulue doit donc être retrouvée parmi les pistes du fichier.
//

import Foundation

enum AudioTrackMatching {

    /// Flux audio Jellyfin à lire : celui choisi, sinon le flux par défaut, sinon le premier
    static func wantedStream(in streams: [MediaStream], selectedIndex: Int?) -> MediaStream? {
        streams.first { $0.index == selectedIndex }
            ?? streams.first { $0.isDefault == true }
            ?? streams.first
    }

    /// Position (parmi les pistes audio du fichier, dans l'ordre) de la piste à lire.
    /// - Parameters:
    ///   - streams: flux audio Jellyfin, dans l'ordre du fichier
    ///   - selectedIndex: AudioStreamIndex choisi (nil = défaut)
    ///   - trackLanguages: langue de chaque piste audio du fichier (nil si inconnue)
    /// Par langue d'abord (si elle désigne une seule piste), sinon par position du flux.
    /// Fonction pure, testée dans xfinnTests
    static func trackPosition(streams: [MediaStream], selectedIndex: Int?, trackLanguages: [String?]) -> Int? {
        guard !trackLanguages.isEmpty, let wanted = wantedStream(in: streams, selectedIndex: selectedIndex) else {
            return nil
        }

        if let language = wanted.language {
            let normalized = [MediaStream].normalizeLanguage(language)
            let matches = trackLanguages.indices.filter { position in
                guard let trackLanguage = trackLanguages[position] else { return false }
                return [MediaStream].normalizeLanguage(trackLanguage) == normalized
            }
            if matches.count == 1 {
                return matches[0]
            }
        }

        guard let position = streams.firstIndex(where: { $0.index == wanted.index }),
              position < trackLanguages.count else {
            return nil
        }
        return position
    }
}
