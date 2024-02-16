//
//  NextcloudBackend.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 4/2/24.
//

import AVFoundation
import NextcloudKit
import OSLog

extension Logger {
    static let ncBackend = Logger(subsystem: subsystem, category: "ncBackend")
}

public class NextcloudBackend: NSObject, Backend {
    public let typeDescription: BackendDescription = ncBackendTypeDescription
    public let id: String
    public var presentation: BackendPresentable
    public var configValues: BackendConfiguration
    private let ncKit: NextcloudKit

    public required init(config: BackendConfiguration) {
        configValues = config
        id = config[BackendConfigurationIdFieldKey] as! String
        presentation = BackendPresentable(
            backendId: id,
            typeId: typeDescription.id,
            systemImage: typeDescription.systemImageName,
            primary: typeDescription.name,
            secondary: typeDescription.description,
            config: "" // TODO
        )

        let user = config[NextcloudBackendFieldId.username.rawValue] as! String
        let password = config[NextcloudBackendFieldId.password.rawValue] as! String
        let serverUrl = config[NextcloudBackendFieldId.serverUrl.rawValue] as! String
        ncKit = NextcloudKit()
        ncKit.setup(user: user, userId: user, password: password, urlBase: serverUrl)
    }

    public func scan() async -> [Song] {
        return []  // TODO
    }
    
    public func assetForSong(atURL url: URL) -> AVAsset? {
        return nil  // TODO
    }
    
    public func fetchSong(_ song: Song) async {
        // TODO
    }
    
    public func evictSong(_ song: Song) async {
        // TODO
    }
}
