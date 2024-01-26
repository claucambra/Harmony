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

public class LocalBackend : NSObject, Backend {
    private static let pathConfigId = "path-field"
    public static let description = BackendDescription(
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
    public let path: URL
    public let id: String = UUID().uuidString
    public let primaryDisplayString = LocalBackend.description.name
    public let secondaryDisplayString = LocalBackend.description.description

    required public init(config: BackendConfiguration) {
        let accessibleUrlPathFieldId =
            LocalBackend.pathConfigId + BackendConfigurationLocalURLAccessibleURLFieldKeySuffix
        if let accessibleUrl = config[accessibleUrlPathFieldId] as? URL {
            path = accessibleUrl
        } else {
            path = URL(fileURLWithPath: config[LocalBackend.pathConfigId] as? String ?? "")
        }
    }

    public init(path: URL) {
        self.path = path
        super.init()
    }

    public func scan() async -> [Song] {
        Logger.localBackend.info("Starting full scan of \(self.path)")
        let urls = await recursiveScan(path: path)
        return await songsFromLocalUrls(urls)
    }

    func recursiveScan(path: URL) async -> [URL] {
        Logger.localBackend.info("Scanning \(path)")

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
}
