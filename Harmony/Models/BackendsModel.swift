//
//  BackendsModel.swift
//  Harmony
//
//  Created by Claudio Cambra on 21/1/24.
//

import Foundation
import HarmonyKit

class BackendsModel: ObservableObject {
    static let shared = BackendsModel()
    @Published var configurations = existingConfigs()
    @Published var backends: [any Backend] = []

    private init() {
        updateBackends()
    }

    private func updateBackends() {
        for backend in availableBackends {
            for config in configurations {
                guard let configuredBackend = backendFromId(backend.id, withConfig: config) else {
                    continue
                }
                backends.append(configuredBackend)
            }
        }
    }
}
