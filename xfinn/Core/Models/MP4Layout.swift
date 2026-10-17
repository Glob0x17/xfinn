//
//  MP4Layout.swift
//  xfinn
//
//  Détection des MP4 fragmentés à partir des premiers octets du fichier.
//
//  Problème (mesuré sur serveur réel) : un MP4 fragmenté (moov minimal +
//  sidx + suite de moof/mdat) servi en Direct Play bloque AVPlayer —
//  `AVURLAsset.load(.isPlayable)` parcourt les fragments un par un en
//  requêtes Range sur tout le fichier et ne rend la main qu'après plusieurs
//  minutes. Le même fichier remuxé en HLS par Jellyfin démarre normalement.
//  Courant sur les WEB-DL et les sorties de certains outils d'enregistrement.
//

import Foundation

enum MP4Layout {

    /// Nombre d'octets à lire en tête de fichier pour trancher : un moov de
    /// fichier fragmenté ne contient pas de table d'échantillons, il tient
    /// largement dans cette fenêtre
    static let probeLength = 64 * 1024

    /// Conteneurs Jellyfin concernés (MediaSource.Container)
    static func isMP4Family(container: String?) -> Bool {
        guard let container = container?.lowercased() else { return false }
        return container.split(separator: ",").contains { ["mp4", "m4v", "mov"].contains($0.trimmingCharacters(in: .whitespaces)) }
    }

    /// Analyse les boîtes de premier niveau d'un début de fichier MP4.
    /// - Returns: `true` si fragmenté (moof/sidx/styp en tête, ou mvex dans
    ///   moov), `false` si structure classique (mdat ou moov sans mvex),
    ///   `nil` si les octets ne permettent pas de conclure.
    /// Fonction pure, testée dans xfinnTests
    static func isFragmented(prefix data: Data) -> Bool? {
        let bytes = [UInt8](data)
        var offset = 0
        var sawCompleteMoovWithoutMvex = false

        while offset + 8 <= bytes.count {
            guard let box = readBoxHeader(bytes, at: offset) else { return nil }

            switch box.type {
            case "moof", "sidx", "styp", "mvex":
                return true
            case "mdat":
                // Données média avant tout fragment : MP4 classique
                // (moov en tête déjà vu, ou moov en fin de fichier)
                return false
            case "moov":
                let end = box.size == 0 ? bytes.count : offset + box.size
                if containsChild("mvex", in: bytes, from: offset + box.headerSize, to: min(end, bytes.count)) {
                    return true
                }
                // moov tronqué par la fenêtre, sans mvex dans la partie lue
                guard end <= bytes.count else { return nil }
                // moov complet sans mvex : la boîte suivante tranche
                // (mdat → classique, moof → fragmenté atypique)
                sawCompleteMoovWithoutMvex = true
            default:
                break
            }

            // size 0 = boîte jusqu'à la fin du fichier
            guard box.size > 0 else { return nil }
            offset += box.size
        }

        return sawCompleteMoovWithoutMvex ? false : nil
    }

    // MARK: - Private

    private struct BoxHeader {
        let type: String
        let size: Int
        let headerSize: Int
    }

    private static func readBoxHeader(_ bytes: [UInt8], at offset: Int) -> BoxHeader? {
        guard offset + 8 <= bytes.count else { return nil }

        let size32 = bytes[offset..<offset + 4].reduce(0) { ($0 << 8) | Int($1) }
        guard let type = String(bytes: bytes[offset + 4..<offset + 8], encoding: .isoLatin1) else { return nil }

        if size32 == 1 {
            // Taille 64 bits
            guard offset + 16 <= bytes.count else { return nil }
            let size64 = bytes[offset + 8..<offset + 16].reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
            guard size64 >= 16, size64 <= UInt64(Int.max) else { return nil }
            return BoxHeader(type: type, size: Int(size64), headerSize: 16)
        }

        guard size32 == 0 || size32 >= 8 else { return nil }
        return BoxHeader(type: type, size: size32, headerSize: 8)
    }

    private static func containsChild(_ type: String, in bytes: [UInt8], from start: Int, to end: Int) -> Bool {
        var offset = start
        while offset + 8 <= end {
            guard let box = readBoxHeader(bytes, at: offset), box.size > 0 else { return false }
            if box.type == type { return true }
            offset += box.size
        }
        return false
    }
}
