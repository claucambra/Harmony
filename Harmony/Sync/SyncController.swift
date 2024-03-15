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
    let dataActor = SyncDataActor()
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
    private var currentSyncsFoundContainers: [String: String] = [:]  // container id, backend id

    init() {
        Task.detached(priority: .background) {
            await self.sync()
        }
    }

    public func sync() async {
        Task { @MainActor in
            currentlySyncingFully = true
        }
        let backends = BackendsModel.shared.backends.values
        await withDiscardingTaskGroup { group in
            for backend in backends {
                group.addTask {
                    await self.syncBackend(backend)
                }
            }
        }
        Task { @MainActor in
            currentlySyncingFully = false
        }
    }

    func syncBackend(_ backend: any Backend) async {
        guard !backend.presentation.scanning else { return }

        let backendId = backend.id
        await backend.scan(containerScanApprover: { containerId, containerVersionId in
            Task { @MainActor in
                self.currentSyncsFoundContainers[containerId] = backendId
            }
            return await self.dataActor.approvalForSongContainerScan(
                id: containerId, versionId: containerVersionId
            )
        }, songScanApprover: { songId, songVersionId in
            Task { @MainActor in
                self.currentSyncsFoundSongs[songId] = backendId
            }
            return await self.dataActor.approvalForSongScan(id: songId, versionId: songVersionId)
        }, finalisedSongHandler: { song in
            await self.dataActor.ingestSong(song)
        }, finalisedContainerHandler: { songContainer in
            await self.dataActor.ingestContainer(songContainer)
        })

        do {
            let retrievedSongIdentifiers = try currentSyncsFoundSongs.filter(
                #Predicate { $0.value == backendId }
            ).map { $0.key }
            let retrievedContainerIdentifiers = try currentSyncsFoundContainers.filter(
                #Predicate { $0.value == backendId }
            ).map { $0.key }
            for songId in retrievedSongIdentifiers {
                currentSyncsFoundSongs.removeValue(forKey: songId)
            }
            let exceptionSet = Set(retrievedSongIdentifiers)
            let skippedContainers = Set(retrievedContainerIdentifiers)
            // Clear all stale songs (i.e. those that no longer exist in backend)
            await self.dataActor.clearSongs(
                backendId: backend.id,
                withExceptions: exceptionSet,
                avoidingContainers: skippedContainers
            )
            await self.dataActor.clearSongContainers(
                backendId: backend.id, withExceptions: skippedContainers
            )
            await self.dataActor.refreshGroupings()
        } catch let error {
            Logger.sync.error("Could not get result from ingestion task: \(error)")
            return
        }
    }
}
