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
            let fetchDescriptor = FetchDescriptor<Song>(predicate: #Predicate<Song> {
                $0.identifier == songIdentifier
            })
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

    // TODO: Make progressive on each song ingest
    func refreshGroupings() {
        Logger.sync.info("Refreshing albums and artists.")
        let fetchDescriptor = FetchDescriptor<Song>()

        do {
            let songs = try context.fetch(fetchDescriptor)
            var artistDict: Dictionary<String, [Song]> = [:]
            var albumDict: Dictionary<String, [Song]> = [:]
            for song in songs {
                let album = song.album
                let artists = song.artist.components(separatedBy: "; ")

                if var existingSongs = albumDict[album] {
                    existingSongs.append(song)
                    albumDict[album] = existingSongs
                } else {
                    albumDict[album] = [song]
                }

                for artist in artists {
                    if var existingSongs = artistDict[artist] {
                        existingSongs.append(song)
                        artistDict[artist] = existingSongs
                    } else {
                        artistDict[artist] = [song]
                    }
                }
            }

            Logger.sync.info("About to insert \(albumDict.count) albums.")
            for songs in albumDict.values {
                guard let album = Album(songs: songs) else { continue }
                context.insert(album)
            }
            Logger.sync.info("About to insert \(artistDict.count) artists.")
            for (artistName, songs) in artistDict {
                guard let artist = Artist(name: artistName, songs: songs) else { continue }
                context.insert(artist)
            }
            clearAlbums(withExceptions: Set(albumDict.keys))
            clearArtists(withExceptions: Set(artistDict.keys))
            try context.save()
        } catch let error {
            Logger.sync.error("Could not refresh albums: \(error)")
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
