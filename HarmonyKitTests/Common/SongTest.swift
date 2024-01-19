//
//  SongTest.swift
//  HarmonyKitTests
//
//  Created by Claudio Cambra on 19/1/24.
//

import XCTest
import AVFoundation
@testable import HarmonyKit // Import your module here

class SongTests: XCTestCase {
    func testInitializationWithValidURL() async {
        let testBundle = Bundle(for: type(of: self))
        let testAudioURL = testBundle.url(
            forResource: "Free_Test_Data_1MB_MP3",
            withExtension: "mp3"
        )!
        let asset = AVAsset(url: testAudioURL)
        if let song = await Song(fromAsset: asset, withIdentifier: "testID") {
            XCTAssertEqual(song.title, "Test Title", "Title should be set")
            XCTAssertEqual(song.artist, "Test Artist", "Artist should be set")
            XCTAssertEqual(song.album, "Test Album", "Album should be set")
            XCTAssertEqual(song.creator, "Test Composer", "Creator should be set")
            XCTAssertEqual(song.subject, "Test Grouping", "Subject should be set")
            XCTAssertEqual(song.contributor, "Test Performer", "Contributor should be set")
            XCTAssertEqual(song.type, "Test Genre", "Type should be set")
            XCTAssertFalse(song.identifier.isEmpty, "Identifier should not be empty")
            XCTAssertEqual(
                song.duration,
                CMTime(value: 1899648, timescale: CMTimeScale(44100)),
                "Duration should have a default value"
            )
        } else {
            XCTFail("Song initialization should succeed with a valid URL")
        }
    }

    func testInitializationWithInvalidURL() async {
        // Create an invalid local audio file URL (replace with an invalid path)
        let fileURL = URL(fileURLWithPath: "/path/to/invalid/audio.mp3")
        let asset = AVAsset(url: fileURL)
        let song = await Song(fromAsset: asset, withIdentifier: "testID")
        XCTAssertNil(song, "Song initialization should fail with an invalid URL")
    }
}
