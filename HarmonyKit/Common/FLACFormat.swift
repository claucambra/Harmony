//
//  FLACFormat.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import Foundation

struct FLACFormat {
    static var streamMarker = "fLaC"

    struct Header {
        static let size = 4

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
    }
}
