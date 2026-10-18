//
//  AudioTrackMatchingTests.swift
//  xfinnTests
//
//  Choix de la piste audio en Direct Play : un MP4 VF + VO dont les deux pistes
//  sont actives les jouait simultanément (Air Crash Investigation S05E01).
//

import XCTest
@testable import xfinn

final class AudioTrackMatchingTests: XCTestCase {

    private func audioStream(_ index: Int, lang: String?, isDefault: Bool = false) -> MediaStream {
        let json = """
        {"Index": \(index), "Type": "Audio", "IsDefault": \(isDefault)\(lang.map { ", \"Language\": \"\($0)\"" } ?? "")}
        """.data(using: .utf8)!
        return try! JSONDecoder().decode(MediaStream.self, from: json)
    }

    // fra (index 1), eng (index 2) — comme le fichier S05E01
    private var vfvo: [MediaStream] { [audioStream(1, lang: "fra", isDefault: true), audioStream(2, lang: "eng")] }

    func testSelectedStreamMatchedByLanguage() {
        XCTAssertEqual(AudioTrackMatching.trackPosition(streams: vfvo, selectedIndex: 2, trackLanguages: ["fr", "en"]), 1)
        XCTAssertEqual(AudioTrackMatching.trackPosition(streams: vfvo, selectedIndex: 1, trackLanguages: ["fr", "en"]), 0)
    }

    func testLanguageMatchIgnoresTrackOrder() {
        // Pistes du fichier dans l'ordre inverse des flux Jellyfin
        XCTAssertEqual(AudioTrackMatching.trackPosition(streams: vfvo, selectedIndex: 1, trackLanguages: ["eng", "fre"]), 1)
    }

    func testNoSelectionFallsBackToDefaultStream() {
        XCTAssertEqual(AudioTrackMatching.trackPosition(streams: vfvo, selectedIndex: nil, trackLanguages: ["fra", "eng"]), 0)
    }

    func testUnknownTrackLanguagesFallBackToPosition() {
        XCTAssertEqual(AudioTrackMatching.trackPosition(streams: vfvo, selectedIndex: 2, trackLanguages: [nil, nil]), 1)
    }

    func testAmbiguousLanguageFallsBackToPosition() {
        // Deux pistes françaises (ex. stéréo + 5.1) : la langue ne suffit pas
        let streams = [audioStream(1, lang: "fra"), audioStream(2, lang: "fra")]
        XCTAssertEqual(AudioTrackMatching.trackPosition(streams: streams, selectedIndex: 2, trackLanguages: ["fr", "fr"]), 1)
    }

    func testNoTracksGivesNil() {
        XCTAssertNil(AudioTrackMatching.trackPosition(streams: vfvo, selectedIndex: 1, trackLanguages: []))
    }
}
