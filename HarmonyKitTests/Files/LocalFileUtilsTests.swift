//
//  LocalFileUtilsTests.swift
//  HarmonyKitTests
//
//  Created by Claudio Cambra on 20/1/24.
//

import XCTest
@testable import HarmonyKit

class LocalFileUtilsTests: XCTestCase {
    func testMD5ChecksumCalc() {
        let testBundle = Bundle(for: type(of: self))
        let testAudioURL = testBundle.url(
            forResource: "Free_Test_Data_1MB_MP3",
            withExtension: "mp3"
        )!
        let checksum = calculateMD5Checksum(forFileAtLocalURL: testAudioURL)
        XCTAssertNotNil(checksum, "Checksum should not be nil!")
    }

    func testSongsFromLocalUrls() async {
        let testBundle = Bundle(for: type(of: self))
        let testAudioURL = testBundle.url(
            forResource: "Free_Test_Data_1MB_MP3",
            withExtension: "mp3"
        )!
        let songs = await songsFromLocalUrls([testAudioURL])
        XCTAssertEqual(songs.count, 1, "Should acquire 1 song from local URL!")
    }
}
