//
//  NextcloudBackendDescription.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 4/2/24.
//

import Foundation

internal let ncBackendServerUrlConfigFieldId = "serverurl-field"
internal let ncBackendUsernameConfigFieldId = "username-field"
internal let ncBackendPasswordConfigFieldId = "password-field"
internal let ncBackendMusicPathConfigFieldId = "musicpath-field"

let ncBackendTypeDescription = BackendDescription(
    id: "nc-backend",
    name: "Nextcloud Backend",
    description: "Provides music stored on your Nextcloud server.",
    systemImageName: "cloud",
    configDescription: [
        BackendConfigurationField(
            id: ncBackendServerUrlConfigFieldId,
            title: "Server URL",
            description: "Location of server.",
            valueType: .string,
            isArray: false,
            optional: false,
            defaultValue: ""
        ),
        BackendConfigurationField(
            id: ncBackendUsernameConfigFieldId,
            title: "Username",
            description: "Nextcloud user username",
            valueType: .string,
            isArray: false,
            optional: false,
            defaultValue: ""
        ),
        BackendConfigurationField(
            id: ncBackendPasswordConfigFieldId,
            title: "Password",
            description: "Nextcloud user password",
            valueType: .string,
            isArray: false,
            optional: false,
            defaultValue: ""
        ),
        BackendConfigurationField(
            id: ncBackendMusicPathConfigFieldId,
            title: "Music path",
            description: "Path to music folder (relative to user root)",
            valueType: .string,
            isArray: false,
            optional: false,
            defaultValue: ""
        )
    ]
)
