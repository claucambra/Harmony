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

fileprivate let NextcloudWebDavFilesUrlSuffix: String = "/remote.php/dav/files/"

public class NextcloudBackend: NSObject, Backend {
    public let typeDescription: BackendDescription = ncBackendTypeDescription
    public let id: String
    public var presentation: BackendPresentable
    public var configValues: BackendConfiguration
    private let ncKit: NextcloudKit
    private let ncKitBackground: NKBackground
    private let filesPath: String
    private let headers: Dictionary<String, String>
    private let assetResourceLoader: NextcloudAVAssetResourceLoaderDelegate

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
        ncKitBackground = NKBackground(nkCommonInstance: ncKit.nkCommonInstance)

        let davRelativePath = config[NextcloudBackendFieldId.musicPath.rawValue] as! String
        filesPath = serverUrl + NextcloudWebDavFilesUrlSuffix + user + davRelativePath

        let loginString = "\(user):\(password)"
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()

        headers = [
            "Authorization": "Basic \(base64LoginString)",
            "User-Agent": ncKit.nkCommonInstance.userAgent ?? ""
        ]

        assetResourceLoader = NextcloudAVAssetResourceLoaderDelegate(user: user, password: password)
    }

    public func scan() async -> [Song] {
        return await recursiveScanRemotePath(filesPath)
    }

    private func recursiveScanRemotePath(_ path: String) async -> [Song] {
        Logger.ncBackend.debug("Starting read of: \(path)")

        let readResult = await withCheckedContinuation { continuation in
            ncKit.readFileOrFolder(
                serverUrlFileName: path, depth: "1"
            ) { _, files, _, error in
                continuation.resume(returning: (files, error))
            }
        }

        let files = readResult.0
        let error = readResult.1

        guard error == .success else {
            Logger.ncBackend.error("Could not scan \(path): \(error.errorDescription)")
            return []
        }

        guard !files.isEmpty else {
            Logger.ncBackend.warning("Received no items from readFileOrFolder of \(path)")
            return []
        }

        var songs: [Song] = []

        for file in files {
            let receivedFileUrl = file.serverUrl + "/" + file.fileName
            Logger.ncBackend.debug("Received file \(receivedFileUrl)")

            guard file.directory else {
                // Process received file
                guard let songUrl = URL(string: receivedFileUrl) else {
                    Logger.ncBackend.error("Received serverUrl for \(receivedFileUrl) is invalid")
                    continue
                }

                guard fileHasPlayableExtension(fileURL: songUrl) else {
                    Logger.ncBackend.info("File at \(songUrl) is not a playable song file, skip")
                    continue
                }

                let asset = AVURLAsset(url: songUrl)
                asset.resourceLoader.setDelegate(assetResourceLoader, queue: DispatchQueue.global())

                guard let song = await Song(
                    url: songUrl,
                    asset: asset,
                    identifier: file.ocId,
                    backendId: self.id
                ) else {
                    Logger.ncBackend.error("Could not create song from \(file)")
                    continue
                }

                Logger.ncBackend.debug("Acquired valid song: \(songUrl)")
                songs.append(song)
                continue
            }

            // Handle directories here.
            // We don't care about the metadata for the directory itself so skip it.
            guard receivedFileUrl != path else { continue } // First item is always the requested.
            let childRecursiveScanSongs = await recursiveScanRemotePath(receivedFileUrl)
            songs.append(contentsOf: childRecursiveScanSongs)
        }

        return songs
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
