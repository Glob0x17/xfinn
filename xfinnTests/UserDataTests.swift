//
//  UserDataTests.swift
//  xfinnTests
//
//  Décodage de UserData (dont IsFavorite optionnel) — fixtures issues des
//  réponses réelles de POST/DELETE /UserPlayedItems et /UserFavoriteItems.
//

import XCTest
@testable import xfinn

final class UserDataTests: XCTestCase {

    func testDecodesToggleEndpointResponse() throws {
        // Réponse réelle de POST /UserFavoriteItems/{id} (serveur 10.11)
        let json = """
        {"PlaybackPositionTicks":0,"PlayCount":1,"IsFavorite":true,
         "LastPlayedDate":"2026-08-22T10:54:40.4186543Z","Played":false,
         "Key":"97ec3bde","ItemId":"97ec3bde6a0ea08f20111e3707daac1d"}
        """.data(using: .utf8)!

        let userData = try JSONDecoder().decode(UserData.self, from: json)
        XCTAssertEqual(userData.isFavorite, true)
        XCTAssertFalse(userData.played)
        XCTAssertEqual(userData.playCount, 1)
    }

    func testDecodesWithoutIsFavorite() throws {
        // Vieux serveurs : IsFavorite absent ne doit pas casser le décodage
        let json = """
        {"Played":true,"PlaybackPositionTicks":1200000000,"PlayCount":2}
        """.data(using: .utf8)!

        let userData = try JSONDecoder().decode(UserData.self, from: json)
        XCTAssertNil(userData.isFavorite)
        XCTAssertTrue(userData.played)
        XCTAssertEqual(userData.playbackPosition, 120, accuracy: 0.001)
    }
}
