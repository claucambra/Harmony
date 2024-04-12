//
//  SyncDataActorTests.swift
//  HarmonyTests
//
//  Created by Claudio Cambra on 12/4/24.
//

import AVFoundation
import SwiftData
import XCTest

@testable import Harmony
@testable import HarmonyKit

final class SyncDataActorTests: XCTestCase {

    var syncDataActor: SyncDataActor!
    var mockModelContainer: ModelContainer!

    override func setUpWithError() throws {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        mockModelContainer = try ModelContainer(
            for: Song.self, Album.self, Artist.self, Container.self,
            configurations: config
        )
        syncDataActor = SyncDataActor(modelContainer: mockModelContainer)
    }

    override func tearDownWithError() throws {
        syncDataActor = nil
        mockModelContainer = nil
        super.tearDown()
    }

    func testCleanup_ShouldChangeDownloadStateOfDownloadingSongs() async throws {
        let song1 = Song(identifier: "1", downloadState: .downloading)
        XCTAssertNotNil(song1)
        let mockModelContext = ModelContext(mockModelContainer)
        mockModelContext.insert(song1)
        try mockModelContext.save()

        await syncDataActor.cleanup()
        XCTAssertEqual(song1.downloadState, DownloadState.notDownloaded.rawValue)
    }

    func testApprovalForSongScan_WhenSongDoesNotExist() async {
        let result = await syncDataActor.approvalForSongScan(id: "1", versionId: "new")
        XCTAssertTrue(result)
    }

    func testApprovalForSongScan_WhenSongExistsWithDifferentVersion() async throws {
        let song = Song(identifier: "1", versionId: "old")
        let mockModelContext = ModelContext(mockModelContainer)
        mockModelContext.insert(song)
        try mockModelContext.save()

        let result = await syncDataActor.approvalForSongScan(id: "1", versionId: "new")
        XCTAssertTrue(result)
    }

    func testApprovalForSongScan_WhenSongExistsWithSameVersion() async throws {
        let song = Song(identifier: "1", versionId: "same")
        let mockModelContext = ModelContext(mockModelContainer)
        mockModelContext.insert(song)
        try mockModelContext.save()

        let result = await syncDataActor.approvalForSongScan(
            id: song.identifier, versionId: song.versionId
        )
        XCTAssertFalse(result)
    }
}
