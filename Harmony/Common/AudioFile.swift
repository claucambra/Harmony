//
//  AudioFile.swift
//  Harmony
//
//  Created by Claudio Cambra on 17/1/24.
//

import Foundation
import AVFoundation

enum FilePlayable {
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

func filePlayability(fileURL: URL) -> FilePlayable {
    guard fileHasPlayableExtension(fileURL: fileURL) else { return .fileNotPlayable }
    do {
        let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
        if fileAttributes.isRegularFile! {
            return .filePlayable
        }
    } catch {
        print("Error reading file attributes for \(fileURL): \(error).")
    }
    return .fileMaybePlayable
}
