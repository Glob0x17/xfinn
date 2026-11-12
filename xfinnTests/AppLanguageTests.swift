//
//  AppLanguageTests.swift
//  xfinnTests
//
//  Langue choisie dans les réglages : les chaînes suivent le choix,
//  et « Système » rend la main à la résolution du bundle principal.
//

import XCTest
@testable import xfinn

final class AppLanguageTests: XCTestCase {

    private var saved: String?

    override func setUp() {
        super.setUp()
        saved = UserDefaults.standard.appLanguage
    }

    override func tearDown() {
        AppLanguage.selected = saved
        super.tearDown()
    }

    func testEverySupportedLanguageHasStrings() {
        for code in AppLanguage.supported {
            XCTAssertNotNil(Bundle.main.path(forResource: code, ofType: "lproj"), code)
        }
    }

    func testEveryLanguageHasEveryKey() throws {
        func keys(_ code: String) throws -> Set<String> {
            let path = try XCTUnwrap(Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: code))
            return Set((NSDictionary(contentsOfFile: path) as? [String: String] ?? [:]).keys)
        }
        let reference = try keys("en")
        for code in AppLanguage.supported {
            XCTAssertEqual(try keys(code), reference, code)
        }
    }

    func testSelectedLanguageDrivesStrings() {
        AppLanguage.selected = "fr"
        XCTAssertEqual("settings.title".localized, "Paramètres")
        AppLanguage.selected = "es"
        XCTAssertEqual("settings.language".localized, "Idioma")
        AppLanguage.selected = "de"
        XCTAssertEqual("settings.title".localized, "Einstellungen")
        AppLanguage.selected = "it"
        XCTAssertEqual("settings.title".localized, "Impostazioni")
    }

    func testSystemFallsBackToMainBundle() {
        AppLanguage.selected = nil
        XCTAssertIdentical(AppLanguage.bundle, Bundle.main)
        XCTAssertEqual(AppLanguage.effective, Bundle.main.preferredLocalizations.first)
    }

    func testUnknownStoredCodeMeansSystem() {
        UserDefaults.standard.appLanguage = "xx"
        XCTAssertNil(AppLanguage.selected)
    }

    func testNativeNames() {
        XCTAssertEqual(AppLanguage.nativeName(of: "fr"), "Français")
        XCTAssertEqual(AppLanguage.nativeName(of: "es"), "Español")
        XCTAssertEqual(AppLanguage.nativeName(of: "de"), "Deutsch")
        XCTAssertEqual(AppLanguage.nativeName(of: "it"), "Italiano")
    }
}
