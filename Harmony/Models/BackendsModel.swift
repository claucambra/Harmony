//
//  BackendsModel.swift
//  Harmony
//
//  Created by Claudio Cambra on 21/1/24.
//

import AVFoundation
import Foundation
import HarmonyKit
import OrderedCollections
import OSLog

class BackendsModel: ObservableObject {
    static let shared = BackendsModel()
    @Published var configurations = existingBackendConfigs()
    @Published var backends: OrderedDictionary<String, any Backend> = [:] {  // <BackendId: Backend>
        didSet { backendPresentables = backends.values.map { $0.presentation } }
    }
    @Published var backendPresentables: [BackendPresentable] = []

    private init() {
        updateBackends()
    }

    func updateBackends() {
        // TODO: Handle mid-sync backends here
        configurations = existingBackendConfigs()

        var currentBackends = backends.keys
        for backendDescription in availableBackends {
            for config in configurations {
                guard let configId = config[BackendConfigurationIdFieldKey] as? String,
                      configId.starts(with: backendDescription.id),
                      let configuredBackend = backendFromDescriptionId(
                        backendDescription.id, withConfig: config
                      )
                else {
                    continue
                }
                backends[configId] = configuredBackend
                currentBackends.remove(configId)
            }
        }

        for remainingBackend in currentBackends {
            let backend = backends[remainingBackend]
            backend?.cancelScan()
            backends.removeValue(forKey: remainingBackend)
            clearBackendStorage(remainingBackend)
            Task {
                await SyncDataActor.shared.clearSongs(
                    backendId: remainingBackend,
                    withExceptions: [],
                    avoidingContainers: []
                )
                await SyncDataActor.shared.clearSongContainers(
                    backendId: remainingBackend, withExceptions: [], withProtectedParents: []
                )
                await SyncDataActor.shared.clearStaleGroupings()
            }
        }
    }

    private func clearBackendStorage(_ backendId: String) {
        if let backendStorageUrl = backendStorageUrl(backendId: backendId),
           FileManager.default.fileExists(atPath: backendStorageUrl.path)
        {
            do {
                try FileManager.default.removeItem(at: backendStorageUrl)
                Logger.backendsModel.debug("Cleared up storage for \(backendId)")
            } catch let error {
                Logger.backendsModel.error("Could not clean up storage for \(backendId): \(error)")
            }
        } else {
            Logger.backendsModel.warning("Can't clear inexistent storage for \(backendId)")
        }
    }

    func playerForSong(_ song: Song) -> (any BackendPlayer)? {
        return backends[song.backendId]?.player
    }
}
