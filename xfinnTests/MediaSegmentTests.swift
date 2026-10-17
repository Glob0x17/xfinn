//
//  MediaSegmentTests.swift
//  xfinnTests
//
//  Tests du modèle MediaSegment (décodage, conversion ticks) et de la
//  résolution du segment actif utilisée par le bouton "Passer l'intro".
//

import XCTest
@testable import xfinn

final class MediaSegmentTests: XCTestCase {

    // MARK: - Décodage (fixture = réponse réelle du serveur 10.11.11)

    func testDecodesRealServerResponse() throws {
        let json = """
        {"Items":[{"Id":"5bbbd9394a3a436ca38add3e9553ab8c",
                   "ItemId":"dfa3c073f2ab40e3afa436cc34f2c9ed",
                   "Type":"Outro",
                   "StartTicks":25253140000,
                   "EndTicks":25626850000}],
         "TotalRecordCount":1,"StartIndex":0}
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(MediaSegmentsResponse.self, from: json)
        XCTAssertEqual(response.items.count, 1)

        let segment = try XCTUnwrap(response.items.first)
        XCTAssertEqual(segment.type, .outro)
        XCTAssertEqual(segment.startSeconds, 2525.314, accuracy: 0.001)
        XCTAssertEqual(segment.endSeconds, 2562.685, accuracy: 0.001)
    }

    func testUnknownSegmentTypeDecodesAsUnknown() throws {
        let json = """
        {"Items":[{"Id":"a","ItemId":"b","Type":"SomethingNew",
                   "StartTicks":0,"EndTicks":10000000}]}
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(MediaSegmentsResponse.self, from: json)
        XCTAssertEqual(response.items.first?.type, .unknown)
        XCTAssertEqual(response.items.first?.type.isSkippable, false)
    }

    // MARK: - Résolution du segment actif

    private func segment(_ id: String, type: MediaSegment.SegmentType,
                         start: TimeInterval, end: TimeInterval) -> MediaSegment {
        MediaSegment(id: id, itemId: "item", type: type,
                     startTicks: Int64(start * 10_000_000),
                     endTicks: Int64(end * 10_000_000))
    }

    func testActiveSegmentWithinBounds() {
        let segments = [segment("intro", type: .intro, start: 10, end: 90)]

        XCTAssertNil(segments.activeSegment(at: 9.9, excluding: nil))
        XCTAssertEqual(segments.activeSegment(at: 10, excluding: nil)?.id, "intro")
        XCTAssertEqual(segments.activeSegment(at: 89.9, excluding: nil)?.id, "intro")
        // Borne haute exclusive : à la fin du segment, plus de bouton
        XCTAssertNil(segments.activeSegment(at: 90, excluding: nil))
    }

    func testSuppressedSegmentIsExcluded() {
        let segments = [segment("intro", type: .intro, start: 10, end: 90)]

        XCTAssertNil(segments.activeSegment(at: 50, excluding: "intro"))
        // Un autre id supprimé ne masque pas ce segment
        XCTAssertEqual(segments.activeSegment(at: 50, excluding: "autre")?.id, "intro")
    }

    func testNonSkippableTypesAreIgnored() {
        let segments = [
            segment("pub", type: .commercial, start: 0, end: 100),
            segment("preview", type: .preview, start: 0, end: 100)
        ]
        XCTAssertNil(segments.activeSegment(at: 50, excluding: nil))
    }

    func testPicksCorrectSegmentAmongSeveral() {
        let segments = [
            segment("recap", type: .recap, start: 0, end: 30),
            segment("intro", type: .intro, start: 30, end: 95),
            segment("outro", type: .outro, start: 2500, end: 2560)
        ]

        XCTAssertEqual(segments.activeSegment(at: 15, excluding: nil)?.type, .recap)
        XCTAssertEqual(segments.activeSegment(at: 60, excluding: nil)?.type, .intro)
        XCTAssertEqual(segments.activeSegment(at: 2530, excluding: nil)?.type, .outro)
        XCTAssertNil(segments.activeSegment(at: 1000, excluding: nil))
    }
}
