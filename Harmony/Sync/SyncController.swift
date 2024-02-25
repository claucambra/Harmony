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
    let songsContainer = try! ModelContainer(for: Song.self)
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
                    let context = songsContainer.mainContext
                    context.insert(song)
                    try context.save()
                    refreshedSongIdentifiers.insert(songIdentifier)
                } catch let error {
                    Logger.sync.error("Could not save song to data: \(error)")
                }
            }
            return refreshedSongIdentifiers
        }

        do {
            let retrievedIdentifiers = try await ingestTask.result.get()
            await clearStaleSongs(backendId: backend.id, freshSongIdentifiers: retrievedIdentifiers)
        } catch let error {
            Logger.sync.error("Could not get result from ingestion task: \(error)")
            return
        }
    }

    private func runSyncForBackend(_ backend: any Backend) async -> [Song] {
        let backendId = backend.id
        guard !backend.presentation.scanning else { return [] }
        let songs = await backend.scan()
        return songs
    }

    @MainActor
    private func clearStaleSongs(backendId: String, freshSongIdentifiers: Set<String>) {
        let context = songsContainer.mainContext
        let fetchDescriptor = FetchDescriptor<Song>(
            predicate: #Predicate { $0.backendId == backendId }
        )

        do {
            let backendSongs = try context.fetch(fetchDescriptor)
            let staleSongs = try backendSongs.filter(
                #Predicate { !freshSongIdentifiers.contains($0.identifier) }
            )
            for staleSong in staleSongs {
                Logger.sync.debug("Removing stale song: \(staleSong.url)")
                context.delete(staleSong)
            }
            try context.save()
        } catch let error {
            Logger.sync.error("Could not clear stale songs for \(backendId): \(error)")
        }
    }
}
