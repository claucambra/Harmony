//
//  FilePlayability.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 20/1/24.
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
    // TODO: Check remote files
    // TODO: Check file validity (i.e. is corrupted?)
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
