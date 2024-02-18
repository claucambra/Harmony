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
    @Published var currentlySyncing: Set<String> = Set()
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
        for backend in backends {
            await self.syncBackend(backend)
        }

        currentlySyncingFully = false
    }

    func syncBackend(_ backend: any Backend) async -> Set<String> {
        let refreshedSongs = await runSyncForBackend(backend)

        let ingestTask = Task { @MainActor in
            var refreshedSongIdentifiers: Set<String> = []
            for song in refreshedSongs {
                do {
                    let context = songsContainer.mainContext
                    context.insert(song)
                    try context.save()
                    refreshedSongIdentifiers.insert(song.identifier)
                } catch let error {
                    Logger.sync.error("Could not save song to data: \(error)")
                }
            }
            return refreshedSongIdentifiers
        }

        do {
            return try await ingestTask.result.get()
        } catch let error {
            Logger.sync.error("Could not get result from ingestion task: \(error)")
            return []
        }
    }

    private func runSyncForBackend(_ backend: any Backend) async -> [Song] {
        let backendId = backend.id
        guard !currentlySyncing.contains(backendId) else { return [] }
        self.currentlySyncing.insert(backendId)
        let songs = await backend.scan()
        self.currentlySyncing.remove(backendId)
        return songs
    }
}
