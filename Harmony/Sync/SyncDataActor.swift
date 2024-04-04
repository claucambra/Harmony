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

    func ingestSong(_ song: Song) {
        let songIdentifier = song.identifier
        Logger.sync.info("Ingesting song: \(song.title) \(song.identifier)")
        do {
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

            let album = processSongAlbum(song)
            processSongArtist(song, inAlbum: album)
        } catch let error {
            Logger.sync.error("Could not save song to data: \(error)")
        }
    }

    private func processSongAlbum(_ song: Song) -> Album? {
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

    func processSongArtist(_ song: Song, inAlbum album: Album?) {
        let songIdentifier = song.identifier
        do {
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
                } else if let artist = Artist(name: artistName, songs: [song]) {
                    modelContext.insert(artist)
                }
                try modelContext.save()
            }
        } catch let error {
            Logger.sync.error("Could not process artist for song \(songIdentifier): \(error)")
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
            let backendSongs = try modelContext.fetch(fetchDescriptor)
            let songsForRemoval = try backendSongs.filter(
                #Predicate {
                    !exceptions.contains($0.identifier) &&
                    !songContainers.contains($0.parentContainerId)
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
            predicate: #Predicate { $0.backendId == backendId }
        )
        let backendSongContainers = try modelContext.fetch(fetchDescriptor)
        let directChildren = Set(try backendSongContainers.filter(
            #Predicate { parents.contains($0.identifier) }
        ))
        let potentialNonChildren = try backendSongContainers.filter(
            #Predicate { !parents.contains($0.identifier) }
        )
        var validChildren = parents.union(directChildren.map { $0.identifier })
        for container in potentialNonChildren {
            let songContainerId = container.identifier
            guard !validChildren.contains(songContainerId) else { continue }
            var hierarchy: Set<String> = [songContainerId]
            var nextParent = container.parentContainer
            while let scanningParent = nextParent {
                let scanningParentId = scanningParent.identifier
                guard !validChildren.contains(scanningParentId) else {
                    validChildren.formUnion(hierarchy)
                    break
                }
                hierarchy.insert(scanningParentId)
                if parents.contains(scanningParentId) {
                    validChildren.formUnion(hierarchy)
                    break
                } else {
                    nextParent = scanningParent.parentContainer
                }
            }
        }
        return validChildren
    }
}
