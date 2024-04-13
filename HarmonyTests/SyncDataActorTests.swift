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
        let song1Id = "1"
        let song2Id = "2"
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
        XCTAssertTrue(result?.songs.contains(where: { $0.identifier == song1Id }) ?? false)
        XCTAssertTrue(result?.songs.contains(where: { $0.identifier == song2Id }) ?? false)
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

    func testIngestContainer_IngestSolitaryContainer() async throws {
        let identifier = "root"
        let container = Container(identifier: identifier, backendId: "1", versionId: "1")
        let mockModelContext = ModelContext(mockModelContainer)

        await syncDataActor.ingestContainer(container, parentContainer: nil)
        let activeContainer = try mockModelContext.fetch(
            FetchDescriptor<Container>(predicate: #Predicate { $0.identifier == identifier })
        ).first
        XCTAssertNotNil(activeContainer)
        XCTAssertEqual(activeContainer?.identifier, identifier)
        XCTAssertEqual(activeContainer?.backendId, container.backendId)
        XCTAssertEqual(activeContainer?.versionId, container.versionId)
        XCTAssertNil(activeContainer?.parentContainer)
        XCTAssertTrue(activeContainer?.childContainers.isEmpty ?? false)
    }

    func testIngestContainer_ShouldCorrectlyLinkToParentContainer() async throws {
        let parentIdentifier = "parent1"
        let childIdentifier = "child1"
        let parent = Container(identifier: parentIdentifier, backendId: "1", versionId: "1")
        let child = Container(identifier: childIdentifier, backendId: "1", versionId: "1")
        let mockModelContext = ModelContext(mockModelContainer)

        // Should insert parent first and then link the child
        await syncDataActor.ingestContainer(child, parentContainer: parent)
        let activeParent = try mockModelContext.fetch(
            FetchDescriptor<Container>(predicate: #Predicate { $0.identifier == parentIdentifier })
        ).first
        XCTAssertNotNil(activeParent)

        let activeChild = try mockModelContext.fetch(
            FetchDescriptor<Container>(predicate: #Predicate { $0.identifier == childIdentifier })
        ).first
        XCTAssertNotNil(activeChild)

        XCTAssertEqual(activeChild?.parentContainer, activeParent)
        XCTAssertEqual(activeParent?.childContainers.contains(activeChild!), true)

        // Now insert another child
        let child2Identifier = "child2"
        let child2 = Container(identifier: child2Identifier, backendId: "1", versionId: "1")
        await syncDataActor.ingestContainer(child2, parentContainer: activeParent)
        let activeChild2 = try mockModelContext.fetch(
            FetchDescriptor<Container>(predicate: #Predicate { $0.identifier == child2Identifier })
        ).first
        XCTAssertNotNil(activeChild2)

        XCTAssertEqual(activeChild2?.parentContainer, activeParent)
        XCTAssertEqual(activeParent?.childContainers.contains(activeChild2!), true)
        XCTAssertEqual(activeParent?.childContainers.count, 2)
    }

    func testClearSongs_BasicDelete() async throws {
        let songId = "1"
        let backendId = "backend1"
        let song = Song(identifier: songId, parentContainerId: "container1", backendId: backendId)
        let activeSong = await syncDataActor.ingestSong(song)
        XCTAssertNotNil(activeSong)
        XCTAssertFalse(activeSong!.isDeleted)

        let mockModelContext = ModelContext(mockModelContainer)
        let fetchDescriptor = FetchDescriptor<Song>(predicate: #Predicate {
            $0.identifier == songId && $0.backendId == backendId
        })

        let retrievedSong = try mockModelContext.fetch(fetchDescriptor).first
        XCTAssertNotNil(retrievedSong)

        await syncDataActor.clearSongs(
            backendId: activeSong!.backendId, withExceptions: [], avoidingContainers: []
        )

        let postDeleteSong = try mockModelContext.fetch(fetchDescriptor).first
        XCTAssertNil(postDeleteSong)
    }

    func testClearSongs_DeletesOnlyBackendSongs() async throws {
        let song1Identifier = "1"
        let song2Identifier = "2"
        let song1BackendId = "backend1"
        let song2BackendId = "backend2"
        let song1 = Song(
            identifier: song1Identifier, parentContainerId: "container1", backendId: song1BackendId
        )
        let song2 = Song(
            identifier: song2Identifier, parentContainerId: "container1", backendId: song2BackendId
        )
        let activeSong1 = await syncDataActor.ingestSong(song1)
        let activeSong2 = await syncDataActor.ingestSong(song2)
        XCTAssertNotNil(activeSong1)
        XCTAssertNotNil(activeSong2)

        await syncDataActor.clearSongs(
            backendId: song1BackendId, withExceptions: [], avoidingContainers: []
        )

        let s1FetchDescriptor = FetchDescriptor<Song>(predicate: #Predicate {
            $0.identifier == song1Identifier
        })
        let s2FetchDescriptor = FetchDescriptor<Song>(predicate: #Predicate {
            $0.identifier == song2Identifier
        })
        let mockModelContext = ModelContext(mockModelContainer)
        let retrievedS1 = try mockModelContext.fetch(s1FetchDescriptor).first
        let retrievedS2 = try mockModelContext.fetch(s2FetchDescriptor).first
        XCTAssertNil(retrievedS1)
        XCTAssertNotNil(retrievedS2)
    }

    func testClearSongs_RespectsExceptions() async throws {
        let songId = "1"
        let backendId = "backend1"
        let song = Song(identifier: songId, parentContainerId: "container1", backendId: backendId)
        let activeSong = await syncDataActor.ingestSong(song)
        XCTAssertNotNil(activeSong)

        await syncDataActor.clearSongs(
            backendId: activeSong!.backendId, withExceptions: [songId], avoidingContainers: []
        )

        let mockModelContext = ModelContext(mockModelContainer)
        let fetchDescriptor = FetchDescriptor<Song>(predicate: #Predicate {
            $0.identifier == songId && $0.backendId == backendId
        })
        let postDeleteSong = try mockModelContext.fetch(fetchDescriptor).first
        XCTAssertNotNil(postDeleteSong)
    }

    func testClearSongs_RespectsAvoidedContainers() async throws {
        let backendId = "backend1"
        let song1Id = "1"
        let song2Id = "2"
        let song3Id = "3"
        let song4Id = "4"
        let song5Id = "5"
        let rootId = "root"
        let rootChild1Id = "rootChild1"
        let rootChild2Id = "rootChild2"
        let rootChild1ChildId = "rootChild1Child"
        let rootChild2ChildId = "rootChild2Child"
        let song1 = Song(identifier: song1Id, parentContainerId: rootId, backendId: backendId)
        let song2 = Song(identifier: song2Id, parentContainerId: rootChild1Id, backendId: backendId)
        let song3 = Song(identifier: song3Id, parentContainerId: rootChild2Id, backendId: backendId)
        let song4 = Song(
            identifier: song4Id, parentContainerId: rootChild1ChildId, backendId: backendId
        )
        let song5 = Song(
            identifier: song5Id, parentContainerId: rootChild2ChildId, backendId: backendId
        )

        let activeSong1 = await syncDataActor.ingestSong(song1)
        let activeSong2 = await syncDataActor.ingestSong(song2)
        let activeSong3 = await syncDataActor.ingestSong(song3)
        let activeSong4 = await syncDataActor.ingestSong(song4)
        let activeSong5 = await syncDataActor.ingestSong(song5)
        XCTAssertNotNil(activeSong1)
        XCTAssertNotNil(activeSong2)
        XCTAssertNotNil(activeSong3)
        XCTAssertNotNil(activeSong4)
        XCTAssertNotNil(activeSong5)

        let root = Container(identifier: rootId, backendId: backendId, versionId: "1")
        let rootChild1 = Container(identifier: rootChild1Id, backendId: backendId, versionId: "1")
        let rootChild2 = Container(identifier: rootChild2Id, backendId: backendId, versionId: "1")
        let rootChild1Child = Container(
            identifier: rootChild1ChildId, backendId: backendId, versionId: "1"
        )
        let rootChild2Child = Container(
            identifier: rootChild2ChildId, backendId: backendId, versionId: "1"
        )

        await syncDataActor.ingestContainer(root, parentContainer: nil)
        await syncDataActor.ingestContainer(rootChild1, parentContainer: root)
        await syncDataActor.ingestContainer(rootChild2, parentContainer: root)
        await syncDataActor.ingestContainer(rootChild1Child, parentContainer: rootChild1)
        await syncDataActor.ingestContainer(rootChild2Child, parentContainer: rootChild2)

        await syncDataActor.clearSongs(
            backendId: backendId, withExceptions: [], avoidingContainers: [rootId, rootChild2Id]
        )

        let mockModelContext = ModelContext(mockModelContainer)
        let fetchDescriptor = FetchDescriptor<Song>(predicate: #Predicate {
            $0.backendId == backendId
        })
        let postDeleteSongs = try mockModelContext.fetch(fetchDescriptor)

        XCTAssertEqual(postDeleteSongs.count, 3)
        XCTAssertTrue(postDeleteSongs.contains(where: { $0.identifier == song1Id }))
        XCTAssertFalse(postDeleteSongs.contains(where: { $0.identifier == song2Id }))
        XCTAssertTrue(postDeleteSongs.contains(where: { $0.identifier == song3Id }))
        XCTAssertFalse(postDeleteSongs.contains(where: { $0.identifier == song4Id }))
        XCTAssertTrue(postDeleteSongs.contains(where: { $0.identifier == song5Id }))
    }

    func testClearStaleGroupings_ShouldRemoveEmptyGroupings() async throws {
        let staleAlbumTitle = "Empty Album"
        let staleArtistName = "Lonely Artist"
        let nonStaleAlbumTitle = "Active Album"
        let nonStaleArtistTitle = "Active Artist"

        let staleAlbum = Album(songs: [], title: staleAlbumTitle)
        let staleArtist = Artist(songs: [], albums: [], name: staleArtistName)
        let song = Song(
            identifier: "1", 
            parentContainerId: "container1",
            backendId: "backend1",
            artist: nonStaleArtistTitle,
            album: nonStaleAlbumTitle
        )
        let mockModelContext = ModelContext(mockModelContainer)
        mockModelContext.insert(staleAlbum)
        mockModelContext.insert(staleArtist)
        try mockModelContext.save()

        let activeSong = await syncDataActor.ingestSong(song)
        XCTAssertNotNil(activeSong)
        let activeAlbum = await syncDataActor.processSongAlbum(activeSong!)
        XCTAssertNotNil(activeAlbum)
        let activeArtists = await syncDataActor.processSongArtist(
            activeSong!, inAlbum: activeAlbum!
        )
        XCTAssertNotNil(activeArtists)

        let staleAlbumFetchDescriptor = FetchDescriptor<Album>(predicate: #Predicate {
            $0.title == staleAlbumTitle
        })
        let staleArtistFetchDescriptor = FetchDescriptor<Artist>(predicate: #Predicate {
            $0.name == staleArtistName
        })
        let activeAlbumFetchDescriptor = FetchDescriptor<Album>(predicate: #Predicate {
            $0.title == nonStaleAlbumTitle
        })
        let activeArtistFetchDescriptor = FetchDescriptor<Artist>(predicate: #Predicate {
            $0.name == nonStaleArtistTitle
        })
        let retrievedStaleAlbum = try mockModelContext.fetch(staleAlbumFetchDescriptor).first
        let retrievedStaleArtist = try mockModelContext.fetch(staleArtistFetchDescriptor).first
        let retrievedActiveAlbum = try mockModelContext.fetch(activeAlbumFetchDescriptor).first
        let retrievedActiveArtist = try mockModelContext.fetch(activeArtistFetchDescriptor).first
        XCTAssertNotNil(retrievedStaleAlbum)
        XCTAssertNotNil(retrievedStaleArtist)
        XCTAssertNotNil(retrievedActiveAlbum)
        XCTAssertNotNil(retrievedActiveArtist)

        await syncDataActor.clearStaleGroupings()

        let postDeleteStaleAlbum = try mockModelContext.fetch(staleAlbumFetchDescriptor).first
        let postDeleteStaleArtist = try mockModelContext.fetch(staleArtistFetchDescriptor).first
        let postDeleteActiveAlbum = try mockModelContext.fetch(activeAlbumFetchDescriptor).first
        let postDeleteActiveArtist = try mockModelContext.fetch(activeArtistFetchDescriptor).first
        XCTAssertNil(postDeleteStaleAlbum)
        XCTAssertNil(postDeleteStaleArtist)
        XCTAssertNotNil(postDeleteActiveAlbum)
        XCTAssertNotNil(postDeleteActiveArtist)
    }

    func testClearSongContainers_DeletesOnlyBackendContainers() async throws {
        let container1Identifier = "1"
        let container2Identifier = "2"
        let container1BackendId = "backend1"
        let container2BackendId = "backend2"
        let container1 = Container(
            identifier: container1Identifier, backendId: container1BackendId, versionId: "v1"
        )
        let container2 = Container(
            identifier: container2Identifier, backendId: container2BackendId, versionId: "v1"
        )

        await syncDataActor.ingestContainer(container1, parentContainer: nil)
        await syncDataActor.ingestContainer(container2, parentContainer: nil)

        await syncDataActor.clearSongContainers(
            backendId: container1BackendId, withExceptions: [], withProtectedParents: []
        )

        let c1FetchDescriptor = FetchDescriptor<Container>(predicate: #Predicate {
            $0.identifier == container1Identifier
        })
        let c2FetchDescriptor = FetchDescriptor<Container>(predicate: #Predicate {
            $0.identifier == container2Identifier
        })
        let mockModelContext = ModelContext(mockModelContainer)
        let retrievedC1 = try mockModelContext.fetch(c1FetchDescriptor).first
        let retrievedC2 = try mockModelContext.fetch(c2FetchDescriptor).first
        XCTAssertNil(retrievedC1)
        XCTAssertNotNil(retrievedC2)
    }

    func testClearSongContainers_RespectsExceptions() async throws {
        let containerId = "1"
        let backendId = "backend1"
        let container = Container(identifier: containerId, backendId: backendId, versionId: "v1")
        await syncDataActor.ingestContainer(container, parentContainer: nil)

        await syncDataActor.clearSongContainers(
            backendId: backendId,
            withExceptions: [containerId],
            withProtectedParents: []
        )

        let mockModelContext = ModelContext(mockModelContainer)
        let fetchDescriptor = FetchDescriptor<Container>(predicate: #Predicate {
            $0.identifier == containerId && $0.backendId == backendId
        })
        let postDeleteContainer = try mockModelContext.fetch(fetchDescriptor).first
        XCTAssertNotNil(postDeleteContainer)
    }

    func testClearSongContainers_RespectsProtectedParents() async throws {
        let backendId = "backend1"
        let rootId = "root"
        let rootChild1Id = "rootChild1"
        let rootChild2Id = "rootChild2"
        let rootChild1ChildId = "rootChild1Child"
        let rootChild2ChildId = "rootChild2Child"

        let root = Container(identifier: rootId, backendId: backendId, versionId: "1")
        let rootChild1 = Container(identifier: rootChild1Id, backendId: backendId, versionId: "1")
        let rootChild2 = Container(identifier: rootChild2Id, backendId: backendId, versionId: "1")
        let rootChild1Child = Container(
            identifier: rootChild1ChildId, backendId: backendId, versionId: "1"
        )
        let rootChild2Child = Container(
            identifier: rootChild2ChildId, backendId: backendId, versionId: "1"
        )

        await syncDataActor.ingestContainer(root, parentContainer: nil)
        await syncDataActor.ingestContainer(rootChild1, parentContainer: root)
        await syncDataActor.ingestContainer(rootChild2, parentContainer: root)
        await syncDataActor.ingestContainer(rootChild1Child, parentContainer: rootChild1)
        await syncDataActor.ingestContainer(rootChild2Child, parentContainer: rootChild2)

        await syncDataActor.clearSongContainers(
            backendId: backendId, withExceptions: [], withProtectedParents: [rootId, rootChild2Id]
        )

        let mockModelContext = ModelContext(mockModelContainer)
        let fetchDescriptor = FetchDescriptor<Container>(predicate: #Predicate {
            $0.backendId == backendId
        })
        let postDeleteContainers = try mockModelContext.fetch(fetchDescriptor)

        XCTAssertEqual(postDeleteContainers.count, 3)
        XCTAssertTrue(postDeleteContainers.contains(where: { $0.identifier == rootId }))
        XCTAssertFalse(postDeleteContainers.contains(where: { $0.identifier == rootChild1Id }))
        XCTAssertTrue(postDeleteContainers.contains(where: { $0.identifier == rootChild2Id }))
        XCTAssertFalse(postDeleteContainers.contains(where: { $0.identifier == rootChild1ChildId }))
        XCTAssertTrue(postDeleteContainers.contains(where: { $0.identifier == rootChild2ChildId }))
    }
}
