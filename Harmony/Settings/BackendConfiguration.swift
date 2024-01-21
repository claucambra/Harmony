//
//  BackendConfiguration.swift
//  Harmony
//
//  Created by Claudio Cambra on 21/1/24.
//

import Foundation
import HarmonyKit

typealias BackendConfiguration = [String: Any]

func saveConfig(_ configValues: BackendConfiguration, forBackend backend: BackendDescription) {
    let defaults = UserDefaults.standard
    var backendConfigs: [Any]

    if let existingConfigs = defaults.array(forKey: backend.id) {
        backendConfigs = existingConfigs
    } else {
        backendConfigs = []
    }

    var fullConfig = configValues
    for field in backend.configDescription {
        if fullConfig[field.id] == nil {
            fullConfig[field.id] = field.defaultValue
        }
    }

    backendConfigs.append(fullConfig)
    defaults.set(backendConfigs, forKey: backend.id)
}
