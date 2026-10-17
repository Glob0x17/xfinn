//
//  LibrarySortOptionTests.swift
//  xfinnTests
//
//  Tests du mapping options de tri → paramètres API Jellyfin
//  (valeurs validées contre un serveur 10.11 réel).
//

import XCTest
@testable import xfinn

final class LibrarySortOptionTests: XCTestCase {

    func testNameSortsAscendingBySortName() {
        XCTAssertEqual(LibrarySortOption.name.apiSortBy, "SortName")
        XCTAssertEqual(LibrarySortOption.name.apiSortOrder, "Ascending")
    }

    func testNonAlphabeticalSortsAreDescendingWithStableSecondary() {
        for option in [LibrarySortOption.dateAdded, .rating, .year] {
            XCTAssertEqual(option.apiSortOrder, "Descending", "\(option)")
            XCTAssertTrue(option.apiSortBy.hasSuffix(",SortName"),
                          "\(option) doit avoir SortName en tri secondaire")
        }
    }

    func testApiFieldNames() {
        XCTAssertEqual(LibrarySortOption.dateAdded.apiSortBy, "DateCreated,SortName")
        XCTAssertEqual(LibrarySortOption.rating.apiSortBy, "CommunityRating,SortName")
        XCTAssertEqual(LibrarySortOption.year.apiSortBy, "ProductionYear,SortName")
    }

    func testItemsResponseDecodesTotalRecordCount() throws {
        let json = """
        {"Items":[{"Id":"1","Name":"Film","Type":"Movie"}],
         "TotalRecordCount":107,"StartIndex":0}
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ItemsResponse.self, from: json)
        XCTAssertEqual(response.totalRecordCount, 107)
        XCTAssertEqual(response.items.count, 1)
    }
}
