//
//  LocalBackend.swift
//  Harmony
//
//  Created by Claudio Cambra on 16/1/24.
//

import AVFoundation
import CryptoKit

class LocalBackend : NSObject, Backend {
    let path: URL

    init(path: URL) {
        self.path = path
        super.init()
    }

    public static func calculateMD5Checksum(forFileAtURL url: URL) -> String? {
        do {
            let fileData = try Data(contentsOf: url)
            let checksum = Insecure.MD5.hash(data: fileData)
            let checksumString = checksum.map { String(format: "%02hhx", $0) }.joined()
            return checksumString
        } catch {
            print("Error reading file or calculating MD5 checksum: \(error)")
            return nil
        }
    }

    public static func songsFromLocalUrls(_ urls:[URL]) async -> [Song] {
        var songs: [Song] = []
        for url in urls {
            let asset = AVAsset(url: url)
            guard let csum = calculateMD5Checksum(forFileAtURL: url) else { continue }
            guard let song = await Song.init(fromAsset: asset, withIdentifier: csum) else { continue }
            songs.append(song)
        }
        return songs
    }

    func scan() async -> [Song] {
        let urls = await recursiveScan(path: path)
        return await LocalBackend.songsFromLocalUrls(urls)
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
