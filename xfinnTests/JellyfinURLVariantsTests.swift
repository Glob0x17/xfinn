//
//  JellyfinURLVariantsTests.swift
//  xfinnTests
//
//  Tests de la génération de variantes d'URL serveur — logique sensible :
//  HTTP ne doit JAMAIS être tenté implicitement pour un domaine public.
//

import XCTest
@testable import xfinn

final class JellyfinURLVariantsTests: XCTestCase {

    // MARK: - Domaines publics (HTTPS forcé)

    func testPublicDomainWithoutSchemeIsHTTPSOnly() {
        let variants = "jellyfin.example.com".jellyfinURLVariants()
        XCTAssertEqual(variants, [
            "https://jellyfin.example.com",
            "https://jellyfin.example.com:8920"
        ])
        XCTAssertFalse(variants.contains { $0.hasPrefix("http://") },
                       "Aucun fallback HTTP implicite pour un domaine public")
    }

    func testExplicitHTTPSKeepsInputAndAddsAlternatePort() {
        XCTAssertEqual("https://jellyfin.example.com".jellyfinURLVariants(), [
            "https://jellyfin.example.com",
            "https://jellyfin.example.com:8920"
        ])
    }

    func testExplicitHTTPOnPublicDomainIsRespectedButNotExtended() {
        // L'utilisateur l'a tapé explicitement : on respecte, sans ajouter
        // de port 8096 (réservé aux IP locales)
        XCTAssertEqual("http://jellyfin.example.com".jellyfinURLVariants(),
                       ["http://jellyfin.example.com"])
    }

    // MARK: - IP privées (HTTP prioritaire, port Jellyfin)

    func testPrivateIPWithoutSchemePrefersHTTP8096() {
        XCTAssertEqual("192.168.1.10".jellyfinURLVariants(), [
            "http://192.168.1.10:8096",
            "http://192.168.1.10",
            "https://192.168.1.10"
        ])
    }

    func testExplicitHTTPOnPrivateIPAddsJellyfinPort() {
        XCTAssertEqual("http://10.0.0.5".jellyfinURLVariants(), [
            "http://10.0.0.5",
            "http://10.0.0.5:8096"
        ])
    }

    // MARK: - Schéma + port explicites : utilisés tels quels

    func testFullURLIsUsedVerbatim() {
        XCTAssertEqual("https://example.com:8443".jellyfinURLVariants(),
                       ["https://example.com:8443"])
        XCTAssertEqual("http://192.168.1.10:8096".jellyfinURLVariants(),
                       ["http://192.168.1.10:8096"])
    }

    // MARK: - Entrées limites

    func testEmptyAndWhitespaceInputYieldsNoVariant() {
        XCTAssertEqual("".jellyfinURLVariants(), [])
        XCTAssertEqual("   ".jellyfinURLVariants(), [])
    }

    func testInputIsTrimmed() {
        XCTAssertEqual("  192.168.1.10  ".jellyfinURLVariants().first,
                       "http://192.168.1.10:8096")
    }

    // MARK: - isPrivateIPAddress (RFC 1918 + loopback)

    func testPrivateRanges() {
        XCTAssertTrue("10.0.0.1".isPrivateIPAddress)
        XCTAssertTrue("10.255.255.255".isPrivateIPAddress)
        XCTAssertTrue("172.16.0.1".isPrivateIPAddress)
        XCTAssertTrue("172.31.9.9".isPrivateIPAddress)
        XCTAssertTrue("192.168.0.1".isPrivateIPAddress)
        XCTAssertTrue("127.0.0.1".isPrivateIPAddress)
    }

    func testPublicAndInvalidAddressesAreNotPrivate() {
        XCTAssertFalse("8.8.8.8".isPrivateIPAddress)
        XCTAssertFalse("172.32.0.1".isPrivateIPAddress, "172.32.x.x est public")
        XCTAssertFalse("172.15.0.1".isPrivateIPAddress, "172.15.x.x est public")
        XCTAssertFalse("192.169.0.1".isPrivateIPAddress)
        XCTAssertFalse("example.com".isPrivateIPAddress)
        XCTAssertFalse("192.168.1".isPrivateIPAddress, "IP incomplète")
        XCTAssertFalse("".isPrivateIPAddress)
    }
}
