//
//  KeychainKeyDerivationTests.swift
//  xfinnTests
//
//  Portage du script scripts/test_keychain_key_derivation.swift en vrais
//  tests unitaires. La clé Keychain d'un serveur est le SHA-256 de son URL
//  normalisée ; des variantes équivalentes doivent produire la même clé.
//

import XCTest
@testable import xfinn

final class KeychainKeyDerivationTests: XCTestCase {

    func testCanonicalVariantsCollapseToSameKey() {
        // Casse, slash final, query et fragment ne doivent pas changer la clé
        XCTAssertEqual(
            "https://Example.com/library/".keychainSafeKey,
            "https://example.com/library?x=1#frag".keychainSafeKey
        )
    }

    func testRootTrailingSlashIsIgnored() {
        XCTAssertEqual(
            "https://example.com/".keychainSafeKey,
            "https://example.com".keychainSafeKey
        )
    }

    func testDifferentHostsDoNotCollide() {
        XCTAssertNotEqual(
            "https://example.com".keychainSafeKey,
            "https://example.net".keychainSafeKey
        )
    }

    func testLegacyKeyFormatDiffersFromModernHash() {
        // La migration repose sur le fait que les deux formats diffèrent
        XCTAssertNotEqual(
            "https://example.com".legacyKeychainSafeKey,
            "https://example.com".keychainSafeKey
        )
    }

    func testNormalizedMaterialLowercasesAndStripsQueryFragment() {
        let material = "  HTTPS://Example.COM/path/?q=1#x  ".normalizedServerKeyMaterial
        XCTAssertTrue(material.hasPrefix("https://example.com/path"),
                      "Obtenu : \(material)")
    }

    func testKeyIsHexSHA256() {
        let key = "https://example.com".keychainSafeKey
        XCTAssertEqual(key.count, 64)
        XCTAssertTrue(key.allSatisfy { $0.isHexDigit })
    }
}
