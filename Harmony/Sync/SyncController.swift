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

actor CurrentSyncActor {
    var foundSongs: [String: String] = [:]  // song id, backend id
    var foundContainers: [String: String] = [:]  // container id, backend id
    var skippedContainers: [String: String] = [:]  // container id, backend id

    func addFound(songId: String, backendId: String) {
        foundSongs[songId] = backendId
    }

    func addFound(containerId: String, backendId: String) {
        foundContainers[containerId] = backendId
    }

    func addSkipped(containerId: String, backendId: String) {
        skippedContainers[containerId] = backendId
    }

    func removeFound(songIds: [String]) {
        songIds.forEach { foundSongs.removeValue(forKey: $0) }
    }

    func removeFound(containerIds: [String]) {
        containerIds.forEach { foundContainers.removeValue(forKey: $0) }
    }

    func removeSkipped(containerIds: [String]) {
        containerIds.forEach { skippedContainers.removeValue(forKey: $0) }
    }
}

public class SyncController: ObservableObject {
    static let shared = SyncController()
    let dataActor = SyncDataActor(
        modelContainer: try! ModelContainer(for: Song.self, Album.self, Artist.self, Container.self)
    )
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

    init() {
        Task.detached(priority: .background) {
            await self.sync()
        }
        
        NotificationCenter.default.addObserver(
            forName: BackendNewScanRequiredNotification,
            object: nil,
            queue: .current,
            using: { notification in
                guard let backend = notification.object as? any Backend else {
                    Logger.sync.error("New scan required notification but object isn't backend")
                    return
                }
                Task { await self.syncBackend(backend) }
            }
        )
    }

    public func sync() async {
        Task { @MainActor in
            currentlySyncingFully = true
        }
        await self.dataActor.cleanup()
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
        guard !currentlySyncingFully, !backend.presentation.scanning else { return }

        let backendId = backend.id
        let currentSyncActor = CurrentSyncActor()
        do {
            try await backend.scan(containerScanApprover: { containerId, containerVersionId in
                await currentSyncActor.addFound(containerId: containerId, backendId: backendId)
                let approved = await self.dataActor.approvalForSongContainerScan(
                    id: containerId, versionId: containerVersionId
                )
                if !approved {
                    await currentSyncActor.addSkipped(
                        containerId: containerId, backendId: backendId
                    )
                }
                return approved
            }, songScanApprover: { songId, songVersionId in
                await currentSyncActor.addFound(songId: songId, backendId: backendId)
                return await self.dataActor.approvalForSongScan(
                    id: songId, versionId: songVersionId
                )
            }, finalisedSongHandler: { song in
                await self.dataActor.ingestSong(song)
            }, finalisedContainerHandler: { songContainer, parentContainer in
                await self.dataActor.ingestContainer(
                    songContainer, parentContainer: parentContainer
                )
            })

            do {
                let retrievedSongIdentifiers = try await currentSyncActor.foundSongs.filter(
                    #Predicate { $0.value == backendId }
                ).map { $0.key }
                let retrievedContainerIdentifiers = try await currentSyncActor.foundContainers.filter(
                    #Predicate { $0.value == backendId }
                ).map { $0.key }
                let skippedContainerIdentifiers = try await currentSyncActor.skippedContainers.filter(
                    #Predicate { $0.value == backendId }
                ).map { $0.key }

                await currentSyncActor.removeFound(songIds: retrievedSongIdentifiers)
                await currentSyncActor.removeFound(containerIds: retrievedContainerIdentifiers)
                await currentSyncActor.removeSkipped(containerIds: skippedContainerIdentifiers)

                let songExceptionSet = Set(retrievedSongIdentifiers)
                let foundContainers = Set(retrievedContainerIdentifiers)
                let skippedContainers = Set(skippedContainerIdentifiers)
                // Clear all stale songs (i.e. those that no longer exist in backend)
                await self.dataActor.clearSongs(
                    backendId: backend.id,
                    withExceptions: songExceptionSet,
                    avoidingContainers: skippedContainers
                )
                await self.dataActor.clearSongContainers(
                    backendId: backend.id,
                    withExceptions: foundContainers,
                    withProtectedParents: skippedContainers
                )
                await self.dataActor.clearStaleGroupings()
            } catch let error {
                Logger.sync.error("Could not get result from ingestion task: \(error)")
                return
            }
        } catch let error {
            Logger.sync.error("Sync for backend \(backendId) did not complete: \(error)")
        }
    }
}
