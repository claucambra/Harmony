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

class BackendsModel: ObservableObject {
    static let shared = BackendsModel()
    @Published var configurations = existingBackendConfigs()
    @Published var backends: OrderedDictionary<String, any Backend> = [:] {
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
            backends.removeValue(forKey: remainingBackend)
        }
    }

    func assetForSong(_ song: Song) -> AVAsset? {
        guard let backend = backends[song.backendId] else { return nil }
        return backend.assetForSong(song)
    }
}
