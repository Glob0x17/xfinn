//
//  DurationFormattingTests.swift
//  xfinnTests
//
//  Tests de l'unique implémentation de formatage de durées
//  (TimeInterval+Extensions), qui a remplacé 6 copies locales.
//

import XCTest
@testable import xfinn

final class DurationFormattingTests: XCTestCase {

    // MARK: - formattedDuration ("1h 23min")

    func testHoursAndMinutes() {
        XCTAssertEqual(TimeInterval(4980).formattedDuration, "1h 23min")
        XCTAssertEqual(TimeInterval(7200).formattedDuration, "2h 0min")
    }

    func testMinutesOnly() {
        XCTAssertEqual(TimeInterval(2700).formattedDuration, "45min")
        XCTAssertEqual(TimeInterval(59).formattedDuration, "0min")
    }

    // MARK: - formattedPlaybackTime ("m:ss")

    func testClockFormat() {
        XCTAssertEqual(TimeInterval(0).formattedPlaybackTime, "0:00")
        XCTAssertEqual(TimeInterval(7).formattedPlaybackTime, "0:07")
        XCTAssertEqual(TimeInterval(187).formattedPlaybackTime, "3:07")
        XCTAssertEqual(TimeInterval(3600).formattedPlaybackTime, "60:00")
    }

    func testClockFormatIsSafeAgainstInvalidValues() {
        XCTAssertEqual(TimeInterval.nan.formattedPlaybackTime, "0:00")
        XCTAssertEqual(TimeInterval.infinity.formattedPlaybackTime, "0:00")
        XCTAssertEqual(TimeInterval(-42).formattedPlaybackTime, "0:00")
    }
}
