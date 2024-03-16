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

actor SyncDataActor {
    let container = try! ModelContainer(for: Song.self, Album.self, Artist.self, Container.self)
    lazy var context = ModelContext(container)

    // TODO: Deduplicate approval methods with use of generics/protocol
    func approvalForSongScan(id: String, versionId: String) -> Bool {
        do {
            let fetchDescriptor = FetchDescriptor<Song>(predicate: #Predicate<Song> {
                $0.identifier == id
            })
            guard let existingSong = try context.fetch(fetchDescriptor).first else {
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
            guard let existingSongContainer = try context.fetch(fetchDescriptor).first else {
                return true
            }
            return existingSongContainer.versionId != versionId
        } catch let error {
            Logger.sync.error("Could not get accurate approval for container, approving")
            return true
        }
    }

    func ingestSong(_ song: Song) {
        let songIdentifier = song.identifier
        do {
            let context = ModelContext(container)
            let fetchDescriptor = FetchDescriptor<Song>(
                predicate: #Predicate<Song> { $0.identifier == songIdentifier }
            )
            let existingSong = try context.fetch(fetchDescriptor).first

            if let existingSong = existingSong {
                let isOutdated = song.versionId != existingSong.versionId
                let existingDlState = existingSong.downloadState
                var refreshedDlState = DownloadState.notDownloaded
                if existingDlState == DownloadState.downloaded.rawValue {
                    refreshedDlState = isOutdated ? .downloadedOutdated : .downloaded
                } else if existingDlState == DownloadState.downloading.rawValue {
                    refreshedDlState = .downloading
                }
                let refreshedSong = song.clone(downloadState: refreshedDlState)
                context.insert(refreshedSong)
            } else {
                context.insert(song)
            }

            let albumTitle = song.album
            let albumFetchDescriptor = FetchDescriptor<Album>(
                predicate: #Predicate { $0.title == albumTitle }
            )
            var album: Album?
            if let existingAlbum = try context.fetch(albumFetchDescriptor).first {
                if !existingAlbum.songs.contains(where: { $0.identifier == songIdentifier }) {
                    existingAlbum.songs.append(song)
                }
                album = existingAlbum
            } else if let newAlbum = Album(songs: [song]) {
                context.insert(newAlbum)
                album = newAlbum
            }

            let artistNames = song.artist.components(separatedBy: "; ")
            for artistName in artistNames {
                let artistFetchDescriptor = FetchDescriptor<Artist>(
                    predicate: #Predicate { $0.name == artistName }
                )
                if let artist = try context.fetch(artistFetchDescriptor).first {
                    if !artist.songs.contains(where: { $0.identifier == songIdentifier }) {
                        artist.songs.append(song)
                    }
                    if let album = album, 
                        !artist.albums.contains(where: { $0.title == album.title })
                    {
                        artist.albums.append(album)
                    }
                }
            }

            try context.save()
        } catch let error {
            Logger.sync.error("Could not save song to data: \(error)")
        }
    }

    func ingestContainer(_ songContainer: Container, parentContainer: Container?) {
        do {
            context.insert(songContainer)
            if let parentContainer = parentContainer {
                let parentId = parentContainer.identifier
                let childId = songContainer.identifier
                let fetchDescriptor = FetchDescriptor<Container>(
                    predicate: #Predicate { $0.identifier == parentId }
                )
                var parentContainerToUse: Container
                if let result = try? context.fetch(fetchDescriptor).first {
                    parentContainerToUse = result
                } else {
                    context.insert(parentContainer)
                    parentContainerToUse = parentContainer
                }
                if !parentContainerToUse.childContainers.contains(
                    where: { $0.identifier == childId }
                ) {
                    parentContainerToUse.childContainers.append(songContainer)
                }
            }
            try context.save()
        } catch let error {
            Logger.sync.error("Could not save container to data: \(error)")
        }
    }

    // Remove songs. Exceptions should contain song ids
    func clearSongs(
        backendId: String,
        withExceptions exceptions: Set<String>,
        avoidingContainers songContainers: Set<String>
    ) {
        let fetchDescriptor = FetchDescriptor<Song>(
            predicate: #Predicate { $0.backendId == backendId }
        )

        do {
            let backendSongs = try context.fetch(fetchDescriptor)
            let songsForRemoval = try backendSongs.filter(
                #Predicate {
                    !exceptions.contains($0.identifier) &&
                    !songContainers.contains($0.parentContainerId)
                }
            )
            for songToRemove in songsForRemoval {
                Logger.sync.debug("Removing song: \(songToRemove.url)")
                context.delete(songToRemove)
            }
            try context.save()
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
            let backendSongContainers = try context.fetch(fetchDescriptor)
            let songContainersForRemoval = try backendSongContainers.filter(
                #Predicate { !exceptions.contains($0.identifier) }
            )
            var validChildren: Set<String> = protectedParents
            for songContainerToRemove in songContainersForRemoval {
                let songContainerId = songContainerToRemove.identifier
                guard !validChildren.contains(songContainerId) else { continue }
                var hierarchy: Set<String> = [songContainerId]
                var validParent = false
                var nextParent = songContainerToRemove.parentContainer
                while let scanningParent = nextParent {
                    let scanningParentId = scanningParent.identifier
                    guard !validChildren.contains(scanningParentId) else {
                        validParent = true
                        break
                    }
                    hierarchy.insert(scanningParentId)
                    if protectedParents.contains(scanningParentId) {
                        validParent = true
                        validChildren.formUnion(hierarchy)
                        break
                    } else {
                        nextParent = scanningParent.parentContainer
                    }
                }

                if !validParent {
                    Logger.sync.debug("Removing container: \(songContainerToRemove.identifier)")
                    context.delete(songContainerToRemove)
                }
            }
            try context.save()
        } catch let error {
            Logger.sync.error("Could not clear container for \(backendId): \(error)")
        }
    }

    func clearAlbums(withExceptions exceptions: Set<String>) {
        let fetchDescriptor = FetchDescriptor<Album>()

        do {
            let albums = try context.fetch(fetchDescriptor)
            let albumsToRemove = try albums.filter(
                #Predicate { !exceptions.contains($0.title) }
            )
            for albumToRemove in albumsToRemove {
                Logger.sync.debug("Removing album: \(albumToRemove.title)")
                context.delete(albumToRemove)
            }
            try context.save()
        } catch let error {
            Logger.sync.error("Could not clear albums: \(error)")
        }
    }

    func clearArtists(withExceptions exceptions: Set<String>) {
        let fetchDescriptor = FetchDescriptor<Artist>()

        do {
            let artists = try context.fetch(fetchDescriptor)
            let artistsToRemove = try artists.filter(
                #Predicate { !exceptions.contains($0.name) }
            )
            for artistToRemove in artistsToRemove {
                Logger.sync.debug("Removing artist: \(artistToRemove.name)")
                context.delete(artistToRemove)
            }
            try context.save()
        } catch let error {
            Logger.sync.error("Could not clear albums: \(error)")
        }
    }
}
