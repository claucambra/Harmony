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
        for backend in availableBackends {
            for config in configurations {
                guard let configuredBackend = backendFromId(backend.id, withConfig: config) else {
                    continue
                }
                backends[configuredBackend.id] = configuredBackend
            }
        }
    }

    func assetForSong(atURL url: URL, backendId: String) -> AVAsset? {
        guard let backend = backends[backendId] else { return nil }
        return backend.assetForSong(atURL: url)
    }
}
