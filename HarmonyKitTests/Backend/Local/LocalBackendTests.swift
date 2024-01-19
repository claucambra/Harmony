//
//  LocalBackendTests.swift
//  HarmonyTests
//
//  Created by Claudio Cambra on 17/1/24.
//

import XCTest
@testable import HarmonyKit

class LocalBackendTests: XCTestCase {
    var temporaryDirectory: URL!

    override func setUp() {
        super.setUp()
        temporaryDirectory = FileManager.default.temporaryDirectory
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: temporaryDirectory)
        super.tearDown()
    }

    // Create a temporary directory structure with audio and non-audio files
    func createTemporaryDirectoryStructure() throws {
        let subdirectory1 = temporaryDirectory.appendingPathComponent("dir1")
        try FileManager.default.createDirectory(
            at: subdirectory1, withIntermediateDirectories: true, attributes: nil
        )

        let audioFile1 = subdirectory1.appendingPathComponent("song1.mp3")
        try Data().write(to: audioFile1)

        let nonAudioFile1 = subdirectory1.appendingPathComponent("text1.txt")
        try Data().write(to: nonAudioFile1)

        let subdirectory2 = temporaryDirectory.appendingPathComponent("dir2")
        try FileManager.default.createDirectory(
            at: subdirectory2, withIntermediateDirectories: true, attributes: nil
        )

        let audioFile2 = subdirectory2.appendingPathComponent("song2.mp3")
        try Data().write(to: audioFile2)

        let nonAudioFile2 = subdirectory2.appendingPathComponent("text2.txt")
        try Data().write(to: nonAudioFile2)
    }

    func testRecursiveScanWithAudioFiles() async {
        do {
            try createTemporaryDirectoryStructure()
            let backend = LocalBackend(path: temporaryDirectory)
            let audioFiles = await backend.scan()
            XCTAssertEqual(audioFiles.count, 2, "Expected 2 audio files in the directory structure")
        } catch {
            XCTFail("Error creating temporary directory structure: \(error)")
        }
    }

    func testRecursiveScanWithoutAudioFiles() async {
        do {
            let emptyDirectory = temporaryDirectory.appendingPathComponent("emptyDir")
            try FileManager.default.createDirectory(
                at: emptyDirectory, withIntermediateDirectories: true, attributes: nil
            )

            let backend = LocalBackend(path: temporaryDirectory)
            let audioFiles = await backend.scan()
            XCTAssertEqual(audioFiles.count, 0, "Expected no audio files in an empty directory")
        } catch {
            XCTFail("Error creating empty directory: \(error)")
        }
    }

    func testRecursiveScanWithNestedDirectories() async {
        do {
            try createTemporaryDirectoryStructure()
            let nestedDirectory = temporaryDirectory.appendingPathComponent("nestedDir")
            try FileManager.default.createDirectory(
                at: nestedDirectory, withIntermediateDirectories: true, attributes: nil
            )

            let audioFile3 = nestedDirectory.appendingPathComponent("song3.mp3")
            try Data().write(to: audioFile3)

            let backend = LocalBackend(path: temporaryDirectory)
            let audioFiles = await backend.scan()
            XCTAssertEqual(
                audioFiles.count, 3, "Expected 3 audio files including nested directories"
            )
        } catch {
            XCTFail("Error creating nested directory structure: \(error)")
        }
    }

    func testRecursiveScanTime() throws {
        try createTemporaryDirectoryStructure()
        let backend = LocalBackend(path: temporaryDirectory)
        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                let _ = await backend.scan()
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    func testMD5ChecksumCalc() {
        let testBundle = Bundle(for: type(of: self))
        let testAudioURL = testBundle.url(
            forResource: "Free_Test_Data_1MB_MP3",
            withExtension: "mp3"
        )!
        let checksum = LocalBackend.calculateMD5Checksum(forFileAtURL: testAudioURL)
        XCTAssertNotNil(checksum, "Checksum should not be nil!")
    }
}
