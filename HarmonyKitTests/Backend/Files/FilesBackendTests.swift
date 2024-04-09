//
//  FilesBackendTests.swift
//  HarmonyTests
//
//  Created by Claudio Cambra on 17/1/24.
//

import XCTest
@testable import HarmonyKit

class FilesBackendTests: XCTestCase {
    var temporaryDirectory: URL!
    var testAudioData: Data!
    var songs: [Song] = []

    override func setUp() {
        super.setUp()
        temporaryDirectory = FileManager.default.temporaryDirectory
        let testBundle = Bundle(for: type(of: self))
        let testAudioURL = testBundle.url(
            forResource: "Free_Test_Data_1MB_MP3",
            withExtension: "mp3"
        )!
        testAudioData = try! Data(contentsOf: testAudioURL)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: temporaryDirectory)
        super.tearDown()
    }

    override func invokeTest() {
        songs = []
        super.invokeTest()
    }

    // Create a temporary directory structure with audio and non-audio files
    func createTemporaryDirectoryStructure() throws {
        let subdirectory1 = temporaryDirectory.appendingPathComponent("dir1")
        try FileManager.default.createDirectory(
            at: subdirectory1, withIntermediateDirectories: true, attributes: nil
        )

        let audioFile1 = subdirectory1.appendingPathComponent("song1.mp3")
        try testAudioData.write(to: audioFile1)

        let nonAudioFile1 = subdirectory1.appendingPathComponent("text1.txt")
        try testAudioData.write(to: nonAudioFile1)

        let subdirectory2 = temporaryDirectory.appendingPathComponent("dir2")
        try FileManager.default.createDirectory(
            at: subdirectory2, withIntermediateDirectories: true, attributes: nil
        )

        let audioFile2 = subdirectory2.appendingPathComponent("song2.mp3")
        try testAudioData.write(to: audioFile2)

        let nonAudioFile2 = subdirectory2.appendingPathComponent("text2.txt")
        try testAudioData.write(to: nonAudioFile2)
    }

    func testRecursiveScanWithAudioFiles() async {
        do {
            try createTemporaryDirectoryStructure()
            let backend = FilesBackend(path: temporaryDirectory, backendId: "test-backend")
            try await backend.scan(
                containerScanApprover: { _,_ in return true },
                songScanApprover: { _,_ in return true }, 
                finalisedSongHandler: { song in self.songs.append(song) },
                finalisedContainerHandler: { _,_ in }
            )
            XCTAssertEqual(songs.count, 2, "Expected 2 audio files in the directory structure")
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

            let backend = FilesBackend(path: temporaryDirectory, backendId: "test-backend")
            try await backend.scan(
                containerScanApprover: { _,_ in return true },
                songScanApprover: { _,_ in return true },
                finalisedSongHandler: { song in self.songs.append(song) },
                finalisedContainerHandler: { _,_ in }
            )
            XCTAssert(songs.isEmpty, "Expected no audio files in an empty directory")
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
            try testAudioData.write(to: audioFile3)

            let backend = FilesBackend(path: temporaryDirectory, backendId: "test-backend")
            try await backend.scan(
                containerScanApprover: { _,_ in return true },
                songScanApprover: { _,_ in return true },
                finalisedSongHandler: { song in self.songs.append(song) },
                finalisedContainerHandler: { _,_ in }
            )
            XCTAssertEqual(songs.count, 3, "Expected 3 audio files including nested directories")
        } catch {
            XCTFail("Error creating nested directory structure: \(error)")
        }
    }

    func testRecursiveScanWithBrokenSong() async {
        do {
            try createTemporaryDirectoryStructure()
            let brokenFile = temporaryDirectory.appendingPathComponent("brokenFile.mp3")
            try Data().write(to: brokenFile)

            let backend = FilesBackend(path: temporaryDirectory, backendId: "test-backend")
            try await backend.scan(
                containerScanApprover: { _,_ in return true },
                songScanApprover: { _,_ in return true },
                finalisedSongHandler: { song in self.songs.append(song) },
                finalisedContainerHandler: { _,_ in }
            )
            XCTAssertEqual(songs.count, 2, "Expected 2 audio files, third file is not valid")
        } catch {
            XCTFail("Error creating nested directory structure: \(error)")
        }
    }

    func testRecursiveScanTime() throws {
        try createTemporaryDirectoryStructure()
        let backend = FilesBackend(path: temporaryDirectory, backendId: "test-be")
        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                try await backend.scan(
                    containerScanApprover: { _,_ in return true },
                    songScanApprover: { _,_ in return true },
                    finalisedSongHandler: { _ in },
                    finalisedContainerHandler: { _,_ in }
                )
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
}
