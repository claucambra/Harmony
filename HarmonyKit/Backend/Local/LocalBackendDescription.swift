//
//  LocalBackendDescription.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 4/2/24.
//

import Foundation

enum LocalBackendFieldId: String {
    case pathConfig = "path-field"
}

let localBackendTypeDescription = BackendDescription(
    id: "local-backend",
    name: "Local Backend",
    description: "Provides music stored locally on your computer.",
    systemImageName: "internaldrive",
    configDescription: [
        BackendConfigurationField(
            id: LocalBackendFieldId.pathConfig.rawValue,
            title: "Path",
            description: "Location of files. Can be multiple locations.",
            valueType: .localUrl,
            isArray: true,
            optional: false,
            defaultValue: FileManager.default.urls(
                for: .musicDirectory, in: .userDomainMask
            ).first?.path ?? ""
        )
    ]
)
