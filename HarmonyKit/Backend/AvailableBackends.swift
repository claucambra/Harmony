//
//  AvailableBackends.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 20/1/24.
//

import Foundation

public let availableBackends = [
    LocalBackend.description
]

public func backendFromId(_ id: String, withConfig config: BackendConfiguration) -> (any Backend)? {
    switch id {
    case LocalBackend.description.id:
        return LocalBackend(config: config)
    default:
        return nil
    }
}
