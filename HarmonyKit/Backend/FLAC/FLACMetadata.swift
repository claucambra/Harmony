//
//  FLACMetadata.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import Foundation

struct FLACMetadata {
    struct Header {
        enum BlockType: UInt8 {
            case streamInfo
            case padding
            case application
            case seekTable
            case vorbisComment
            case cueSheet
            case picture
            case reserved
            case invalid
            case undefined

            init(byte: UInt8) {
                let type = byte & 0x7F  // Ignore largest bit of byte as that's last block flag
                if type == 127 {
                    self = .invalid
                } else if type <= 126, type >= 7 {
                    self = .reserved
                } else {
                    self = BlockType(rawValue: type) ?? .undefined
                }
            }
        }

        static let size = 4  // Bytes
        let isLastMetadataBlock: Bool
        let blockType: BlockType
        let metadataBlockDataSize: UInt32

        init(bytes: Data) {
            isLastMetadataBlock = (bytes[0] & 0x80) != 0  // Check largest bit of byte
            blockType = BlockType(byte: bytes[0])
            let metadataBlockDataSizeBytes = bytes[1..<4]
            metadataBlockDataSize = metadataBlockDataSizeBytes.withUnsafeBytes {
                $0.load(as: UInt32.self)
            } // All numbers are big endian
        }
    }

    static var streamMarker = "fLaC"
    var streamInfo: FLACStreamInfoBlock?
    var vorbisComments: FLACVorbisCommentsBlock?
    var picture: FLACPictureBlock?
    var application: FLACApplicationBlock?
    var seekTable: FLACSeekTableBlock?
    var cueSheet: FLACCueSheetBlock?
    var paddings: [FLACPaddingBlock]?
}
