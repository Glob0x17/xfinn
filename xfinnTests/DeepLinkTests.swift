//
//  DeepLinkTests.swift
//  xfinnTests
//
//  Parsing des URLs xfinn:// utilisées par l'extension Top Shelf.
//

import XCTest
@testable import xfinn

final class DeepLinkTests: XCTestCase {

    func testParsesItemURL() throws {
        let url = try XCTUnwrap(URL(string: "xfinn://item/abc123def"))
        XCTAssertEqual(DeepLink(url: url), .item(id: "abc123def"))
    }

    func testRoundTripWithItemURLBuilder() throws {
        let url = try XCTUnwrap(DeepLink.itemURL(id: "97ec3bde6a0ea08f20111e3707daac1d"))
        XCTAssertEqual(DeepLink(url: url), .item(id: "97ec3bde6a0ea08f20111e3707daac1d"))
    }

    func testRejectsForeignScheme() {
        XCTAssertNil(DeepLink(url: URL(string: "https://item/abc")!))
        XCTAssertNil(DeepLink(url: URL(string: "jellyfin://item/abc")!))
    }

    func testRejectsUnknownHostOrMissingID() {
        XCTAssertNil(DeepLink(url: URL(string: "xfinn://play/abc")!))
        XCTAssertNil(DeepLink(url: URL(string: "xfinn://item")!))
        XCTAssertNil(DeepLink(url: URL(string: "xfinn://item/")!))
    }
}
