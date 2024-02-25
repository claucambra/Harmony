//
//  BackendConfigurationUtils.swift
//  Harmony
//
//  Created by Claudio Cambra on 21/1/24.
//

import Foundation
import HarmonyKit
import OSLog

let BackendConfigurationLocalURLBookmarkDataFieldKeySuffix = "__bookmark-data"
let BackendConfigurationPasswordFieldKeySuffix = "__password"

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

    let backendId = fullConfig[BackendConfigurationIdFieldKey] as! String

    for field in backendDescription.configDescription {
        guard let fieldValue = fullConfig[field.id] else {
            fullConfig[field.id] = field.defaultValue
            continue
        }

        if field.valueType == .localUrl {
            // TODO: Handle errors better here
            guard let url = fieldValue as? URL else { continue }
            guard url.startAccessingSecurityScopedResource() else { continue }
            #if os(macOS)
            guard let data = try? url.bookmarkData(options: .withSecurityScope) else { continue }
            #else
            guard let data = try? url.bookmarkData(options: .minimalBookmark) else { continue }
            #endif
            let dataFieldId = field.id + BackendConfigurationLocalURLBookmarkDataFieldKeySuffix
            fullConfig[dataFieldId] = data
            Logger.config.debug("Stored local url bookmark data under key \(dataFieldId)")
            fullConfig[field.id] = url.path
            url.stopAccessingSecurityScopedResource()
        } else if field.valueType == .password {
            fullConfig.removeValue(forKey: field.id)
            fullConfig[field.id + BackendConfigurationPasswordFieldKeySuffix] = field.id
            guard let password = fieldValue as? String else { continue }
            savePasswordInKeychain(password, forBackend: backendId, withFieldId: field.id)
        }
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
        guard var config = existingConfig as? BackendConfiguration else { continue }

        let bookmarkDatas = Array(
            config.keys
                .filter { $0.contains(BackendConfigurationLocalURLBookmarkDataFieldKeySuffix) }
                .map { config[$0] }
        )
        let passwordFields = Array(
            config.keys
                .filter { $0.contains(BackendConfigurationPasswordFieldKeySuffix) }
        )

        for data in bookmarkDatas {
            guard let data = data as? Data else {
                Logger.config.error("Found bookmark data is not valid data.")
                continue
            }
            var isStale = false
            #if os(macOS)
            guard let accessibleUrl = try? URL(
                resolvingBookmarkData: data,
                options: NSURL.BookmarkResolutionOptions.withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ), !isStale else {
                Logger.config.error("Could not acquire accessible url. isStale: \(isStale)")
                continue
            }
            #else
            guard let accessibleUrl = try? URL(
                resolvingBookmarkData: data,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ), !isStale else {
                Logger.config.error("Could not acquire accessible url. isStale: \(isStale)")
                continue
            }
            #endif
        }

        for passwordField in passwordFields {
            guard let backendId = config[BackendConfigurationIdFieldKey] as? String else {
                Logger.config.error("Could not get backend id!")
                continue
            }
            guard let fieldId = config[passwordField] as? String else {
                Logger.config.error("Could not get password field id!")
                continue
            }
            let password = getPasswordInKeychain(forBackend: backendId, fieldId: fieldId)
            config[fieldId] = password
        }

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
