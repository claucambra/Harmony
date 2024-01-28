//
//  SyncController.swift
//  Harmony
//
//  Created by Claudio Cambra on 18/1/24.
//

import Foundation
import HarmonyKit

public class SyncController: ObservableObject {
    @Published var currentlySyncing: Set<String> = Set()
    @Published var currentlySyncingFully: Bool = false
    private var pollTimer: Timer? = nil

    public init(poll: Bool = true) {
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
        let refreshedSongs = await withTaskGroup(of: [Song].self, returning: [Song].self) { group in
            for backend in backends {
                group.addTask {
                    return await self.runSyncForBackend(backend)
                }
            }

            var allScannedSongs: [Song] = []
            for await result in group {
                allScannedSongs.append(contentsOf: result)
            }
            return allScannedSongs
        }
        Task { @MainActor in
            DatabaseManager.shared.writeSongs(refreshedSongs)
        }

        currentlySyncingFully = false
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
