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

@MainActor
public class SyncController: ObservableObject {
    static let shared = SyncController()
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
        currentlySyncingFully = true
        await SyncDataActor.shared.cleanup()
        let backends = BackendsModel.shared.backends.values
        for backend in backends {
            await self.syncBackend(backend)
        }
        currentlySyncingFully = false
    }

    func syncBackend(_ backend: any Backend) async {
        guard !backend.presentation.scanning else { return }
        
        let backendId = backend.backendId
        let currentSyncActor = CurrentSyncActor()
        do {
            try await backend.scan(containerScanApprover: { containerId, containerVersionId in
                await currentSyncActor.addFound(containerId: containerId, backendId: backendId)
                let approved = await SyncDataActor.shared.approvalForSongContainerScan(
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
                return await SyncDataActor.shared.approvalForSongScan(
                    id: songId, versionId: songVersionId
                )
            }, finalisedSongHandler: { song in
                guard let ingestedSong = await SyncDataActor.shared.ingestSong(song) else { return }
                let album = await SyncDataActor.shared.processSongAlbum(ingestedSong)
                await SyncDataActor.shared.processSongArtist(ingestedSong, inAlbum: album)
            }, finalisedContainerHandler: { songContainer, parentContainer in
                await SyncDataActor.shared.ingestContainer(
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
                print("foundContainers", foundContainers, "skippedContianers", skippedContainers)
                await SyncDataActor.shared.clearSongs(
                    backendId: backend.backendId,
                    withExceptions: songExceptionSet,
                    avoidingContainers: skippedContainers
                )
                await SyncDataActor.shared.clearSongContainers(
                    backendId: backend.backendId,
                    withExceptions: foundContainers,
                    withProtectedParents: skippedContainers
                )
                await SyncDataActor.shared.clearStaleGroupings()
            } catch let error {
                Logger.sync.error("Could not get result from ingestion task: \(error)")
                return
            }
        } catch let error {
            Logger.sync.error("Sync for backend \(backendId) did not complete: \(error)")
        }
    }
}
