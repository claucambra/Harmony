//
//  FLACPictureMetadataBlock.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import Foundation

struct FLACPictureMetadataBlock {
    enum PictureType: UInt32 {
        case other
        case fileIcon  // 32x32 pixels 'file icon' (PNG only)
        case otherFileIcon
        case frontCover
        case backCover
        case leafletPage
        case media  // Media (e.g. label side of CD)
        case leadArtist // Lead artist/lead performer/soloist
        case artist
        case conductor
        case band
        case composer
        case lyricist
        case recordingLocation
        case duringRecording
        case duringPerformance
        case videoScreenCapture
        case fish  // A bright coloured fish (??)
        case illustration
        case bandLogotype  // Band/artist logotype
        case publisherLogotype
        case undefined
    }

    let header: FLACMetadataBlockHeader
    let type: PictureType
    let mimeType: String
    let description: String?
    let size: CGSize
    let colorDepth: UInt32
    // For indexed-color pictures (e.g. GIF), number of colors used, or 0 for non-indexed pictures.
    let colorUsed: UInt32
    let length: UInt32
    let data: Data

    init(bytes: Data, header: FLACMetadataBlockHeader) {
        self.header = header

        var advancedBytes = bytes.advanced(by: 0)
        let typeValue = advancedBytes[0..<4].withUnsafeBytes {
            $0.load(as: UInt32.self).bigEndian
        }
        type = PictureType(rawValue: typeValue) ?? .undefined
        advancedBytes = advancedBytes.advanced(by: 4)

        let mimeTypeLength = Int(advancedBytes[0..<4].withUnsafeBytes {
            $0.load(as: UInt32.self).bigEndian
        })
        advancedBytes = advancedBytes.advanced(by: 4)

        mimeType = String(bytes: advancedBytes[0..<mimeTypeLength], encoding: .ascii) ?? ""
        advancedBytes = advancedBytes.advanced(by: mimeTypeLength)

        let descriptionLength = advancedBytes[0..<4].withUnsafeBytes {
            $0.load(as: UInt32.self).bigEndian
        }
        advancedBytes = advancedBytes.advanced(by: 4)

        if descriptionLength > 0 {
            description = String(bytes: advancedBytes[0..<descriptionLength], encoding: .utf8)
            advancedBytes = advancedBytes.advanced(by: Int(descriptionLength))
        } else {
            description = nil
        }

        let width = Int(advancedBytes[0..<4].withUnsafeBytes {
            $0.load(as: UInt32.self).bigEndian
        })
        advancedBytes = advancedBytes.advanced(by: 4)

        let height = Int(advancedBytes[0..<4].withUnsafeBytes {
            $0.load(as: UInt32.self).bigEndian
        })
        advancedBytes = advancedBytes.advanced(by: 4)

        size = CGSize(width: width, height: height)

        colorDepth = advancedBytes[0..<4].withUnsafeBytes {
            $0.load(as: UInt32.self).bigEndian
        }
        advancedBytes = advancedBytes.advanced(by: 4)

        colorUsed = advancedBytes[0..<4].withUnsafeBytes {
            $0.load(as: UInt32.self).bigEndian
        }
        advancedBytes = advancedBytes.advanced(by: 4)

        length = advancedBytes[0..<4].withUnsafeBytes {
            $0.load(as: UInt32.self).bigEndian
        }
        advancedBytes = advancedBytes.advanced(by: 4)

        data = advancedBytes[0..<length]
    }
}
