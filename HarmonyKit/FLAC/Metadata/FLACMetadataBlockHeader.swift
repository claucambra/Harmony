//
//  FLACBlockHeader.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import Foundation

struct FLACMetadataBlockHeader {
    enum MetadataBlockType: UInt8 {
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
                self = MetadataBlockType(rawValue: type) ?? .undefined
            }
        }
    }

    static let size = 4  // Bytes
    let isLastMetadataBlock: Bool
    let metadataBlockType: MetadataBlockType
    let metadataBlockDataSize: UInt32

    init(bytes: Data) {
        isLastMetadataBlock = (bytes[0] & 0x80) != 0  // Check largest bit of byte
        metadataBlockType = MetadataBlockType(byte: bytes[0])
        var usableMetadataBlockDataSize: UInt32 = 0
        for i in 1..<4 {
            usableMetadataBlockDataSize = (usableMetadataBlockDataSize << 8) | UInt32(bytes[i])
        } // big endian numbers
        metadataBlockDataSize = usableMetadataBlockDataSize
    }
}
