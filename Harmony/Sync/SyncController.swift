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
    @Published var currentlySyncing: Set<String> = Set()
    @Published var currentlySyncingFully: Bool = false
    let songsContainer = try! ModelContainer(for: Song.self)
    private var pollTimer: Timer? = nil

    private init(poll: Bool = true) {
        if poll {
            let interval = TimeInterval(15 * 60)
            pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                Task {
                    await self.sync()
                }
            }
        }
    }

    public func sync() async {
        currentlySyncingFully = true

        let backends = BackendsModel.shared.backends.values
        for backend in backends {
            await self.syncBackend(backend)
        }

        currentlySyncingFully = false
    }

    func syncBackend(_ backend: any Backend) async {
        let refreshedSongs = await runSyncForBackend(backend)
        Task { @MainActor in
            for song in refreshedSongs {
                do {
                    let context = songsContainer.mainContext
                    context.insert(song)
                    try context.save()
                } catch let error {
                    Logger.sync.error("Could not save song to data: \(error)")
                }
            }
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
