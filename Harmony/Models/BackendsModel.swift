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
    @Published var configurations = existingConfigs()
    @Published var backends: OrderedDictionary<String, any Backend> = [:]

    private init() {
        updateBackends()
    }

    func updateBackends() {
        // TODO: Handle mid-sync backends here
        configurations = existingConfigs()

        var currentBackends = backends.keys
        for backendDescription in availableBackends {
            for config in configurations {
                guard let configuredBackend = backendFromDescriptionId(
                    backendDescription.id, withConfig: config
                ) else {
                    continue
                }
                let configId = configuredBackend.id
                backends[configId] = configuredBackend
                currentBackends.remove(configId)
            }
        }

        for remainingBackend in currentBackends {
            backends.removeValue(forKey: remainingBackend)
        }
    }

    func assetForSong(atURL url: URL, backendId: String) -> AVAsset? {
        guard let backend = backends[backendId] else { return nil }
        return backend.assetForSong(atURL: url)
    }
}
