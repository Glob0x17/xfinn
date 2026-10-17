//
//  EpisodeOrderingTests.swift
//  xfinnTests
//
//  Tests du tri des épisodes (saison puis numéro) utilisé par la sélection
//  de l'épisode suivant pour l'auto-play.
//

import XCTest
@testable import xfinn

final class EpisodeOrderingTests: XCTestCase {

    private func episode(_ id: String, season: Int?, number: Int?) -> MediaItem {
        MediaItem(id: id, name: "Ep \(id)", type: "Episode",
                  indexNumber: number, parentIndexNumber: season)
    }

    func testSortsBySeasonThenEpisodeNumber() {
        let shuffled = [
            episode("s2e1", season: 2, number: 1),
            episode("s1e2", season: 1, number: 2),
            episode("s2e2", season: 2, number: 2),
            episode("s1e1", season: 1, number: 1)
        ]

        let sorted = shuffled.sortedByEpisodeOrder()
        XCTAssertEqual(sorted.map(\.id), ["s1e1", "s1e2", "s2e1", "s2e2"])
    }

    func testMissingNumbersSortFirst() {
        let items = [
            episode("b", season: 1, number: 2),
            episode("a", season: 1, number: nil),
            episode("c", season: nil, number: 1)
        ]

        let sorted = items.sortedByEpisodeOrder()
        // season nil → 0 : passe avant la saison 1 ; number nil → 0
        XCTAssertEqual(sorted.map(\.id), ["c", "a", "b"])
    }

    func testNextEpisodeSelection() {
        let episodes = [
            episode("s1e1", season: 1, number: 1),
            episode("s1e2", season: 1, number: 2),
            episode("s2e1", season: 2, number: 1)
        ].sortedByEpisodeOrder()

        // Le "suivant" de la fin de saison 1 est le début de saison 2
        let currentIndex = episodes.firstIndex { $0.id == "s1e2" }!
        XCTAssertEqual(episodes[currentIndex + 1].id, "s2e1")

        // Dernier épisode : pas de suivant
        let lastIndex = episodes.firstIndex { $0.id == "s2e1" }!
        XCTAssertEqual(lastIndex, episodes.count - 1)
    }
}
