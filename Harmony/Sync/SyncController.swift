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
    let container = try! ModelContainer(for: Song.self, Album.self, Artist.self)
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

    public func sync() async {
        currentlySyncingFully = true

        let backends = BackendsModel.shared.backends.values
        // TODO: Run concurrently
        for backend in backends {
            await self.syncBackend(backend)
        }

        currentlySyncingFully = false
    }

    func syncBackend(_ backend: any Backend) async {
        let refreshedSongs = await runSyncForBackend(backend)

        let ingestTask = Task { @MainActor in
            var refreshedSongIdentifiers: Set<String> = []
            for song in refreshedSongs {
                let songIdentifier = song.identifier
                do {
                    let context = container.mainContext
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
                    refreshedSongIdentifiers.insert(songIdentifier)
                } catch let error {
                    Logger.sync.error("Could not save song to data: \(error)")
                }
            }
            refreshGroupings()
            return refreshedSongIdentifiers
        }

        do {
            let retrievedIdentifiers = try await ingestTask.result.get()
            await clearSongs(backendId: backend.id, withExceptions: retrievedIdentifiers)
        } catch let error {
            Logger.sync.error("Could not get result from ingestion task: \(error)")
            return
        }
    }

    private func runSyncForBackend(_ backend: any Backend) async -> [Song] {
        guard !backend.presentation.scanning else { return [] }
        let songs = await backend.scan()
        return songs
    }

    @MainActor  // Remove songs. Exceptions should contain song ids
    func clearSongs(backendId: String, withExceptions exceptions: Set<String>) {
        let context = container.mainContext
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

    @MainActor
    func refreshGroupings() {
        Logger.sync.info("Refreshing albums and artists.")
        let context = container.mainContext
        let fetchDescriptor = FetchDescriptor<Song>()
        
        do {
            let songs = try context.fetch(fetchDescriptor)
            var artistDict: Dictionary<String, [Song]> = [:]
            var albumDict: Dictionary<String, [Song]> = [:]
            for song in songs {
                let album = song.album
                let artist = song.artist

                if var existingSongs = albumDict[album] {
                    existingSongs.append(song)
                    albumDict[album] = existingSongs
                } else {
                    albumDict[album] = [song]
                }

                if var existingSongs = artistDict[artist] {
                    existingSongs.append(song)
                    artistDict[artist] = existingSongs
                } else {
                    artistDict[artist] = [song]
                }
            }

            Logger.sync.info("About to insert \(albumDict.count) albums.")
            for songs in albumDict.values {
                guard let album = Album(songs: songs) else { continue }
                context.insert(album)
            }
            Logger.sync.info("About to insert \(artistDict.count) artists.")
            for songs in artistDict.values {
                guard let artist = Artist(songs: songs) else { continue }
                context.insert(artist)
            }
            try context.save()
        } catch let error {
            Logger.sync.error("Could not refresh albums: \(error)")
        }
    }

    @MainActor
    func clearAlbums(withExceptions exceptions: Set<String>) {
        let context = container.mainContext
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

    @MainActor
    func clearArtists(withExceptions exceptions: Set<String>) {
        let context = container.mainContext
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
