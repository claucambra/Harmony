//
//  BackendConfiguration.swift
//  Harmony
//
//  Created by Claudio Cambra on 21/1/24.
//

import Foundation
import HarmonyKit

let BackendConfigurationIdFieldKey = "config-id"

func saveConfig(_ configValues: BackendConfiguration, forBackend backend: BackendDescription) {
    assert(backend.id != "")

    let defaults = UserDefaults.standard
    let existingConfigs = defaults.array(forKey: backend.id)
    let existingConfigsCount = existingConfigs?.count ?? 0
    var backendConfigs: [Any] = existingConfigs ?? []

    var fullConfig = configValues
    for field in backend.configDescription {
        if fullConfig[field.id] == nil {
            fullConfig[field.id] = field.defaultValue
        }
    }
    fullConfig[BackendConfigurationIdFieldKey] = backend.id + String(existingConfigsCount)

    backendConfigs.append(fullConfig)
    defaults.set(backendConfigs, forKey: backend.id)
}

func existingConfigsForBackend(_ backend: BackendDescription) -> [BackendConfiguration] {
    guard let existingConfigs = UserDefaults.standard.array(forKey: backend.id) else {
        return []
    }

    var configs: [BackendConfiguration] = []
    for existingConfig in existingConfigs {
        guard let config = existingConfig as? BackendConfiguration else { continue }
        configs.append(config)
    }
    return configs
}

func existingConfigs() -> [BackendConfiguration] {
    var configs: [BackendConfiguration] = []
    for backend in availableBackends {
        let backendConfigs = existingConfigsForBackend(backend)
        configs.append(contentsOf: backendConfigs)
    }
    return configs
}
