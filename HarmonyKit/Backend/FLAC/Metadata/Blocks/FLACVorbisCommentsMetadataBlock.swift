//
//  FLACVorbisCommentsMetadataBlock.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import Foundation

struct FLACVorbisCommentsMetadataBlock {
    enum Field: String {
        case title = "TITLE"
        case version = "VERSION"
        case album = "ALBUM"
        case trackNumber = "TRACKNUMBER"
        case artist = "ARTIST"
        case performer = "PERFORMER"
        case copyright = "COPYRIGHT"
        case license = "LICENSE"
        case organization = "ORGANIZATION"
        case description = "DESCRIPTION"
        case genre = "GENRE"
        case date = "DATE"
        case location = "LOCATION"
        case contact = "CONTACT"
        case isrc = "ISRC"
    }

    let header: FLACMetadataBlockHeader
    let vendor: String
    let metadata: [Field: String]

    init(bytes: Data, header: FLACMetadataBlockHeader) {
        var advancedBytes = bytes.advanced(by: 0)
        self.header = header

        let vendorLength = Int(advancedBytes[0..<4].withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        })
        advancedBytes = advancedBytes.advanced(by: 4)

        vendor = String(bytes: advancedBytes[0..<vendorLength], encoding: .utf8) ?? ""
        advancedBytes = advancedBytes.advanced(by: vendorLength)

        let commentCount = advancedBytes[0..<4].withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        advancedBytes = advancedBytes.advanced(by: 4)

        for i in 0..<commentCount {
        var processedMetadata: [Field: String] = [:]
            let commentLength = Int(advancedBytes[0..<4].withUnsafeBytes {
                $0.load(as: UInt32.self).littleEndian
            })
            advancedBytes = advancedBytes.advanced(by: 4)

            guard let value = String(
                bytes: advancedBytes[0..<commentLength], encoding: .utf8
            ) else {
                advancedBytes = advancedBytes.advanced(by: commentLength)
                continue
            }
            advancedBytes = advancedBytes.advanced(by: commentLength)

            let keyValue = value.split(separator: "=")
            if keyValue.count == 2, let key = Field(rawValue: String(keyValue[0])) {
                processedMetadata[key] = String(keyValue[1])
            }
        }

        metadata = processedMetadata
    }
}
