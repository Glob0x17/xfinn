//
//  HLSSubtitleRewriteTests.swift
//  xfinnTests
//
//  Réécritures du proxy de sous-titres HLS — fixtures tirées des manifests
//  réels d'un serveur Jellyfin 10.11 (segments fMP4, carte de temps à 10 s
//  dans les VTT segmentés ; le VTT fichier-entier, lui, est sain).
//

import XCTest
@testable import xfinn

final class HLSSubtitleRewriteTests: XCTestCase {

    private let masterURL = URL(string: "http://jellyfin.local:8096/videos/abc-123/master.m3u8?api_key=k")!

    // MARK: - Master : sous-titres → playlists virtuelles, vidéo en direct

    func testMasterRewriteRoutesSubtitlesThroughProxyAndVideoDirect() {
        let master = """
        #EXTM3U
        #EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subs",NAME="Français - ASS",DEFAULT=NO,FORCED=NO,AUTOSELECT=YES,URI="abc123/Subtitles/4/subtitles.m3u8?SegmentLength=30&ApiKey=k",LANGUAGE="fra"
        #EXT-X-STREAM-INF:BANDWIDTH=20179238,CODECS="avc1.4D4028,ec-3",RESOLUTION=1920x1080,SUBTITLES="subs"
        main.m3u8?DeviceId=x&PlaySessionId=y
        """
        let output = String(data: HLSSubtitleResourceLoader.rewriteMasterPlaylist(Data(master.utf8), baseURL: masterURL), encoding: .utf8)!

        XCTAssertTrue(output.contains(#"URI="xfinnhls://jellyfin.local:8096/videos/abc-123/abc123/Subtitles/4/subtitles.m3u8?SegmentLength=30&ApiKey=k""#), output)
        XCTAssertTrue(output.contains("\nhttp://jellyfin.local:8096/videos/abc-123/main.m3u8?DeviceId=x&PlaySessionId=y"), output)
        XCTAssertTrue(output.contains(#"NAME="Français - ASS""#))
        XCTAssertTrue(output.contains(#"LANGUAGE="fra""#))
    }

    // MARK: - URL du VTT fichier-entier

    func testWholeFileVTTURLDerivation() throws {
        let playlist = URL(string: "http://jellyfin.local:8096/videos/abc-123/abc123/Subtitles/4/subtitles.m3u8?SegmentLength=30&ApiKey=secret")!
        let vtt = try XCTUnwrap(HLSSubtitleResourceLoader.wholeFileVTTURL(forSubtitlePlaylist: playlist))

        XCTAssertEqual(vtt.absoluteString,
                       "http://jellyfin.local:8096/videos/abc-123/abc123/Subtitles/4/Stream.vtt?ApiKey=secret")
    }

    func testWholeFileVTTURLRejectsNonSubtitlePlaylists() {
        XCTAssertNil(HLSSubtitleResourceLoader.wholeFileVTTURL(forSubtitlePlaylist: masterURL))
    }

    // MARK: - Playlist virtuelle mono-segment

    func testSingleSegmentPlaylistShape() {
        let vtt = URL(string: "http://h/Videos/a/b/Subtitles/4/Stream.vtt?ApiKey=k")!
        let output = String(data: HLSSubtitleResourceLoader.makeSingleSegmentPlaylist(vttURL: vtt, duration: 2489.5), encoding: .utf8)!

        XCTAssertTrue(output.hasPrefix("#EXTM3U"))
        XCTAssertTrue(output.contains("#EXT-X-TARGETDURATION:2490"))
        XCTAssertTrue(output.contains("#EXTINF:2489.500,"))
        XCTAssertTrue(output.contains("\nhttp://h/Videos/a/b/Subtitles/4/Stream.vtt?ApiKey=k\n"))
        XCTAssertTrue(output.hasSuffix("#EXT-X-ENDLIST"))
        // Le segment est en http direct : les segments média ne passent
        // jamais par le resource loader
        XCTAssertFalse(output.contains("xfinnhls"))
    }

    // MARK: - Mapping de schemes

    func testProxyURLOnlyForTranscodingMasters() {
        XCTAssertEqual(HLSSubtitleResourceLoader.proxyURL(for: masterURL)?.scheme, "xfinnhls")
        let direct = URL(string: "http://jellyfin.local:8096/Videos/abc/stream?static=true")!
        XCTAssertNil(HLSSubtitleResourceLoader.proxyURL(for: direct))
        let https = URL(string: "https://jellyfin.example.com/videos/x/master.m3u8")!
        XCTAssertEqual(HLSSubtitleResourceLoader.proxyURL(for: https)?.scheme, "xfinnhlss")
    }
}
