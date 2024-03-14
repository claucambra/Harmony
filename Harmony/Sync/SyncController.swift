//
//  SyncController.swift
//  Harmony
//
//  Created by Claudio Cambra on 18/1/24.
//

import Foundation
import HarmonyKit
import OSLog
import SwiftData

public class SyncController: ObservableObject {
    static let shared = SyncController()
    let container = try! ModelContainer(for: Song.self, Album.self, Artist.self, Container.self)
    @Published var currentlySyncingFully: Bool = false
    @Published var poll: Bool = false {
        didSet {
            if poll {
                let interval = TimeInterval(60 * 60)
                pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                    Task { await self.sync() }
                }
            } else {
                pollTimer?.invalidate()
                pollTimer = nil
            }
        }
    }
    private var pollTimer: Timer? = nil
    private var currentSyncsFoundSongs: [String: String] = [:]  // song id, backend id

    init() {
        Task.detached(priority: .background) {
            await self.sync()
        }
    }

    public func sync() async {
        currentlySyncingFully = true
        let backends = BackendsModel.shared.backends.values
        await withDiscardingTaskGroup { group in
            for backend in backends {
                group.addTask {
                    await self.syncBackend(backend)
                }
            }
        }
        currentlySyncingFully = false
    }

    func syncBackend(_ backend: any Backend) async {
        let backendId = backend.id
        await backend.scan(containerScanApprover: { containerId, containerVersionId in
            return true  // TODO: Do not approve if versionId is same
        }, songScanApprover: { songId, songVersionId in
            self.currentSyncsFoundSongs[songId] = backendId
            return true  // TODO: Do not approve if versionId is same
        }, finalisedSongHandler: { song in
            self.ingestSong(song)
        }, finalisedContainerHandler: { container in
            // TODO
            // Needs to wait for songs to be finalised; that way we do not register a container
            // as up to date if the sync procedure is cut off half-way
        })

        do {
            let retrievedIdentifiers = try currentSyncsFoundSongs.filter(
                #Predicate { $0.value == backendId }
            ).map { $0.key }
            clearSongs(backendId: backend.id, withExceptions: Set(retrievedIdentifiers))
            refreshGroupings()
        } catch let error {
            Logger.sync.error("Could not get result from ingestion task: \(error)")
            return
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

    // Remove songs. Exceptions should contain song ids
    func clearSongs(backendId: String, withExceptions exceptions: Set<String>) {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<Song>(
            predicate: #Predicate { $0.backendId == backendId }
        )

        do {
            let backendSongs = try context.fetch(fetchDescriptor)
            let songsForRemoval = try backendSongs.filter(
                #Predicate { !exceptions.contains($0.identifier) }
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

    // TODO: Make progressive on each song ingest
    func refreshGroupings() {
        Logger.sync.info("Refreshing albums and artists.")
        let context = ModelContext(container)
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
        let context = ModelContext(container)
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
        let context = ModelContext(container)
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
