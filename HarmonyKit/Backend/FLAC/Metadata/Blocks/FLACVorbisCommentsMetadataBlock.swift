//
//  FLACVorbisCommentsMetadataBlock.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import Foundation
import OSLog

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
    private let logger = Logger(subsystem: Logger.subsystem, category: "flacVorbisComments")

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

        var processedMetadata: [Field: String] = [:]
        for _ in 0..<commentCount {
            let commentLength = Int(advancedBytes[0..<4].withUnsafeBytes {
                $0.load(as: UInt32.self).littleEndian
            })
            advancedBytes = advancedBytes.advanced(by: 4)

            let valueBytes = advancedBytes[0..<commentLength]
            guard let value = String(bytes: valueBytes, encoding: .utf8) else {
                logger.error("Could not get string from \(valueBytes), skipping value")
                advancedBytes = advancedBytes.advanced(by: commentLength)
                continue
            }
            advancedBytes = advancedBytes.advanced(by: commentLength)

            let keyValue = value.split(separator: "=")
            if keyValue.count == 2, let key = Field(rawValue: String(keyValue[0])) {
                processedMetadata[key] = String(keyValue[1])
            } else {
                logger.error("Could not get key-value pair from \(keyValue), skipping")
            }
        }

        metadata = processedMetadata
    }
}
