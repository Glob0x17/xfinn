//
//  AudioStreamSelectionTests.swift
//  xfinnTests
//
//  Tests de l'auto-sélection de piste audio par langue (codes ISO 639
//  à 2 et 3 lettres normalisés).
//

import XCTest
@testable import xfinn

final class AudioStreamSelectionTests: XCTestCase {

    private func audioStream(_ index: Int, lang: String?) -> MediaStream {
        // Décodage plutôt que init membre à membre : MediaStream n'a pas d'init public
        let json = """
        {"Index": \(index), "Type": "Audio"\(lang.map { ", \"Language\": \"\($0)\"" } ?? "")}
        """.data(using: .utf8)!
        return try! JSONDecoder().decode(MediaStream.self, from: json)
    }

    func testMatchesExactLanguage() {
        let streams = [audioStream(1, lang: "eng"), audioStream(2, lang: "fra")]
        XCTAssertEqual(streams.firstAudioIndex(matchingLanguage: "fra"), 2)
        XCTAssertEqual(streams.firstAudioIndex(matchingLanguage: "eng"), 1)
    }

    func testNormalizesFrenchVariants() {
        // Le fichier dit "fra", la préférence mémorisée peut dire "fre" ou "fr"
        let streams = [audioStream(1, lang: "eng"), audioStream(2, lang: "fra")]
        XCTAssertEqual(streams.firstAudioIndex(matchingLanguage: "fre"), 2)
        XCTAssertEqual(streams.firstAudioIndex(matchingLanguage: "fr"), 2)
    }

    func testNoPreferenceOrNoMatchReturnsNil() {
        let streams = [audioStream(1, lang: "eng"), audioStream(2, lang: "fra")]
        XCTAssertNil(streams.firstAudioIndex(matchingLanguage: nil))
        XCTAssertNil(streams.firstAudioIndex(matchingLanguage: ""))
        XCTAssertNil(streams.firstAudioIndex(matchingLanguage: "jpn"))
    }

    func testStreamWithoutLanguageIsSkipped() {
        let streams = [audioStream(1, lang: nil), audioStream(2, lang: "fra")]
        XCTAssertEqual(streams.firstAudioIndex(matchingLanguage: "fra"), 2)
    }

    func testLanguageNormalization() {
        XCTAssertEqual([MediaStream].normalizeLanguage("FRA"), "fre")
        XCTAssertEqual([MediaStream].normalizeLanguage("en"), "eng")
        XCTAssertEqual([MediaStream].normalizeLanguage("ita"), "ita")
    }
}
