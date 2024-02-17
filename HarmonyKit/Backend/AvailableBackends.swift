//
//  AvailableBackends.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 20/1/24.
//

import Foundation

public let availableBackends = [
    localBackendTypeDescription,
    ncBackendTypeDescription
]

public func backendFromDescriptionId(
    _ id: String, withConfig config: BackendConfiguration
) -> (any Backend)? {
    switch id {
    case localBackendTypeDescription.id:
        return LocalBackend(config: config)
    case ncBackendTypeDescription.id:
        return NextcloudBackend(config: config)
    default:
        return nil
    }
}
