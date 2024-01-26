//
//  BackendsModel.swift
//  Harmony
//
//  Created by Claudio Cambra on 21/1/24.
//

import AVFoundation
import Foundation
import HarmonyKit

class BackendsModel: ObservableObject {
    static let shared = BackendsModel()
    @Published var configurations = existingConfigs()
    @Published var backends: [any Backend] = []

    private init() {
        updateBackends()
    }

    func updateBackends() {
        for backend in availableBackends {
            for config in configurations {
                guard let configuredBackend = backendFromId(backend.id, withConfig: config) else {
                    continue
                }
                backends.append(configuredBackend)
            }
        }
    }

    func backend(id: String) -> (any Backend)? {
        for backend in backends {
            if backend.id == id {
                return backend
            }
        }
        return nil
    }

    func assetForSong(atURL url: URL, backendId: String) -> AVAsset? {
        guard let backend = backend(id: backendId) else { return nil }
        return backend.assetForSong(atURL: url)
    }
}
