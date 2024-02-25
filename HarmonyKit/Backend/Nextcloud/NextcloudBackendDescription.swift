//
//  NextcloudBackendDescription.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 4/2/24.
//

import Foundation

enum NextcloudBackendFieldId: String {
    case serverUrl = "serverurl-field"
    case username = "username-field"
    case password = "password-field"
    case musicPath = "musicpath-field"
}

let ncBackendTypeDescription = BackendDescription(
    id: "nc-backend",
    name: "Nextcloud",
    description: "Provides music stored on your Nextcloud server.",
    systemImageName: "cloud",
    configDescription: [
        BackendConfigurationField(
            id: NextcloudBackendFieldId.serverUrl.rawValue,
            title: "Server URL",
            description: "Location of server.",
            valueType: .string,
            isArray: false,
            optional: false,
            defaultValue: ""
        ),
        BackendConfigurationField(
            id: NextcloudBackendFieldId.username.rawValue,
            title: "Username",
            description: "Nextcloud user username",
            valueType: .string,
            isArray: false,
            optional: false,
            defaultValue: ""
        ),
        BackendConfigurationField(
            id: NextcloudBackendFieldId.password.rawValue,
            title: "Password",
            description: "Nextcloud user password",
            valueType: .password,
            isArray: false,
            optional: false,
            defaultValue: ""
        ),
        BackendConfigurationField(
            id: NextcloudBackendFieldId.musicPath.rawValue,
            title: "Music path",
            description: "Path to music folder (relative to user root)",
            valueType: .string,
            isArray: false,
            optional: false,
            defaultValue: ""
        )
    ]
)
