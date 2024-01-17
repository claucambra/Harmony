//
//  AudioFileTest.swift
//  HarmonyTests
//
//  Created by Claudio Cambra on 17/1/24.
//

import XCTest
@testable import Harmony

class AudioFileTests: XCTestCase {
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

}
