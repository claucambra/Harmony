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
    public static let backendDescription = BackendDescription(
        id: "local-backend",
        name: "Local Backend",
        description: "Provides music stored locally on your computer.",
        systemImageName: "internaldrive",
        configDescription: [
            BackendConfigurationField(
                id: "path-field",
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

        let fileManager = FileManager.default
        var audioFiles: [URL] = []

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: path,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            for item in contents {
                Logger.localBackend.debug("Found \(item) in \(contents)")
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        // If it's a directory, recursively scan it asynchronously
                        let subdirectoryAudioFiles = await recursiveScan(path: item)
                        audioFiles.append(contentsOf: subdirectoryAudioFiles)
                    } else {
                        // If it's a file, check if it's playable
                        if filePlayability(fileURL: item) == .filePlayable {
                            audioFiles.append(item)
                        }
                    }
                }
            }
        } catch {
            Logger.localBackend.error("Error scanning directory \(path): \(error).")
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
