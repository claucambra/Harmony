//
//  AudioFile.swift
//  Harmony
//
//  Created by Claudio Cambra on 17/1/24.
//

import AVFoundation
import CryptoKit

public enum FilePlayable {
    case fileNotPlayable, fileMaybePlayable, filePlayable
}

func playableFileExtensions() -> [String] {
    let avTypes = AVURLAsset.audiovisualTypes()
    let avExtensions = avTypes
        .compactMap({ UTType($0.rawValue)?.preferredFilenameExtension })
        .sorted()
    return avExtensions
}

func fileHasPlayableExtension(fileURL: URL) -> Bool {
    let fileExtension = fileURL.pathExtension.lowercased()
    return playableFileExtensions().contains(fileExtension)
}

public func filePlayability(fileURL: URL) -> FilePlayable {
    guard fileHasPlayableExtension(fileURL: fileURL) else { return .fileNotPlayable }
    do {
        let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
        if fileAttributes.isRegularFile ?? false {
            return .filePlayable
        }
    } catch {
        print("Error reading file attributes for \(fileURL): \(error).")
    }
    return .fileMaybePlayable
}

func calculateMD5Checksum(forFileAtURL url: URL) -> String? {
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

func songsFromLocalUrls(_ urls:[URL]) async -> [Song] {
    var songs: [Song] = []
    for url in urls {
        let asset = AVAsset(url: url)
        guard let csum = calculateMD5Checksum(forFileAtURL: url) else { continue }
        guard let song = await Song.init(fromAsset: asset, withIdentifier: csum) else { continue }
        songs.append(song)
    }
    return songs
}
