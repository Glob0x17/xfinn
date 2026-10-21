//
//  PlaybackInfoQueryTests.swift
//  xfinnTests
//
//  La sélection de pistes n'est honorée par Jellyfin (10.11 vérifié) que
//  via la query string de PlaybackInfo, avec MediaSourceId présent.
//  Ces tests verrouillent la forme de la requête.
//

import XCTest
@testable import xfinn

final class PlaybackInfoQueryTests: XCTestCase {

    private func dict(_ items: [URLQueryItem]) -> [String: String] {
        Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
    }

    func testAlwaysIncludesMediaSourceId() {
        let items = PlaybackService.playbackInfoQueryItems(
            itemId: "abc", audioStreamIndex: nil, subtitleStreamIndex: nil
        )
        XCTAssertEqual(dict(items)["MediaSourceId"], "abc")
        XCTAssertNil(dict(items)["AudioStreamIndex"])
        XCTAssertNil(dict(items)["SubtitleStreamIndex"])
    }

    func testIncludesSelectedStreams() {
        let items = PlaybackService.playbackInfoQueryItems(
            itemId: "abc", audioStreamIndex: 1, subtitleStreamIndex: 4
        )
        XCTAssertEqual(dict(items)["AudioStreamIndex"], "1")
        XCTAssertEqual(dict(items)["SubtitleStreamIndex"], "4")
    }

    func testDisabledSubtitlesAreExplicitMinusOne() {
        let items = PlaybackService.playbackInfoQueryItems(
            itemId: "abc", audioStreamIndex: nil, subtitleStreamIndex: -1
        )
        XCTAssertEqual(dict(items)["SubtitleStreamIndex"], "-1")
    }

    // MARK: - Sous-titre image activé d'office par Jellyfin

    private func source(defaultSubtitle: Int?, codec: String) -> MediaSourceInfo {
        MediaSourceInfo(
            mediaStreams: [
                MediaStreamInfo(type: "Video", index: 0, codec: "hevc"),
                MediaStreamInfo(type: "Subtitle", index: 4, codec: codec)
            ],
            defaultSubtitleStreamIndex: defaultSubtitle
        )
    }

    func testDefaultPGSSubtitleIsImageBased() {
        // Harry Potter : piste « Forced » PGS par défaut → incrustation
        XCTAssertTrue(source(defaultSubtitle: 4, codec: "PGSSUB").defaultSubtitleIsImageBased)
        XCTAssertTrue(source(defaultSubtitle: 4, codec: "dvdsub").defaultSubtitleIsImageBased)
    }

    func testTextOrNoDefaultSubtitleIsNotImageBased() {
        // Sully : forcés en SRT, servis en rendition HLS
        XCTAssertFalse(source(defaultSubtitle: 4, codec: "subrip").defaultSubtitleIsImageBased)
        XCTAssertFalse(source(defaultSubtitle: -1, codec: "PGSSUB").defaultSubtitleIsImageBased)
        XCTAssertFalse(source(defaultSubtitle: nil, codec: "PGSSUB").defaultSubtitleIsImageBased)
    }
}
