//
//  AvailableBackends.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 20/1/24.
//

import Foundation

public let availableBackends = [
    appleMusicBackendTypeDescription,
    filesBackendTypeDescription,
    ncBackendTypeDescription
]

public func backendFromDescriptionId(
    _ id: String, withConfig config: BackendConfiguration
) -> (any Backend)? {
    switch id {
    case appleMusicBackendTypeDescription.id:
        return AppleMusicBackend(config: config)
    case filesBackendTypeDescription.id:
        return FilesBackend(config: config)
    case ncBackendTypeDescription.id:
        return NextcloudBackend(config: config)
    default:
        return nil
    }
}
