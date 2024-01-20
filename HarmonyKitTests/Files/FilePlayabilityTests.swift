//
//  AudioFileTest.swift
//  HarmonyTests
//
//  Created by Claudio Cambra on 17/1/24.
//

import XCTest
@testable import HarmonyKit

class FilePlayabilityTests: XCTestCase {
    func testPlayableFileExtensionsNotEmpty() {
        let extensions = playableFileExtensions()
        XCTAssertFalse(extensions.isEmpty,
                       "The list of playable file extensions should not be empty.")
    }

    func testPlayableFileExtensionsContainCommonFormats() {
        let extensions = playableFileExtensions()
        let commonExtensions = ["mp3", "wav", "m4a", "aac", "flac"]
        for ext in commonExtensions {
            XCTAssertTrue(extensions.contains(ext),
                          "\(ext) should be a recognized playable file extension.")
        }
    }

    func testFileHasPlayableExtension() {
        let playableURL = URL(fileURLWithPath: "song.mp3")
        XCTAssertTrue(fileHasPlayableExtension(fileURL: playableURL),
                      "MP3 files should be recognized as having a playable extension.")
    }

    func testFileHasNonPlayableExtension() {
        let nonPlayableURL = URL(fileURLWithPath: "document.pdf")
        XCTAssertFalse(fileHasPlayableExtension(fileURL: nonPlayableURL),
                       "PDF files should not be recognized as having a playable extension.")
    }

    func testFileHasNoExtension() {
        let noExtensionURL = URL(fileURLWithPath: "file")
        XCTAssertFalse(fileHasPlayableExtension(fileURL: noExtensionURL),
                       "Files with no extension should not be recognized as having a playable extension.")
    }

    func testFilePlayabilityWithPlayableFile() {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent("tempSong.mp3")
        // Create a dummy MP3 file
        FileManager.default.createFile(atPath: tempFileURL.path, contents: Data(), attributes: nil)

        XCTAssertEqual(filePlayability(fileURL: tempFileURL),
                       .filePlayable,
                       "MP3 files should be classified as playable.")

        // Clean up
        try? FileManager.default.removeItem(at: tempFileURL)
    }

    func testFilePlayabilityWithNonPlayableFile() {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent("tempDocument.pdf")

        // Create a dummy PDF file
        FileManager.default.createFile(atPath: tempFileURL.path, contents: Data(), attributes: nil)

        XCTAssertEqual(filePlayability(fileURL: tempFileURL), 
                       .fileNotPlayable,
                       "PDF files should be classified as not playable.")

        // Clean up
        try? FileManager.default.removeItem(at: tempFileURL)
    }

    func testFilePlayabilityWithRemoteMaybePlayableFile() {
        let dummyUrl = URL(string: "https://claudiocambra.com/test/location/testSong.mp3")!
        XCTAssertEqual(filePlayability(fileURL: dummyUrl),
                       .fileMaybePlayable,
                       "Non-local MP3 files should be classified as maybe playable.")
    }
}
