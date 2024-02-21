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
            case undefined

            init(bytes: UInt8) {
                let type = bytes & 0x7F
                if type <= 126, type >= 7 {
                    self = .reserved
                } else if type >= 0 {
                    self = BlockType(rawValue: type) ?? .undefined
                } else {
                    self = .undefined
                }
            }
        }
    }
}
