//
//  LocalBackend.swift
//  Harmony
//
//  Created by Claudio Cambra on 16/1/24.
//

import Foundation

class LocalBackend : NSObject, Backend {
    let path: URL

    init(path: URL) {
        self.path = path
        super.init()
    }

    func scan() async -> [URL] {
        return await recursiveScan(path: path)
    }

    private func recursiveScan(path: URL) async -> [URL] {
        let fileManager = FileManager.default
        var audioFiles: [URL] = []

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: path,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            for item in contents {
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
            print("Error scanning directory \(path): \(error).")
        }

        return audioFiles
    }

    func fetchSong(_ song: Song) async {
        return
    }
    
    func evictSong(_ song: Song) async {
        return
    }
}
