//
//  DeviceProfileAudioFallbackTests.swift
//  xfinnTests
//
//  Le profil de repli (après échec d'un remux EAC3/AC3 → fMP4) doit forcer
//  le réencodage audio côté transcodage sans toucher au Direct Play.
//

import XCTest
@testable import xfinn

final class DeviceProfileAudioFallbackTests: XCTestCase {

    func testDefaultProfileKeepsEAC3Passthrough() {
        let profile = DeviceProfile.currentProfile(maxBitrate: nil)
        let audio = profile.transcodingProfiles?.first?.audioCodec ?? ""
        XCTAssertTrue(audio.split(separator: ",").contains("eac3"), "eac3 attendu dans \(audio)")
    }

    func testFallbackProfileForcesAACInTranscodingOnly() {
        let normal = DeviceProfile.currentProfile(maxBitrate: nil)
        let fallback = DeviceProfile.currentProfile(maxBitrate: nil, forceAudioTranscode: true)

        XCTAssertEqual(fallback.transcodingProfiles?.first?.audioCodec, DeviceProfile.audioFallbackTranscodeCodec)
        XCTAssertEqual(fallback.transcodingProfiles?.first?.videoCodec, normal.transcodingProfiles?.first?.videoCodec)
        XCTAssertEqual(
            fallback.directPlayProfiles?.map { $0.audioCodec },
            normal.directPlayProfiles?.map { $0.audioCodec },
            "Le Direct Play ne doit pas changer en repli"
        )
    }
}
