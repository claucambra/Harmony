//
//  LocalBackend.swift
//  Harmony
//
//  Created by Claudio Cambra on 16/1/24.
//

import AVFoundation
import CryptoKit
import OSLog

extension Logger {
    static let localBackend = Logger(subsystem: subsystem, category: "localBackend")
}

let localBackendTypeDescription = BackendDescription(
    id: "local-backend",
    name: "Local Backend",
    description: "Provides music stored locally on your computer.",
    systemImageName: "internaldrive",
    configDescription: [
        BackendConfigurationField(
            id: LocalBackend.pathConfigId,
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

public class LocalBackend : NSObject, Backend {
    fileprivate static let pathConfigId = "path-field"

    public let typeDescription = localBackendTypeDescription
    public let id: String

    public var configValues: BackendConfiguration = [:]

    public private(set) var presentation: BackendPresentable
    public private(set) var path: URL {
        didSet { DispatchQueue.main.async { self.presentation.config = self.path.path } }
    }

    static func getPathFromConfig(_ config: BackendConfiguration) -> URL {
        #if os(macOS)
        let accessibleUrlPathFieldId =
            LocalBackend.pathConfigId + BackendConfigurationLocalURLAccessibleURLFieldKeySuffix
        if let accessibleUrl = config[accessibleUrlPathFieldId] as? URL {
            return accessibleUrl
        }
        #endif
        return URL(fileURLWithPath: config[LocalBackend.pathConfigId] as? String ?? "")
    }

    required public init(config: BackendConfiguration) {
        configValues = config
        let localPath = LocalBackend.getPathFromConfig(config)
        path = localPath
        id = config[BackendConfigurationIdFieldKey] as! String
        presentation = BackendPresentable(
            backendId: id,
            typeId: localBackendTypeDescription.id,
            systemImage: localBackendTypeDescription.systemImageName,
            primary: localBackendTypeDescription.name,
            secondary: localBackendTypeDescription.description,
            config: "Path: " + localPath.path
        )
        super.init()
    }

    public init(path: URL, id: String) {
        self.path = path
        self.id = id
        presentation = BackendPresentable(
            backendId: id,
            typeId: localBackendTypeDescription.id,
            systemImage: localBackendTypeDescription.systemImageName,
            primary: localBackendTypeDescription.name,
            secondary: localBackendTypeDescription.description,
            config: "Path: " + path.path
        )
        super.init()
    }

    func songsFromLocalUrls(_ urls:[URL]) async -> [Song] {
        var songs: [Song] = []
        for url in urls {
            let asset = AVAsset(url: url)
            guard let csum = calculateMD5Checksum(forFileAtLocalURL: url) else { continue }
            guard let song = await Song(
                url: url, asset: asset, identifier: csum, backendId: id
            ) else { continue }
            songs.append(song)
        }
        return songs
    }

    public func scan() async -> [Song] {
        Logger.localBackend.info("Starting full scan of \(self.path)")
        DispatchQueue.main.async {
            self.presentation.state = "Starting full scan..."
        }
        let urls = await recursiveScan(path: path)
        let songs = await songsFromLocalUrls(urls)
        DispatchQueue.main.async {
            self.presentation.state = "Finished full scan at " + Date().formatted()
        }
        return songs
    }

    func recursiveScan(path: URL) async -> [URL] {
        Logger.localBackend.info("Scanning \(path)")

        DispatchQueue.main.async {
            self.presentation.state = "Scanning " + path.path + "…"
        }

        let audioFiles = await withTaskGroup(of: [URL].self, returning: [URL].self) { group in
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: path,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )

                for item in contents {
                    group.addTask {
                        Logger.localBackend.debug("Found \(item) in \(contents)")
                        var isDirectory: ObjCBool = false
                        if FileManager.default.fileExists(
                            atPath: item.path, isDirectory: &isDirectory
                        ) {
                            if isDirectory.boolValue {
                                // If it's a directory, recursively scan it asynchronously
                                return await self.recursiveScan(path: item)
                            } else {
                                // If it's a file, check if it's playable
                                if filePlayability(fileURL: item) == .filePlayable {
                                    return [item]
                                }
                            }
                        }
                        return []
                    }
                }

                var scannedUrls: [URL] = []
                for await result in group {
                    scannedUrls.append(contentsOf: result)
                }
                return scannedUrls
            } catch {
                Logger.localBackend.error("Error scanning directory \(path): \(error).")
                return []
            }
        }

        return audioFiles
    }

    public func fetchSong(_ song: Song) async {
        return
    }
    
    public func evictSong(_ song: Song) async {
        return
    }

    public func assetForSong(atURL url: URL) -> AVAsset? {
        return AVAsset(url: url)
    }
}
