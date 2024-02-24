//
//  FilesBackendDescription.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 4/2/24.
//

import Foundation

enum FilesBackendFieldId: String {
    case pathConfig = "path-field"
}

let filesBackendTypeDescription = BackendDescription(
    id: "files-backend",
    name: "Files",
    description: "Provides music stored as files.",
    systemImageName: "doc",
    configDescription: [
        BackendConfigurationField(
            id: FilesBackendFieldId.pathConfig.rawValue,
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
