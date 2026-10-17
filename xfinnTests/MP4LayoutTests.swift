//
//  MP4LayoutTests.swift
//  xfinnTests
//
//  Détection des MP4 fragmentés (Direct Play bloquant AVPlayer). Les trois
//  structures testées sont celles relevées sur le serveur réel : fragmenté
//  (ftyp/free/moov+mvex/sidx/moof…), moov en tête, moov en fin de fichier.
//

import XCTest
@testable import xfinn

final class MP4LayoutTests: XCTestCase {

    // MARK: - Helpers

    private func box(_ type: String, payload: Data = Data()) -> Data {
        var data = Data()
        let size = UInt32(8 + payload.count)
        data.append(contentsOf: withUnsafeBytes(of: size.bigEndian) { Array($0) })
        data.append(contentsOf: Array(type.utf8))
        data.append(payload)
        return data
    }

    private func largeBox(_ type: String, declaredSize: UInt64) -> Data {
        var data = Data()
        data.append(contentsOf: withUnsafeBytes(of: UInt32(1).bigEndian) { Array($0) })
        data.append(contentsOf: Array(type.utf8))
        data.append(contentsOf: withUnsafeBytes(of: declaredSize.bigEndian) { Array($0) })
        return data
    }

    private var ftyp: Data { box("ftyp", payload: Data("isom\0\0\u{2}\0isomiso2avc1mp41".utf8)) }

    // MARK: - Fragmenté

    func testFragmentedWithMvexInMoov() {
        let moov = box("moov", payload: box("mvhd", payload: Data(count: 100)) + box("mvex", payload: box("trex", payload: Data(count: 24))))
        let data = ftyp + box("free", payload: Data(count: 50)) + moov + box("sidx", payload: Data(count: 40))
        XCTAssertEqual(MP4Layout.isFragmented(prefix: data), true)
    }

    func testFragmentedDetectedOnMoofEvenWithoutMvexVisible() {
        let moov = box("moov", payload: box("mvhd", payload: Data(count: 100)))
        let data = ftyp + moov + box("moof", payload: Data(count: 20))
        XCTAssertEqual(MP4Layout.isFragmented(prefix: data), true)
    }

    func testSegmentTypeBoxIsFragmented() {
        XCTAssertEqual(MP4Layout.isFragmented(prefix: box("styp") + box("moof")), true)
    }

    // MARK: - Classique

    func testFaststartIsNotFragmented() {
        let moov = box("moov", payload: box("mvhd", payload: Data(count: 100)) + box("trak", payload: Data(count: 500)))
        let data = ftyp + moov + largeBox("mdat", declaredSize: 2_897_886_857)
        XCTAssertEqual(MP4Layout.isFragmented(prefix: data), false)
    }

    func testMoovAtEndIsNotFragmented() {
        // mdat de 1,5 Go en tête : seul son en-tête est dans la fenêtre lue
        let data = ftyp + box("free") + largeBox("mdat", declaredSize: 1_517_167_304)
        XCTAssertEqual(MP4Layout.isFragmented(prefix: data), false)
    }

    // MARK: - Indéterminé

    func testTruncatedMoovIsUndetermined() {
        // moov annoncé plus grand que la fenêtre, sans mvex dans la partie lue
        var moovHeader = Data()
        moovHeader.append(contentsOf: withUnsafeBytes(of: UInt32(1_000_000).bigEndian) { Array($0) })
        moovHeader.append(contentsOf: Array("moov".utf8))
        let data = ftyp + moovHeader + box("mvhd", payload: Data(count: 100))
        XCTAssertNil(MP4Layout.isFragmented(prefix: data))
    }

    func testGarbageIsUndetermined() {
        XCTAssertNil(MP4Layout.isFragmented(prefix: Data([0x00, 0x00, 0x00, 0x02, 0x41, 0x42])))
        XCTAssertNil(MP4Layout.isFragmented(prefix: Data()))
    }

    // MARK: - Conteneurs

    func testMP4FamilyContainers() {
        XCTAssertTrue(MP4Layout.isMP4Family(container: "mp4"))
        XCTAssertTrue(MP4Layout.isMP4Family(container: "mov,mp4,m4a,3gp,3g2,mj2"))
        XCTAssertFalse(MP4Layout.isMP4Family(container: "mkv"))
        XCTAssertFalse(MP4Layout.isMP4Family(container: nil))
    }
}
