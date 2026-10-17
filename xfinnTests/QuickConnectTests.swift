//
//  QuickConnectTests.swift
//  xfinnTests
//
//  Tests du décodage des réponses Quick Connect et du formatage du code.
//

import XCTest
@testable import xfinn

final class QuickConnectTests: XCTestCase {

    // MARK: - Décodage /QuickConnect/Initiate

    func testDecodesInitiateResponse() throws {
        let json = """
        {
            "Authenticated": false,
            "Secret": "f488b7e0ab5f4cbf9f6c057d6a75dc6d",
            "Code": "482917",
            "DeviceId": "device-1",
            "DeviceName": "Apple TV",
            "AppName": "xfinn",
            "AppVersion": "1.0.0",
            "DateAdded": "2026-08-21T10:00:00Z"
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(QuickConnectResult.self, from: json)
        XCTAssertFalse(result.authenticated)
        XCTAssertEqual(result.code, "482917")
        XCTAssertEqual(result.secret, "f488b7e0ab5f4cbf9f6c057d6a75dc6d")
    }

    // MARK: - Décodage /QuickConnect/Connect (approbation)

    func testDecodesApprovedConnectResponse() throws {
        let json = """
        { "Authenticated": true, "Secret": "abc", "Code": "111222" }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(QuickConnectResult.self, from: json)
        XCTAssertTrue(result.authenticated)
    }

    // MARK: - Formatage du code

    func testSixDigitCodeIsGrouped() {
        let result = QuickConnectResult(authenticated: false, secret: "s", code: "482917")
        XCTAssertEqual(result.formattedCode, "482 917")
    }

    func testNonStandardCodeIsLeftVerbatim() {
        XCTAssertEqual(
            QuickConnectResult(authenticated: false, secret: "s", code: "1234").formattedCode,
            "1234"
        )
        XCTAssertEqual(
            QuickConnectResult(authenticated: false, secret: "s", code: "").formattedCode,
            ""
        )
    }

    // MARK: - AuthenticateWithQuickConnect renvoie la même shape que le login classique

    func testAuthenticationResultDecodesQuickConnectResponse() throws {
        let json = """
        {
            "User": {
                "Id": "user-42",
                "Name": "dorian",
                "ServerId": "srv-1",
                "HasPassword": true
            },
            "AccessToken": "token-xyz",
            "ServerId": "srv-1"
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(AuthenticationResult.self, from: json)
        XCTAssertEqual(result.user.name, "dorian")
        XCTAssertEqual(result.accessToken, "token-xyz")
    }
}
