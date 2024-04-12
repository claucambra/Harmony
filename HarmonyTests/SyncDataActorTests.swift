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

    func testApprovalForSongContainerScan_WhenContainerDoesNotExist() async throws {
        let result = await syncDataActor.approvalForSongContainerScan(id: "1", versionId: "new")
        XCTAssertTrue(result)
    }

    func testApprovalForSongContainerScan_WhenContainerExistsWithDifferentVersion() async throws {
        let container = Container(identifier: "1", backendId: "backendId", versionId: "old")
        let mockModelContext = ModelContext(mockModelContainer)
        mockModelContext.insert(container)
        try mockModelContext.save()

        let result = await syncDataActor.approvalForSongContainerScan(
            id: container.identifier, versionId: "new"
        )
        XCTAssertTrue(result)
    }

    func testApprovalForSongContainerScan_WhenContainerExistsWithSameVersion() async throws {
        let container = Container(identifier: "1", backendId: "backendId", versionId: "old")
        let mockModelContext = ModelContext(mockModelContainer)
        mockModelContext.insert(container)
        try mockModelContext.save()

        let result = await syncDataActor.approvalForSongContainerScan(
            id: container.identifier, versionId: container.versionId
        )
        XCTAssertFalse(result)
    }


    func testIngestSong_WhenSongDoesNotExist_ShouldCreateSong() async {
        let song = Song(identifier: "1", versionId: "new")
        let result = await syncDataActor.ingestSong(song)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.identifier, song.identifier)
    }

    func testIngestSong_WhenSongExistsAndIsOutdated_ShouldUpdateDownloadState() async throws {
        let song = Song(identifier: "1", downloadState: .downloaded, versionId: "old")
        let newSong = Song(identifier: "1", versionId: "new")
        
        let mockModelContext = ModelContext(mockModelContainer)
        mockModelContext.insert(song)
        try mockModelContext.save()

        let newResult = await syncDataActor.ingestSong(newSong)
        XCTAssertNotNil(newResult)
        XCTAssertEqual(newResult?.downloadState, DownloadState.downloadedOutdated.rawValue)
    }

    func testProcessSongAlbum_ShouldCreateNewAlbum() async {
        let song = Song(identifier: "1", album: "Album 1")
        let ingestedSong = await syncDataActor.ingestSong(song)
        XCTAssertNotNil(ingestedSong)

        let result = await syncDataActor.processSongAlbum(song)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, song.album)
        XCTAssertEqual(result?.songs.first, song)
    }

    func testProcessSongAlbum_ShouldAddSongToExistingAlbum() async {
        let song1 = Song(identifier: "1", album: "Album 1")
        let song2 = Song(identifier: "2", album: "Album 1")
        let activeSong1 = await syncDataActor.ingestSong(song1)
        let activeSong2 = await syncDataActor.ingestSong(song2)
        XCTAssertNotNil(activeSong1)
        XCTAssertNotNil(activeSong2)

        let originalResult = await syncDataActor.processSongAlbum(song1)
        let result = await syncDataActor.processSongAlbum(song2)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, song1.album, "Album titles should match!")
        XCTAssertEqual(result?.title, song2.album, "Album titles should match!")
        XCTAssertEqual(result?.title, originalResult?.title, "Album titles should match!")
        XCTAssertEqual(result?.songs, originalResult?.songs, "Songs should match!")
        XCTAssertEqual(result?.songs, [activeSong1!, activeSong2!], "Songs should match!")
    }

    func testProcessSongArtist_WhenArtistDoesNotExist_ShouldCreateArtist() async {
        let song = Song(identifier: "1", artist: "Artist 1", album: "Album 1")
        let activeSong = await syncDataActor.ingestSong(song)
        XCTAssertNotNil(activeSong)

        let album = await syncDataActor.processSongAlbum(activeSong!)
        XCTAssertNotNil(album)

        let artists = await syncDataActor.processSongArtist(song, inAlbum: album!)
        XCTAssertNotNil(artists)
        XCTAssertEqual(artists?.count, 1)
        for artist in artists! {
            XCTAssertEqual(artist.name, song.artist)
            XCTAssertEqual(artist.songs.count, 1)
            XCTAssertEqual(artist.albums.count, 1)
            XCTAssertTrue(artist.songs.contains(activeSong!))
            XCTAssertTrue(artist.albums.contains(album!))
        }
    }

    func testProcessSongArtist_WhenArtistsDoNotExist_ShouldCreateMultipleArtists() async {
        let song = Song(identifier: "1", artist: "Artist 1; Artist 2; Artist 3", album: "Album 1")
        let songA1 = Song(identifier: "2", artist: "Artist 1", album: "Album 1")
        let songA2 = Song(identifier: "3", artist: "Artist 2", album: "Album 2")
        let activeSong = await syncDataActor.ingestSong(song)
        let activeSongA1 = await syncDataActor.ingestSong(songA1)
        let activeSongA2 = await syncDataActor.ingestSong(songA2)
        XCTAssertNotNil(activeSong)
        XCTAssertNotNil(activeSongA1)
        XCTAssertNotNil(activeSongA2)

        let album1 = await syncDataActor.processSongAlbum(activeSong!)
        _ = await syncDataActor.processSongAlbum(activeSongA1!)
        let album2 = await syncDataActor.processSongAlbum(activeSongA2!)
        XCTAssertNotNil(album1)
        XCTAssertNotNil(album2)
        XCTAssertEqual(album1?.songs.count, 2)
        XCTAssertEqual(album2?.songs.count, 1)

        let artists = await syncDataActor.processSongArtist(activeSong!, inAlbum: album1!)
        let artistsA1 = await syncDataActor.processSongArtist(activeSongA1!, inAlbum: album1!)
        let artistsA2 = await syncDataActor.processSongArtist(activeSongA2!, inAlbum: album2!)
        let artistsA3 = artists?.filter { $0.name == "Artist 3" }
        XCTAssertNotNil(artists)
        XCTAssertNotNil(artistsA1)
        XCTAssertNotNil(artistsA2)
        XCTAssertNotNil(artistsA3)
        XCTAssertEqual(artists?.count, 3)
        XCTAssertEqual(artistsA1?.count, 1)
        XCTAssertEqual(artistsA2?.count, 1)
        XCTAssertEqual(artistsA3?.count, 1)

        XCTAssertEqual(artistsA1?.first?.songs.count, 2)
        XCTAssertEqual(artistsA2?.first?.songs.count, 2)
        XCTAssertEqual(artistsA3?.first?.songs.count, 1)

        XCTAssertEqual(artistsA1?.first?.albums.count, 1)
        XCTAssertEqual(artistsA2?.first?.albums.count, 2)
        XCTAssertEqual(artistsA3?.first?.albums.count, 1)

        XCTAssertEqual(artistsA1?.first?.songs.contains(activeSong!), true)
        XCTAssertEqual(artistsA1?.first?.songs.contains(activeSongA1!), true)
        XCTAssertEqual(artistsA2?.first?.songs.contains(activeSong!), true)
        XCTAssertEqual(artistsA2?.first?.songs.contains(activeSongA2!), true)
        XCTAssertEqual(artistsA3?.first?.songs.contains(activeSong!), true)

        XCTAssertEqual(artistsA1?.first?.albums.contains(album1!), true)
        XCTAssertEqual(artistsA2?.first?.albums.contains(album1!), true)
        XCTAssertEqual(artistsA2?.first?.albums.contains(album2!), true)
        XCTAssertEqual(artistsA3?.first?.albums.contains(album1!), true)
    }
}
