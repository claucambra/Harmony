//
//  AudioFile.swift
//  Harmony
//
//  Created by Claudio Cambra on 17/1/24.
//

import Foundation
import AVFoundation

func playableFileExtensions() -> [String] {
    let avTypes = AVURLAsset.audiovisualTypes()
    let avExtensions = avTypes
        .compactMap({ UTType($0.rawValue)?.preferredFilenameExtension })
        .sorted()
    return avExtensions
}
