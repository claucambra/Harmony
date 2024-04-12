//
//  SyncDataActor.swift
//  Harmony
//
//  Created by Claudio Cambra on 15/3/24.
//

import Foundation
import HarmonyKit
import OSLog
import SwiftData

@ModelActor
actor SyncDataActor {
    static let shared = SyncDataActor(
        modelContainer: try! ModelContainer(for: Song.self, Album.self, Artist.self, Container.self)
    )

    func cleanup() {
        let dlState = DownloadState.downloading.rawValue
        let fetchDsc = FetchDescriptor<Song>( predicate: #Predicate { $0.downloadState == dlState })
        do {
            let downloadingSongs = try modelContext.fetch(fetchDsc)
            for song in downloadingSongs {
                song.downloadState = DownloadState.notDownloaded.rawValue
            }
            try modelContext.save()
        } catch let error {
            Logger.sync.error("Could not run init cleanup: \(error)")
            return
        }
    }

    // TODO: Deduplicate approval methods with use of generics/protocol
    func approvalForSongScan(id: String, versionId: String) -> Bool {
        do {
            let fetchDescriptor = FetchDescriptor<Song>(predicate: #Predicate<Song> {
                $0.identifier == id
            })
            guard let existingSong = try modelContext.fetch(fetchDescriptor).first else {
                return true
            }
            return existingSong.versionId != versionId
        } catch let error {
            Logger.sync.error("Could not get accurate approval for container, approving")
            return true
        }
    }

    func approvalForSongContainerScan(id: String, versionId: String) -> Bool {
        do {
            let fetchDescriptor = FetchDescriptor<Container>(predicate: #Predicate<Container> {
                $0.identifier == id
            })
            guard let existingSongContainer = try modelContext.fetch(fetchDescriptor).first else {
                return true
            }
            return existingSongContainer.versionId != versionId
        } catch let error {
            Logger.sync.error("Could not get accurate approval for container, approving")
            return true
        }
    }

    func ingestSong(_ song: Song) -> Song? {
        do {
            let songIdentifier = song.identifier
            Logger.sync.info("Ingesting song: \(song.title) \(song.identifier)")
            let fetchDescriptor = FetchDescriptor<Song>(
                predicate: #Predicate<Song> { $0.identifier == songIdentifier }
            )

            if let existingSong = try modelContext.fetch(fetchDescriptor).first {
                let isOutdated = song.versionId != existingSong.versionId
                let existingDlState = existingSong.downloadState
                var refreshedDlState = DownloadState.notDownloaded
                if existingDlState == DownloadState.downloaded.rawValue {
                    refreshedDlState = isOutdated ? .downloadedOutdated : .downloaded
                } else if existingDlState == DownloadState.downloading.rawValue {
                    refreshedDlState = .downloading
                }
                song.downloadState = refreshedDlState.rawValue
            }
            modelContext.insert(song)
            try modelContext.save()
            return try modelContext.fetch(
                FetchDescriptor<Song>(predicate: #Predicate { $0.identifier == songIdentifier })
            ).first
        } catch let error {
            Logger.sync.error("Could not save song to data: \(error)")
        }
        return nil
    }

    func processSongAlbum(_ song: Song) -> Album? {
        let songIdentifier = song.identifier
        do {
            let albumTitle = song.album
            let albumFetchDescriptor = FetchDescriptor<Album>(
                predicate: #Predicate { $0.title == albumTitle }
            )
            var album: Album?
            if let existingAlbum = try modelContext.fetch(albumFetchDescriptor).first {
                if !existingAlbum.songs.contains(where: { $0.identifier == songIdentifier }) {
                    existingAlbum.songs.append(song)
                }
                album = existingAlbum
            } else if let newAlbum = Album(songs: [song]) {
                modelContext.insert(newAlbum)
                album = newAlbum
            }
            try modelContext.save()
            return album
        } catch let error {
            Logger.sync.error("Could not process album: \(error)")
            return nil
        }
    }

    @discardableResult func processSongArtist(_ song: Song, inAlbum album: Album?) -> Set<Artist>? {
        let songIdentifier = song.identifier
        do {
            var artists = Set<Artist>()
            let artistNames = song.artist.components(separatedBy: "; ")
            for artistName in artistNames {
                let artistFetchDescriptor = FetchDescriptor<Artist>(
                    predicate: #Predicate { $0.name == artistName }
                )
                if let artist = try modelContext.fetch(artistFetchDescriptor).first {
                    if !artist.songs.contains(where: { $0.identifier == songIdentifier }) {
                        artist.songs.append(song)
                    }
                    if let album = album,
                        !artist.albums.contains(where: { $0.title == album.title })
                    {
                        artist.albums.append(album)
                    }
                    artists.insert(artist)
                } else if let artist = Artist(name: artistName, songs: [song]) {
                    modelContext.insert(artist)
                    artists.insert(artist)
                }
                try modelContext.save()
            }
            return artists.isEmpty ? nil : artists
        } catch let error {
            Logger.sync.error("Could not process artist for song \(songIdentifier): \(error)")
            return nil
        }
    }

    func ingestContainer(_ songContainer: Container, parentContainer: Container?) {
        do {
            modelContext.insert(songContainer)
            if let parentContainer = parentContainer {
                let parentId = parentContainer.identifier
                let childId = songContainer.identifier
                let fetchDescriptor = FetchDescriptor<Container>(
                    predicate: #Predicate { $0.identifier == parentId }
                )
                var parentContainerToUse: Container
                if let result = try? modelContext.fetch(fetchDescriptor).first {
                    parentContainerToUse = result
                } else {
                    modelContext.insert(parentContainer)
                    parentContainerToUse = parentContainer
                }
                if !parentContainerToUse.childContainers.contains(
                    where: { $0.identifier == childId }
                ) {
                    parentContainerToUse.childContainers.append(songContainer)
                }
            }
            try modelContext.save()
        } catch let error {
            Logger.sync.error("Could not save container to data: \(error)")
        }
    }

    // Remove songs. Importantly, used at the end of a scan to eliminate songs that are no longer
    // present.
    //
    // Exceptions should contain song ids.
    //
    // Regarding containers. In this example tree...
    //
    // root --> rootChild1 -> rootChild1Child
    //      \-> rootChild2 -> rootChild2Child
    //
    // ...the song in root and the child songs in rootChild2 should be kept.
    // Why? Because we scan from the root of the tree down.
    // Missing containers can mean:
    //
    // 1. The container was deleted
    // 2. The container is a child of one of the containers we're avoiding
    //
    // In the context of syncing, we ONLY want to delete songs for case 1.
    // To figure out if a missing container is the result of case 1 or case 2, we need to:
    //
    // 1.   Traverse the tree from the root
    // 2.   Check if any of the children of the root are present in the list of containers we're
    //      avoiding
    //
    // 3a.  If any are, we should clear any children that are not present (as this means a scan of
    //      the root container has been approved and these children are missing, therefore deleted)
    // 3ai. Repeat 1->3a for present children
    //
    // 3b.  If none are, we should recursively protect all children of the root container (as this
    //      means that a scan of the root container has not been approved, so we assume the state of
    //      the children has not changed)

    func clearSongs(
        backendId: String,
        withExceptions exceptions: Set<String>,
        avoidingContainers songContainers: Set<String>
    ) {
        let fetchDescriptor = FetchDescriptor<Song>(
            predicate: #Predicate { $0.backendId == backendId }
        )

        do {
            let backendSongs = try modelContext.fetch(fetchDescriptor)
            var protectedContainerHierarchy = songContainers

            if !songContainers.isEmpty {
                // Deal with the container hierarchy here
                guard let root = try modelContext.fetch(
                    FetchDescriptor<Container>(
                        predicate: #Predicate {
                            $0.backendId == backendId && $0.parentContainer == nil
                        }
                    )
                ).first else {
                    Logger.sync.error("Could not find root container for \(backendId)")
                    return
                }
                var containersToProcess = [root]

                while !containersToProcess.isEmpty {
                    var nextContainers = [Container]()
                    for container in containersToProcess {
                        let presentChildren = container.childContainers.filter {
                            songContainers.contains($0.identifier)
                        }
                        guard !presentChildren.isEmpty else {
                            let allChildren = try containersWithChildren(
                                parents: [container.identifier], backendId: backendId
                            )
                            protectedContainerHierarchy.formUnion(allChildren)
                            continue
                        }

                        nextContainers.append(contentsOf: presentChildren)
                    }
                    containersToProcess = nextContainers
                }
            }

            let songsForRemoval = try backendSongs.filter(
                #Predicate {
                    !exceptions.contains($0.identifier) &&
                    !protectedContainerHierarchy.contains($0.parentContainerId)
                }
            )
            for songToRemove in songsForRemoval {
                Logger.sync.debug("Removing song: \(songToRemove.url)")
                modelContext.delete(songToRemove)
            }
            try modelContext.save()
        } catch let error {
            Logger.sync.error("Could not clear songs for \(backendId): \(error)")
        }
    }

    func clearSongContainers(
        backendId: String,
        withExceptions exceptions: Set<String>,
        withProtectedParents protectedParents: Set<String>
    ) {
        let fetchDescriptor = FetchDescriptor<Container>(
            predicate: #Predicate { $0.backendId == backendId }
        )

        do {
            let backendSongContainers = try modelContext.fetch(fetchDescriptor)
            let protectedContainers = try containersWithChildren(
                parents: protectedParents, backendId: backendId
            )
            let songContainersForRemoval = try backendSongContainers.filter(
                #Predicate {
                    !exceptions.contains($0.identifier) &&
                    !protectedContainers.contains($0.identifier)
                }
            )
            songContainersForRemoval.forEach {
                Logger.sync.debug("Removing container: \($0.identifier)")
                modelContext.delete($0)
            }
            try modelContext.save()
        } catch let error {
            Logger.sync.error("Could not clear container for \(backendId): \(error)")
        }
    }

    func clearStaleGroupings() {
        let albumsFetchDescriptor = FetchDescriptor<Album> (
            predicate: #Predicate { $0.songs.isEmpty }
        )
        let artistsFetchDescriptor = FetchDescriptor<Artist> (
            predicate: #Predicate { $0.songs.isEmpty }
        )
        do {
            let staleAlbums = try modelContext.fetch(albumsFetchDescriptor)
            let staleArtists = try modelContext.fetch(artistsFetchDescriptor)
            for staleAlbum in staleAlbums {
                Logger.sync.info("Removing stale album \(staleAlbum.title)")
                modelContext.delete(staleAlbum)
            }
            for staleArtist in staleArtists {
                Logger.sync.info("Removing stale artist \(staleArtist.name)")
                modelContext.delete(staleArtist)
            }
            try modelContext.save()
        } catch let error {
            Logger.sync.error("Could not delete stale groupings: \(error)")
        }
    }

    func containersWithChildren(parents: Set<String>, backendId: String) throws -> Set<String> {
        let fetchDescriptor = FetchDescriptor<Container>(
            predicate: #Predicate { parents.contains($0.identifier) && $0.backendId == backendId }
        )
        let parentContainers = try modelContext.fetch(fetchDescriptor)
        var hierarchy = parents
        var queue: [Container] = parentContainers

        while !queue.isEmpty {
            var newQueue: [Container] = []
            queue.forEach {
                hierarchy.insert($0.identifier)
                newQueue += $0.childContainers
            }
            queue = newQueue
        }

        return hierarchy
    }
}
