//
//  BackendConfigurationUtils.swift
//  Harmony
//
//  Created by Claudio Cambra on 21/1/24.
//

import Foundation
import HarmonyKit
import OSLog

#if os(macOS)
let BackendConfigurationLocalURLBookmarkDataFieldKeySuffix = "__bookmark-data"
#endif

func saveBackendConfig(
    _ configValues: BackendConfiguration,
    forBackendDescription backendDescription: BackendDescription
) {
    let descriptionId = backendDescription.id
    assert(descriptionId != "")

    let defaults = UserDefaults.standard
    let existingConfigs = defaults.array(forKey: descriptionId)
    let existingConfigsCount = existingConfigs?.count ?? 0
    var backendConfigs: [Any] = existingConfigs ?? []

    // Make sure to keep old config values if they are pre-existing
    var preexistingConfigIndex: Int?
    var fullConfig = configValues
    if let configId = configValues[BackendConfigurationIdFieldKey] as? String,
        let configIndex = existingConfigs?.firstIndex(where: { config in
            let config = config as! BackendConfiguration
            return config[BackendConfigurationIdFieldKey] as? String == configId
        }) {
        preexistingConfigIndex = configIndex
        if let existingConfig = existingConfigs?[configIndex] as? BackendConfiguration {
            // Keep the values already in fullConfig, which are the received new ones
            fullConfig.merge(existingConfig) { current, _ in current }
        }
    } else {
        fullConfig[BackendConfigurationIdFieldKey] = descriptionId + String(existingConfigsCount)
    }

    for field in backendDescription.configDescription {
        guard let fieldValue = fullConfig[field.id] else {
            fullConfig[field.id] = field.defaultValue
            continue
        }

        #if os(macOS)
        if field.valueType == .localUrl {
            // TODO: Handle errors better here
            guard let url = fieldValue as? URL else { continue }
            guard let data = try? url.bookmarkData(options: .withSecurityScope) else { continue }
            let dataFieldId = field.id + BackendConfigurationLocalURLBookmarkDataFieldKeySuffix
            fullConfig[dataFieldId] = data
            Logger.config.debug("Stored local url bookmark data under key \(dataFieldId)")
            fullConfig[field.id] = url.path
        }
        #endif
    }

    if let preexistingConfigIndex = preexistingConfigIndex {
        backendConfigs[preexistingConfigIndex] = fullConfig
    } else {
        backendConfigs.append(fullConfig)
    }
    defaults.set(backendConfigs, forKey: descriptionId)
    BackendsModel.shared.updateBackends()
}

func existingConfigsForBackend(_ backendDescription: BackendDescription) -> [BackendConfiguration] {
    return existingConfigsForBackend(descriptionId: backendDescription.id)
}

func existingConfigsForBackend(descriptionId: String) -> [BackendConfiguration] {
    guard let existingConfigs = UserDefaults.standard.array(forKey: descriptionId) else {
        return []
    }

    var configs: [BackendConfiguration] = []
    for existingConfig in existingConfigs {
        guard let config = existingConfig as? BackendConfiguration else { continue }
        #if os(macOS)
        let bookmarkDatas = Array(
            config.keys
                .filter { $0.contains(BackendConfigurationLocalURLBookmarkDataFieldKeySuffix) }
                .map { config[$0] }
        )
        for data in bookmarkDatas {
            guard let data = data as? Data else {
                Logger.config.error("Found bookmark data is not valid data.")
                continue
            }
            var isStale = false
            guard let accessibleUrl = try? URL(
                resolvingBookmarkData: data,
                options: NSURL.BookmarkResolutionOptions.withSecurityScope, 
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ), !isStale, accessibleUrl.startAccessingSecurityScopedResource() else {
                Logger.config.error("Could not acquire accessible url. isStale: \(isStale)")
                continue
            }
        }
        #endif
        configs.append(config)
    }
    return configs
}

func existingBackendConfigs() -> [BackendConfiguration] {
    var configs: [BackendConfiguration] = []
    for backendDescription in availableBackends {
        let backendConfigs = existingConfigsForBackend(descriptionId: backendDescription.id)
        configs.append(contentsOf: backendConfigs)
    }
    return configs
}

func deleteBackendConfig(id: String, withBackendDescriptionId descriptionId: String) {
    let defaults = UserDefaults.standard
    var backendConfigs = existingConfigsForBackend(descriptionId: descriptionId)
    guard let configIdx = backendConfigs.firstIndex(where: { config in
        config[BackendConfigurationIdFieldKey] as? String == id
    }) else {
        Logger.config.info("Config with id: \(id) does not exist. Can't delete.")
        return
    }

    backendConfigs.remove(at: configIdx)
    defaults.set(backendConfigs, forKey: descriptionId)
    Logger.config.info("Deleted config with id: \(id)")
    BackendsModel.shared.updateBackends()
}
